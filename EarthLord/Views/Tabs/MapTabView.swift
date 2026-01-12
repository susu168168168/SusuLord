//
//  MapTabView.swift
//  EarthLord
//
//  地图页面 - 显示末世风格地图和用户位置
//

import SwiftUI
import MapKit

struct MapTabView: View {

    // MARK: - State Properties

    /// 定位管理器
    @StateObject private var locationManager = LocationManager()

    /// 用户位置坐标
    @State private var userLocation: CLLocationCoordinate2D?

    /// 是否已完成首次定位
    @State private var hasLocatedUser = false

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
            // 地图
            MapViewRepresentable(
                userLocation: $userLocation,
                hasLocatedUser: $hasLocatedUser
            )
            .ignoresSafeArea()

            // 顶部坐标显示栏
            VStack {
                coordinateBar
                Spacer()
            }

            // 右下角定位按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    locateButton
                        .padding(.trailing, 16)
                        .padding(.bottom, 100)
                }
            }

            // 加载指示器（定位中）
            if !hasLocatedUser && locationManager.isAuthorized {
                loadingOverlay
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
}
