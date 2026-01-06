//
//  ProfileTabView.swift
//  EarthLord
//
//  Created by suyinghui on 2025/12/31.
//

import SwiftUI
import Supabase

/// 个人中心页面
struct ProfileTabView: View {
    /// 认证管理器
    @EnvironmentObject var authManager: AuthManager

    /// 是否显示退出确认弹窗
    @State private var showLogoutConfirmation = false

    /// 是否正在退出中
    @State private var isLoggingOut = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 用户信息卡片
                    userInfoCard

                    // 设置选项列表
                    settingsSection

                    // 退出登录按钮
                    logoutButton

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("个人中心")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "确认退出登录？",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("退出登录", role: .destructive) {
                performLogout()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("退出后需要重新登录才能使用")
        }
        .overlay {
            if isLoggingOut {
                loadingOverlay
            }
        }
    }

    // MARK: - User Info Card

    private var userInfoCard: some View {
        VStack(spacing: 20) {
            // 用户头像
            ZStack {
                // 外圈光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ApocalypseTheme.primary.opacity(0.3),
                                ApocalypseTheme.primary.opacity(0)
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                // 头像背景
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ApocalypseTheme.primary,
                                ApocalypseTheme.primaryDark
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                // 头像图标
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            // 用户信息
            VStack(spacing: 8) {
                // 用户名 / 邮箱
                if let user = authManager.currentUser {
                    // 显示邮箱作为用户名
                    Text(user.email ?? "未知用户")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    // 用户ID
                    Text("ID: \(user.id.uuidString.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                        .monospaced()
                } else {
                    Text("未登录")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                // 身份标签
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                    Text("幸存者")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(ApocalypseTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ApocalypseTheme.primary.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: 0) {
            // 账号设置
            SettingRow(
                icon: "person.circle",
                title: "账号设置",
                iconColor: ApocalypseTheme.info
            ) {
                // TODO: 跳转到账号设置页面
                print("点击账号设置")
            }

            Divider()
                .background(ApocalypseTheme.textMuted.opacity(0.2))
                .padding(.leading, 56)

            // 通知设置
            SettingRow(
                icon: "bell.fill",
                title: "通知设置",
                iconColor: ApocalypseTheme.warning
            ) {
                // TODO: 跳转到通知设置页面
                print("点击通知设置")
            }

            Divider()
                .background(ApocalypseTheme.textMuted.opacity(0.2))
                .padding(.leading, 56)

            // 关于我们
            SettingRow(
                icon: "info.circle.fill",
                title: "关于我们",
                iconColor: ApocalypseTheme.success
            ) {
                // TODO: 跳转到关于页面
                print("点击关于我们")
            }
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Logout Button

    private var logoutButton: some View {
        Button(action: {
            showLogoutConfirmation = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title3)

                Text("退出登录")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ApocalypseTheme.danger)
            .cornerRadius(16)
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("正在退出...")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(32)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Actions

    /// 执行退出登录
    private func performLogout() {
        isLoggingOut = true

        Task {
            // 调用认证管理器的退出方法
            await authManager.signOut()

            // 延迟一下再关闭加载状态，让用户看到反馈
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

            await MainActor.run {
                isLoggingOut = false
            }
        }
    }
}

// MARK: - Setting Row Component

/// 设置行组件
struct SettingRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                // 标题
                Text(title)
                    .font(.body)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                // 箭头
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
            .environmentObject(AuthManager())
    }
}
