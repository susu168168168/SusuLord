//
//  MapTabView.swift
//  EarthLord
//
//  地图页面 - 显示末世风格地图、用户位置和路径追踪
//

import SwiftUI
import MapKit

struct MapTabView: View {

    // MARK: - Environment

    /// 定位管理器（通过环境对象获取）
    @EnvironmentObject var locationManager: LocationManager

    /// 用户位置坐标
    @State private var userLocation: CLLocationCoordinate2D?

    /// 是否已完成首次定位
    @State private var hasLocatedUser = false

    /// 是否显示验证结果横幅
    @State private var showValidationBanner = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景色
            ApocalypseTheme.background
                .ignoresSafeArea()

            // 根据授权状态显示不同内容
            if locationManager.isDenied {
                // 权限被拒绝：显示提示卡片
                deniedPermissionView
            } else {
                // 地图视图
                mapContentView
            }
        }
        .onAppear {
            // 首次打开时请求定位权限
            locationManager.requestPermission()
        }
    }

    // MARK: - Subviews

    /// 地图内容视图
    private var mapContentView: some View {
        ZStack {
            // 地图（传入路径追踪参数）
            MapViewRepresentable(
                userLocation: $userLocation,
                hasLocatedUser: $hasLocatedUser,
                trackingPath: $locationManager.pathCoordinates,
                pathUpdateVersion: locationManager.pathUpdateVersion,
                isTracking: locationManager.isTracking,
                isPathClosed: locationManager.isPathClosed
            )
            .ignoresSafeArea()

            // 顶部视图（验证结果横幅 + 速度警告 + 坐标栏）
            VStack(spacing: 8) {
                // 验证结果横幅（闭环后显示成功或失败）
                if showValidationBanner {
                    validationResultBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 速度警告横幅
                if let warning = locationManager.speedWarning {
                    speedWarningBanner(warning: warning)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 坐标显示栏
                coordinateBar
                Spacer()
            }
            .animation(.easeInOut(duration: 0.3), value: locationManager.speedWarning != nil)
            .animation(.easeInOut(duration: 0.3), value: showValidationBanner)

            // 右下角按钮组
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // 圈地按钮
                        trackingButton

                        // 定位按钮
                        locateButton
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 100)
                }
            }

            // 加载指示器（定位中）
            if !hasLocatedUser && locationManager.isAuthorized {
                loadingOverlay
            }
        }
        // 监听闭环状态，闭环后根据验证结果显示横幅
        .onReceive(locationManager.$isPathClosed) { isClosed in
            if isClosed {
                // 闭环后延迟一点点，等待验证结果
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        showValidationBanner = true
                    }
                    // 3 秒后自动隐藏
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showValidationBanner = false
                        }
                    }
                }
            }
        }
    }

    /// 顶部坐标显示栏
    private var coordinateBar: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(ApocalypseTheme.primary)

            if let location = userLocation {
                Text(String(format: "%.6f, %.6f", location.latitude, location.longitude))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(ApocalypseTheme.textPrimary)
            } else {
                Text("正在获取坐标...")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Spacer()

            // 追踪状态指示（追踪中显示点数）
            if locationManager.isTracking {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("\(locationManager.pathCoordinates.count)点")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            ApocalypseTheme.cardBackground
                .opacity(0.9)
        )
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// 圈地按钮
    private var trackingButton: some View {
        Button(action: {
            if locationManager.isTracking {
                locationManager.stopPathTracking()
            } else {
                locationManager.startPathTracking()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: locationManager.isTracking ? "stop.fill" : "flag.fill")
                    .font(.system(size: 14))

                if locationManager.isTracking {
                    Text("停止圈地")
                        .font(.system(size: 14, weight: .medium))
                    Text("(\(locationManager.pathCoordinates.count))")
                        .font(.system(size: 12))
                } else {
                    Text("开始圈地")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(locationManager.isTracking ? Color.red : ApocalypseTheme.primary)
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    /// 定位按钮
    private var locateButton: some View {
        Button(action: {
            // 重新定位：重置标志，地图会在下次位置更新时居中
            hasLocatedUser = false
        }) {
            Image(systemName: "location.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(ApocalypseTheme.primary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    /// 速度警告横幅
    /// - Parameter warning: 警告信息
    private func speedWarningBanner(warning: String) -> some View {
        HStack(spacing: 8) {
            // 警告图标
            Image(systemName: locationManager.isTracking ? "exclamationmark.triangle.fill" : "xmark.octagon.fill")
                .font(.system(size: 16))

            // 警告文字
            Text(warning)
                .font(.system(size: 14, weight: .medium))

            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            // 根据是否还在追踪选择颜色
            // 黄色：警告但继续追踪
            // 红色：已停止追踪
            RoundedRectangle(cornerRadius: 8)
                .fill(locationManager.isTracking ? Color.orange : Color.red)
        )
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// 验证结果横幅（根据验证结果显示成功或失败）
    private var validationResultBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: locationManager.territoryValidationPassed
                  ? "checkmark.circle.fill"
                  : "xmark.circle.fill")
                .font(.body)

            if locationManager.territoryValidationPassed {
                Text("圈地成功！领地面积: \(String(format: "%.0f", locationManager.calculatedArea))m²")
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else {
                Text(locationManager.territoryValidationError ?? "验证失败")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(locationManager.territoryValidationPassed ? Color.green : Color.red)
        .padding(.top, 50)
    }

    /// 加载中覆盖层
    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                .scaleEffect(1.5)

            Text("正在定位末世坐标...")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
        }
        .padding(32)
        .background(
            ApocalypseTheme.cardBackground
                .opacity(0.95)
        )
        .cornerRadius(16)
    }

    /// 权限被拒绝时的提示视图
    private var deniedPermissionView: some View {
        VStack(spacing: 24) {
            // 图标
            Image(systemName: "location.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.warning)

            // 标题
            Text("需要定位权限")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 说明文字
            Text("《地球新主》需要获取您的位置来显示您在末日世界中的坐标，帮助您探索和圈定领地。")
                .font(.body)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // 前往设置按钮
            Button(action: {
                locationManager.openSettings()
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("前往设置")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ApocalypseTheme.primary)
                .cornerRadius(12)
            }
            .padding(.horizontal, 48)
            .padding(.top, 8)

            // 错误信息（如果有）
            if let error = locationManager.locationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.danger)
                    .padding(.top, 8)
            }
        }
        .padding(24)
        .background(
            ApocalypseTheme.cardBackground
                .cornerRadius(20)
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview

#Preview {
    MapTabView()
        .environmentObject(LocationManager())
}
