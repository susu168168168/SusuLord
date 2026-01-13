//
//  LocationManager.swift
//  EarthLord
//
//  GPS 定位管理器 - 处理用户位置获取、权限管理和路径追踪
//

import Foundation
import CoreLocation
import Combine  // @Published 需要此框架
import UIKit    // UIApplication 需要此框架

/// GPS 定位管理器
/// 负责请求定位权限、获取用户位置、处理授权状态变化、路径追踪
final class LocationManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// 用户当前位置坐标
    @Published var userLocation: CLLocationCoordinate2D?

    /// 定位授权状态
    @Published var authorizationStatus: CLAuthorizationStatus

    /// 定位错误信息
    @Published var locationError: String?

    // MARK: - 路径追踪相关属性

    /// 是否正在追踪路径
    @Published var isTracking: Bool = false

    /// 路径坐标数组（存储原始 WGS-84 坐标）
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []

    /// 路径更新版本号（每次更新 +1，触发 SwiftUI 刷新）
    @Published var pathUpdateVersion: Int = 0

    /// 路径是否已闭合（Day16 圈地完成判断用）
    @Published var isPathClosed: Bool = false

    // MARK: - Private Properties

    /// CoreLocation 定位管理器
    private let locationManager = CLLocationManager()

    /// 当前位置（供 Timer 使用）
    private var currentLocation: CLLocation?

    /// 采点定时器
    private var pathUpdateTimer: Timer?

    /// 最小采点距离（米）
    private let minimumDistance: Double = 10.0

    /// 采点间隔（秒）
    private let trackingInterval: TimeInterval = 2.0

    // MARK: - Computed Properties

    /// 是否已获得定位授权
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// 是否被用户拒绝授权
    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // MARK: - Initialization

    override init() {
        // 获取当前授权状态
        self.authorizationStatus = locationManager.authorizationStatus

        super.init()

        // 配置定位管理器
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 最高精度
        locationManager.distanceFilter = 10  // 移动10米才更新位置
    }

    // MARK: - Public Methods

    /// 请求定位权限
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 开始更新位置
    func startUpdatingLocation() {
        locationError = nil
        locationManager.startUpdatingLocation()
    }

    /// 停止更新位置
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    /// 打开系统设置页面（用于用户拒绝授权后引导开启）
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    // MARK: - 路径追踪方法

    /// 开始路径追踪
    /// 启动 2 秒定时器，定期检查位置并记录路径点
    func startPathTracking() {
        guard isAuthorized else {
            locationError = "需要定位权限才能追踪路径"
            return
        }

        // 清空之前的路径
        clearPath()

        // 标记开始追踪
        isTracking = true

        // 确保定位服务已开启
        startUpdatingLocation()

        // 如果有当前位置，立即记录第一个点
        if let location = currentLocation {
            pathCoordinates.append(location.coordinate)
            pathUpdateVersion += 1
        }

        // 启动定时器，每 2 秒检查一次
        pathUpdateTimer = Timer.scheduledTimer(withTimeInterval: trackingInterval, repeats: true) { [weak self] _ in
            self?.recordPathPoint()
        }
    }

    /// 停止路径追踪
    /// 停止定时器，保留已记录的路径
    func stopPathTracking() {
        // 停止定时器
        pathUpdateTimer?.invalidate()
        pathUpdateTimer = nil

        // 标记停止追踪
        isTracking = false
    }

    /// 清除路径
    /// 重置所有路径相关状态
    func clearPath() {
        pathCoordinates.removeAll()
        pathUpdateVersion = 0
        isPathClosed = false
    }

    /// 记录路径点（定时器回调）
    /// 判断是否需要记录新点：距离上个点 > 10 米
    private func recordPathPoint() {
        guard isTracking else { return }
        guard let location = currentLocation else { return }

        // 如果是第一个点，直接记录
        if pathCoordinates.isEmpty {
            pathCoordinates.append(location.coordinate)
            pathUpdateVersion += 1
            return
        }

        // 计算与上一个点的距离
        guard let lastCoordinate = pathCoordinates.last else { return }
        let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distance = location.distance(from: lastLocation)

        // 距离超过最小阈值才记录
        if distance >= minimumDistance {
            pathCoordinates.append(location.coordinate)
            pathUpdateVersion += 1

            // 可以在这里添加日志
            print("📍 记录路径点 #\(pathCoordinates.count)：距上点 \(String(format: "%.1f", distance))m")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    /// 授权状态变化回调
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            // 授权后自动开始定位
            if self.isAuthorized {
                self.startUpdatingLocation()
            }
        }
    }

    /// 位置更新回调
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.locationError = nil

            // ⭐ 关键：更新 currentLocation，供 Timer 采点使用
            self.currentLocation = location
        }
    }

    /// 定位失败回调
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            // 根据错误类型设置友好提示
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "定位权限被拒绝，请在设置中开启"
                case .locationUnknown:
                    self.locationError = "无法获取位置，请稍后重试"
                case .network:
                    self.locationError = "网络错误，请检查网络连接"
                default:
                    self.locationError = "定位失败：\(error.localizedDescription)"
                }
            } else {
                self.locationError = "定位失败：\(error.localizedDescription)"
            }
        }
    }
}
