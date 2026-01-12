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

    /// 是否显示删除账户确认对话框
    @State private var showDeleteAccountConfirmation = false

    /// 删除账户确认输入
    @State private var deleteConfirmationText = ""

    /// 是否正在删除账户中
    @State private var isDeletingAccount = false

    /// 删除账户错误信息
    @State private var deleteAccountError: String?

    /// 是否显示删除成功提示
    @State private var showDeleteSuccessAlert = false

    /// 是否显示语言选择器
    @State private var showLanguagePicker = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 页面标题
                    Text("幸存者档案")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // 用户信息卡片
                    userInfoCard

                    // 统计区域
                    statsSection

                    // 设置选项列表
                    settingsSection

                    // 退出登录按钮
                    logoutButton

                    // 删除账户按钮
                    deleteAccountButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 140)
            }
        }
        .navigationBarHidden(true)
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
        .sheet(isPresented: $showDeleteAccountConfirmation) {
            deleteAccountConfirmationSheet
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerView()
        }
        .alert("删除成功", isPresented: $showDeleteSuccessAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("您的账户已被永久删除")
        }
        .alert("删除失败", isPresented: .constant(deleteAccountError != nil)) {
            Button("确定", role: .cancel) {
                deleteAccountError = nil
            }
        } message: {
            Text(deleteAccountError ?? "")
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
                    // 显示用户名（邮箱@前的部分）
                    let email = user.email ?? "未知用户"
                    let username = email.components(separatedBy: "@").first ?? email

                    Text(username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    // 显示完整邮箱
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    // 用户ID
                    Text(LanguageManager.shared.localizedString("ID: %@...", String(user.id.uuidString.prefix(8))))
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textMuted)
                        .monospaced()
                } else {
                    Text("未登录")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 0) {
            // 领地
            StatItem(icon: "flag.fill", value: "0", label: "领地", color: ApocalypseTheme.primary)

            // 分隔线
            Rectangle()
                .fill(ApocalypseTheme.textMuted.opacity(0.3))
                .frame(width: 1, height: 50)

            // 资源点
            StatItem(icon: "mappin.circle.fill", value: "0", label: "资源点", color: ApocalypseTheme.primary)

            // 分隔线
            Rectangle()
                .fill(ApocalypseTheme.textMuted.opacity(0.3))
                .frame(width: 1, height: 50)

            // 探索距离
            StatItem(icon: "figure.walk", value: "0", label: "探索距离", color: ApocalypseTheme.primary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: 0) {
            // 设置
            SettingRow(
                icon: "gearshape.fill",
                title: "设置",
                iconColor: ApocalypseTheme.textSecondary
            ) {
                showLanguagePicker = true
            }

            Divider()
                .background(ApocalypseTheme.textMuted.opacity(0.2))
                .padding(.leading, 60)

            // 通知
            SettingRow(
                icon: "bell.fill",
                title: "通知",
                iconColor: ApocalypseTheme.primary
            ) {
                // TODO: 跳转到通知设置页面
                print("点击通知")
            }

            Divider()
                .background(ApocalypseTheme.textMuted.opacity(0.2))
                .padding(.leading, 60)

            // 帮助
            SettingRow(
                icon: "questionmark.circle.fill",
                title: "帮助",
                iconColor: ApocalypseTheme.info
            ) {
                // TODO: 跳转到帮助页面
                print("点击帮助")
            }

            Divider()
                .background(ApocalypseTheme.textMuted.opacity(0.2))
                .padding(.leading, 60)

            // 关于
            SettingRow(
                icon: "info.circle.fill",
                title: "关于",
                iconColor: ApocalypseTheme.success
            ) {
                // TODO: 跳转到关于页面
                print("点击关于")
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

    // MARK: - Delete Account Button

    private var deleteAccountButton: some View {
        Button(action: {
            print("🗑️ 点击删除账户按钮")
            showDeleteAccountConfirmation = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "trash.fill")
                    .font(.title3)

                Text("删除账户")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
            )
        }
    }

    // MARK: - Delete Account Confirmation Sheet

    private var deleteAccountConfirmationSheet: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 危险图标
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }
                .padding(.top, 40)

                // 标题
                VStack(spacing: 8) {
                    Text("删除账户")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Text("此操作无法撤销")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                // 警告说明
                VStack(alignment: .leading, spacing: 12) {
                    Text("删除账户将会：")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        warningItem(text: "永久删除您的所有数据")
                        warningItem(text: "删除所有领地和资源点")
                        warningItem(text: "无法恢复任何信息")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)

                // 确认输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("请输入 \"删除\" 以确认：")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    TextField("", text: $deleteConfirmationText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Spacer()

                // 按钮组
                VStack(spacing: 12) {
                    // 确认删除按钮
                    Button(action: {
                        performDeleteAccount()
                    }) {
                        HStack {
                            if isDeletingAccount {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "trash.fill")
                                    .font(.body)
                            }

                            Text(isDeletingAccount ? "删除中..." : "确认删除")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(deleteConfirmationText == "删除" ? Color.red : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(deleteConfirmationText != "删除" || isDeletingAccount)

                    // 取消按钮
                    Button(action: {
                        print("🔵 取消删除账户")
                        showDeleteAccountConfirmation = false
                        deleteConfirmationText = ""
                    }) {
                        Text("取消")
                            .font(.headline)
                            .foregroundColor(ApocalypseTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ApocalypseTheme.cardBackground)
                            .cornerRadius(12)
                    }
                    .disabled(isDeletingAccount)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helper Views

    private func warningItem(text: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(.red)

            Text(text)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
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

    /// 执行删除账户
    private func performDeleteAccount() {
        print("🗑️ 开始执行删除账户流程...")
        print("✅ 用户已输入确认文本：\(deleteConfirmationText)")

        isDeletingAccount = true

        Task {
            do {
                // 调用认证管理器的删除账户方法
                print("🔵 正在调用 authManager.deleteAccount()...")
                try await authManager.deleteAccount()

                print("✅ 删除账户成功")

                // 延迟一下让用户看到反馈
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

                await MainActor.run {
                    print("🔵 更新 UI 状态")
                    isDeletingAccount = false
                    showDeleteAccountConfirmation = false
                    deleteConfirmationText = ""
                    showDeleteSuccessAlert = true
                }

            } catch {
                print("❌ 删除账户失败: \(error.localizedDescription)")

                await MainActor.run {
                    isDeletingAccount = false
                    showDeleteAccountConfirmation = false
                    deleteConfirmationText = ""
                    deleteAccountError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Setting Row Component

/// 设置行组件
struct SettingRow: View {
    let icon: String
    let title: LocalizedStringKey
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标（无背景圆圈）
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

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
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Stat Item Component

/// 统计项组件
struct StatItem: View {
    let icon: String
    let value: String
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            // 数值
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 标签
            Text(label)
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
            .environmentObject(AuthManager())
    }
}
