//
//  MapViewRepresentable.swift
//  EarthLord
//
//  MKMapView 的 SwiftUI 包装器 - 显示末世风格地图和路径轨迹
//

import SwiftUI
import MapKit

/// 地图视图的 SwiftUI 包装器
/// 将 UIKit 的 MKMapView 封装为 SwiftUI 可用的视图
struct MapViewRepresentable: UIViewRepresentable {

    // MARK: - Bindings

    /// 用户当前位置坐标（双向绑定）
    @Binding var userLocation: CLLocationCoordinate2D?

    /// 是否已完成首次定位（防止重复居中）
    @Binding var hasLocatedUser: Bool

    // MARK: - 路径追踪属性

    /// 路径坐标数组（WGS-84 坐标）
    @Binding var trackingPath: [CLLocationCoordinate2D]

    /// 路径更新版本号（触发地图更新）
    var pathUpdateVersion: Int

    /// 是否正在追踪
    var isTracking: Bool

    // MARK: - UIViewRepresentable

    /// 创建 MKMapView 实例
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        // 配置地图类型：卫星图+道路标签（末世废土风格）
        mapView.mapType = .hybrid

        // 隐藏所有 POI 标签（商店、餐厅等）
        mapView.pointOfInterestFilter = .excludingAll

        // 隐藏 3D 建筑
        mapView.showsBuildings = false

        // 显示用户位置蓝点（关键！触发定位）
        mapView.showsUserLocation = true

        // 允许缩放和拖动
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true

        // 显示指南针
        mapView.showsCompass = true

        // 设置代理（关键！否则 didUpdate userLocation 不会被调用）
        mapView.delegate = context.coordinator

        // 应用末世滤镜效果
        applyApocalypseFilter(to: mapView)

        return mapView
    }

    /// 更新 MKMapView（当 SwiftUI 状态变化时调用）
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 更新路径轨迹
        context.coordinator.updateTrackingPath(on: mapView, with: trackingPath)
    }

    /// 创建 Coordinator 处理地图代理回调
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Private Methods

    /// 应用末世滤镜效果
    /// 降低饱和度、添加棕褐色调，营造废土氛围
    private func applyApocalypseFilter(to mapView: MKMapView) {
        // 色调控制：降低饱和度和亮度
        guard let colorControls = CIFilter(name: "CIColorControls") else { return }
        colorControls.setValue(-0.15, forKey: kCIInputBrightnessKey)  // 稍微变暗
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)    // 降低饱和度

        // 棕褐色调：废土的泛黄效果
        guard let sepiaFilter = CIFilter(name: "CISepiaTone") else { return }
        sepiaFilter.setValue(0.65, forKey: kCIInputIntensityKey)

        // 应用滤镜到地图图层
        mapView.layer.filters = [colorControls, sepiaFilter]
    }

    // MARK: - Coordinator

    /// Coordinator 类：处理 MKMapView 的代理回调
    class Coordinator: NSObject, MKMapViewDelegate {

        /// 父视图引用
        var parent: MapViewRepresentable

        /// 首次居中标志（防止重复居中，不影响用户手动拖动）
        private var hasInitialCentered = false

        /// 当前轨迹线（用于更新时移除旧的）
        private var currentPolyline: MKPolyline?

        /// 上次绘制的路径点数（避免重复绘制）
        private var lastPathCount: Int = 0

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // MARK: - 路径更新方法

        /// 更新追踪路径显示
        /// - Parameters:
        ///   - mapView: 地图视图
        ///   - path: WGS-84 坐标数组
        func updateTrackingPath(on mapView: MKMapView, with path: [CLLocationCoordinate2D]) {
            // 如果路径为空，移除现有轨迹
            if path.isEmpty {
                if let polyline = currentPolyline {
                    mapView.removeOverlay(polyline)
                    currentPolyline = nil
                }
                lastPathCount = 0
                return
            }

            // 如果路径点数没有变化，不重新绘制
            if path.count == lastPathCount {
                return
            }

            // 移除旧的轨迹线
            if let polyline = currentPolyline {
                mapView.removeOverlay(polyline)
            }

            // ⭐ 关键：将 WGS-84 坐标转换为 GCJ-02 坐标
            let convertedCoordinates = CoordinateConverter.wgs84ToGcj02(path)

            // 创建新的轨迹线
            let polyline = MKPolyline(coordinates: convertedCoordinates, count: convertedCoordinates.count)

            // 添加到地图
            mapView.addOverlay(polyline)

            // 保存当前轨迹线引用
            currentPolyline = polyline
            lastPathCount = path.count
        }

        // MARK: - MKMapViewDelegate

        /// ⭐ 关键方法：用户位置更新时调用
        /// 首次获得位置时自动居中地图
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            // 获取有效位置
            guard let location = userLocation.location else { return }

            // 更新绑定的位置坐标
            DispatchQueue.main.async {
                self.parent.userLocation = location.coordinate
            }

            // 检查是否已完成首次居中
            guard !hasInitialCentered else { return }

            // 创建居中区域（约1公里范围）
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )

            // 平滑居中地图
            mapView.setRegion(region, animated: true)

            // 标记已完成首次居中
            hasInitialCentered = true

            // 更新外部状态
            DispatchQueue.main.async {
                self.parent.hasLocatedUser = true
            }
        }

        /// ⭐ 关键方法：渲染覆盖物（必须实现，否则轨迹不显示！）
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // 处理轨迹线
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)

                // 青色轨迹线（末世科技感）
                renderer.strokeColor = UIColor.cyan
                renderer.lineWidth = 5
                renderer.lineCap = .round  // 圆头
                renderer.lineJoin = .round // 圆角连接

                return renderer
            }

            // 默认渲染器
            return MKOverlayRenderer(overlay: overlay)
        }

        /// 地图区域变化回调
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // 可用于后续扩展（如显示当前缩放级别）
        }

        /// 地图加载完成回调
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            // 可用于后续扩展（如显示加载完成提示）
        }
    }
}

// MARK: - Preview

#Preview {
    MapViewRepresentable(
        userLocation: .constant(nil),
        hasLocatedUser: .constant(false),
        trackingPath: .constant([]),
        pathUpdateVersion: 0,
        isTracking: false
    )
}
