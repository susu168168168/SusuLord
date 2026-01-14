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

    // MARK: - 速度检测相关属性

    /// 速度警告信息
    @Published var speedWarning: String?

    /// 是否超速
    @Published var isOverSpeed: Bool = false

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

    /// 上次记录路径点的位置（用于速度计算）
    private var lastRecordedLocation: CLLocation?

    /// 上次记录路径点的时间戳（用于速度计算）
    private var lastLocationTimestamp: Date?

    // MARK: - 闭环检测常量

    /// 闭环距离阈值（米）- 当前位置距起点小于此值视为闭环
    private let closureDistanceThreshold: Double = 30.0

    /// 最少路径点数 - 至少需要这么多点才能判断闭环
    private let minimumPathPoints: Int = 10

    // MARK: - 速度检测常量

    /// 警告速度阈值（km/h）- 超过此速度显示警告
    private let warningSpeedThreshold: Double = 15.0

    /// 停止速度阈值（km/h）- 超过此速度停止追踪
    private let stopSpeedThreshold: Double = 30.0

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

        // 记录日志
        TerritoryLogger.shared.log("开始圈地追踪", type: .info)

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

        // 记录日志
        TerritoryLogger.shared.log("停止追踪，共 \(pathCoordinates.count) 个点", type: .info)
    }

    /// 清除路径
    /// 重置所有路径相关状态
    func clearPath() {
        pathCoordinates.removeAll()
        pathUpdateVersion = 0
        isPathClosed = false

        // 重置速度检测相关状态
        speedWarning = nil
        isOverSpeed = false
        lastRecordedLocation = nil
        lastLocationTimestamp = nil
    }

    /// 记录路径点（定时器回调）
    /// ⚠️ 关键：先检查距离，再检查速度！顺序不能反！
    /// 正确顺序：距离检查 → 速度检测 → 记录新点 → 闭环检测
    private func recordPathPoint() {
        guard isTracking else { return }
        guard let location = currentLocation else { return }

        // 如果是第一个点，直接记录并初始化速度检测状态
        if pathCoordinates.isEmpty {
            pathCoordinates.append(location.coordinate)
            pathUpdateVersion += 1

            // 初始化速度检测基准
            lastRecordedLocation = location
            lastLocationTimestamp = Date()

            print("📍 记录起点 #1")
            return
        }

        // 步骤1：先检查距离（过滤 GPS 漂移，距离不够就直接返回）
        guard let lastCoordinate = pathCoordinates.last else { return }
        let lastPathLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distance = location.distance(from: lastPathLocation)

        // 距离不够，不进行速度检测，直接返回
        guard distance >= minimumDistance else {
            return
        }

        // 步骤2：再检查速度（只对真实移动进行检测）
        guard validateMovementSpeed(newLocation: location) else {
            return  // 严重超速，不记录
        }

        // 步骤3：记录新点
        pathCoordinates.append(location.coordinate)
        pathUpdateVersion += 1

        // 更新速度检测基准
        lastRecordedLocation = location
        lastLocationTimestamp = Date()

        print("📍 记录路径点 #\(pathCoordinates.count)：距上点 \(String(format: "%.1f", distance))m")

        // 记录日志
        TerritoryLogger.shared.log("记录第 \(pathCoordinates.count) 个点，距上点 \(String(format: "%.1f", distance))m", type: .info)

        // 步骤4：检测闭环
        checkPathClosure()
    }

    // MARK: - 闭环检测

    /// 检查路径是否闭合
    /// 条件：路径点数 ≥ 10 且 当前位置距起点 ≤ 30 米
    private func checkPathClosure() {
        // 已经闭合就不再检测
        guard !isPathClosed else { return }

        // 检查点数是否足够
        guard pathCoordinates.count >= minimumPathPoints else {
            print("🔄 闭环检测：点数不足（\(pathCoordinates.count)/\(minimumPathPoints)）")
            return
        }

        // 获取起点和当前位置
        guard let startCoordinate = pathCoordinates.first,
              let currentCoordinate = pathCoordinates.last else {
            return
        }

        // 计算当前位置到起点的距离
        let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
        let currentLocation = CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
        let distanceToStart = currentLocation.distance(from: startLocation)

        // 判断是否达到闭环条件
        if distanceToStart <= closureDistanceThreshold {
            isPathClosed = true
            pathUpdateVersion += 1  // 触发 UI 更新
            print("✅ 闭环检测成功！距起点 \(String(format: "%.1f", distanceToStart))m，路径点数：\(pathCoordinates.count)")

            // 记录日志 - 闭环成功
            TerritoryLogger.shared.log("闭环成功！距起点 \(String(format: "%.1f", distanceToStart))m", type: .success)
        } else {
            print("🔄 闭环检测：距起点 \(String(format: "%.1f", distanceToStart))m（需要 ≤ \(closureDistanceThreshold)m）")

            // 记录日志 - 闭环检测进度
            TerritoryLogger.shared.log("距起点 \(String(format: "%.1f", distanceToStart))m (需≤30m)", type: .info)
        }
    }

    // MARK: - 速度检测

    /// 验证移动速度
    /// - Parameter newLocation: 新位置
    /// - Returns: true 表示可以记录该点，false 表示严重超速不记录
    private func validateMovementSpeed(newLocation: CLLocation) -> Bool {
        // 如果没有上次记录的位置或时间戳，跳过速度检测
        guard let lastLocation = lastRecordedLocation,
              let lastTimestamp = lastLocationTimestamp else {
            return true
        }

        // 计算距离（米）
        let distance = newLocation.distance(from: lastLocation)

        // 计算时间差（秒）
        let timeInterval = Date().timeIntervalSince(lastTimestamp)

        // 防止除以零
        guard timeInterval > 0 else {
            return true
        }

        // 计算速度（km/h）：速度 = 距离 ÷ 时间差 × 3.6
        let speedKmh = (distance / timeInterval) * 3.6

        print("🚗 速度检测：\(String(format: "%.1f", speedKmh)) km/h（距离 \(String(format: "%.1f", distance))m，时间 \(String(format: "%.1f", timeInterval))s）")

        // 严重超速（> 30 km/h）：停止追踪
        if speedKmh > stopSpeedThreshold {
            isOverSpeed = true
            speedWarning = "速度过快（\(String(format: "%.0f", speedKmh)) km/h），追踪已暂停！请步行圈地"
            print("🛑 严重超速！速度 \(String(format: "%.1f", speedKmh)) km/h > \(stopSpeedThreshold) km/h，追踪已停止")

            // 记录日志 - 严重超速
            TerritoryLogger.shared.log("超速 \(String(format: "%.0f", speedKmh)) km/h，已停止追踪", type: .error)

            stopPathTracking()

            // 3 秒后自动清除警告
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.speedWarning = nil
            }

            return false  // 不记录该点
        }

        // 警告超速（> 15 km/h）：警告但继续记录
        if speedKmh > warningSpeedThreshold {
            isOverSpeed = true
            speedWarning = "移动较快（\(String(format: "%.0f", speedKmh)) km/h），请放慢速度"
            print("⚠️ 警告超速：\(String(format: "%.1f", speedKmh)) km/h > \(warningSpeedThreshold) km/h")

            // 记录日志 - 速度较快
            TerritoryLogger.shared.log("速度较快 \(String(format: "%.0f", speedKmh)) km/h", type: .warning)

            // 3 秒后自动清除警告
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.speedWarning = nil
                self?.isOverSpeed = false
            }

            return true  // 警告但继续记录
        }

        // 速度正常
        isOverSpeed = false
        return true
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
