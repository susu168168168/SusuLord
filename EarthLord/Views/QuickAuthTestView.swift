//
//  QuickAuthTestView.swift
//  EarthLord
//
//  Created by Claude on 2026/01/06.
//

import SwiftUI
import Supabase

/// 快速认证测试视图
/// 用于快速创建测试用户并测试登录
struct QuickAuthTestView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var testEmail = "test@earthlord.com"
    @State private var testPassword = "test123456"
    @State private var statusLog = ""
    @State private var isTesting = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    headerSection

                    // 测试账号信息
                    accountInfoCard

                    // 快速操作按钮
                    quickActionsSection

                    // 状态日志
                    statusLogSection
                }
                .padding(20)
            }
        }
        .navigationTitle("快速认证测试")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ApocalypseTheme.success, ApocalypseTheme.info],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("快速认证测试")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text("一键创建测试账号并登录")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Account Info Card

    private var accountInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("测试账号信息")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 邮箱
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                TextField("测试邮箱", text: $testEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            // 密码
            VStack(alignment: .leading, spacing: 8) {
                Text("密码")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                TextField("测试密码", text: $testPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Text("💡 提示：密码长度至少6位")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.warning)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("快速操作")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 方案 1：通过 Supabase 注册（推荐）
            actionButton(
                title: "方案1：完整注册流程",
                subtitle: "发送验证码 → 验证 → 设置密码",
                icon: "envelope.fill",
                color: ApocalypseTheme.primary
            ) {
                await testFullRegistration()
            }

            // 方案 2：手动在 Supabase 控制台创建
            actionButton(
                title: "方案2：手动创建后测试登录",
                subtitle: "假设已在控制台创建用户",
                icon: "key.fill",
                color: ApocalypseTheme.success
            ) {
                await testDirectLogin()
            }

            // 检查当前会话
            actionButton(
                title: "检查当前会话状态",
                subtitle: "查看是否已登录",
                icon: "person.circle.fill",
                color: ApocalypseTheme.info
            ) {
                await checkCurrentSession()
            }

            // 测试 Supabase 连接
            actionButton(
                title: "测试 Supabase 连接",
                subtitle: "确认服务器可访问",
                icon: "network",
                color: .purple
            ) {
                await testSupabaseConnection()
            }

            // 退出登录
            if authManager.isAuthenticated {
                actionButton(
                    title: "退出登录",
                    subtitle: "登出当前用户",
                    icon: "rectangle.portrait.and.arrow.right",
                    color: ApocalypseTheme.danger
                ) {
                    await performLogout()
                }
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () async -> Void
    ) -> some View {
        Button(action: {
            Task {
                isTesting = true
                await action()
                isTesting = false
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                Spacer()

                if isTesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: color))
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .disabled(isTesting)
    }

    // MARK: - Status Log

    private var statusLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("状态日志")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                Button(action: {
                    statusLog = ""
                }) {
                    Text("清空")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }

            ScrollView {
                Text(statusLog.isEmpty ? "等待操作..." : statusLog)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 250)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Test Functions

    /// 方案1：完整注册流程
    private func testFullRegistration() async {
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLog("🚀 开始完整注册流程")
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLog("📧 邮箱: \(testEmail)")
        addLog("")

        // 步骤1：发送 OTP
        addLog("📤 步骤1: 发送验证码...")
        await authManager.sendRegisterOTP(email: testEmail)

        if authManager.otpSent {
            addLog("✅ 验证码已发送")
            addLog("")
            addLog("⚠️ 请按以下步骤操作：")
            addLog("1. 检查邮箱收取验证码")
            addLog("2. 返回登录页或使用调试页面")
            addLog("3. 输入验证码进行验证")
            addLog("4. 设置密码: \(testPassword)")
            addLog("5. 完成注册")
            addLog("")
            addLog("💡 如果未收到邮件：")
            addLog("   - 检查垃圾邮件箱")
            addLog("   - 确认邮箱地址正确")
            addLog("   - 在 Supabase 控制台检查邮件配置")
        } else if let error = authManager.errorMessage {
            addLog("❌ 发送失败")
            addLog("错误: \(error)")
            addLog("")
            addLog("📌 可能的原因：")
            addLog("   - 该邮箱已注册")
            addLog("   - 网络连接问题")
            addLog("   - Supabase 邮件配置问题")
        }
    }

    /// 方案2：直接登录（假设已在控制台创建）
    private func testDirectLogin() async {
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLog("🔐 测试直接登录")
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLog("📧 邮箱: \(testEmail)")
        addLog("🔑 密码: \(testPassword)")
        addLog("")

        addLog("🔄 正在登录...")
        await authManager.signIn(email: testEmail, password: testPassword)

        await Task.sleep(1_000_000_000) // 等待1秒

        if authManager.isAuthenticated {
            addLog("✅ 登录成功！")
            addLog("")
            if let user = authManager.currentUser {
                addLog("👤 用户信息：")
                addLog("   ID: \(user.id.uuidString)")
                addLog("   邮箱: \(user.email ?? "未知")")
                addLog("   创建时间: \(user.createdAt)")
            }
            addLog("")
            addLog("🎉 可以开始使用 App 了！")
        } else {
            addLog("❌ 登录失败")
            if let error = authManager.errorMessage {
                addLog("错误: \(error)")
            }
            addLog("")
            addLog("📌 请按以下步骤排查：")
            addLog("")
            addLog("1️⃣ 确认用户已在 Supabase 创建")
            addLog("   访问: https://app.supabase.com")
            addLog("   进入: Authentication → Users")
            addLog("   检查用户是否存在")
            addLog("")
            addLog("2️⃣ 如果用户不存在，手动创建：")
            addLog("   - 点击 'Add User'")
            addLog("   - Email: \(testEmail)")
            addLog("   - Password: \(testPassword)")
            addLog("   - 取消勾选 'Auto Confirm User'")
            addLog("   - 点击 'Create User'")
            addLog("")
            addLog("3️⃣ 确认邮箱已验证：")
            addLog("   - 在用户列表查看用户")
            addLog("   - 'Email Confirmed' 应该为 ✅")
            addLog("   - 如未验证，点击用户编辑")
            addLog("   - 勾选 'Email Confirmed'")
            addLog("")
            addLog("4️⃣ 检查密码是否正确")
            addLog("   - 如果忘记密码，在控制台重置")
            addLog("")
            addLog("5️⃣ 使用 '方案1' 通过 App 注册")
        }
    }

    /// 检查当前会话
    private func checkCurrentSession() async {
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLog("🔍 检查当前会话状态")
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLog("")

        await authManager.checkSession()

        await Task.sleep(500_000_000) // 等待0.5秒

        if authManager.isAuthenticated {
            addLog("✅ 检测到有效会话")
            addLog("")
            if let user = authManager.currentUser {
                addLog("👤 当前用户：")
                addLog("   邮箱: \(user.email ?? "未知")")
                addLog("   ID: \(user.id.uuidString)")
            }
        } else {
            addLog("❌ 未检测到有效会话")
            addLog("ℹ️ 需要登录才能使用 App")
        }
    }

    /// 测试 Supabase 连接
    private func testSupabaseConnection() async {
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLog("🌐 测试 Supabase 连接")
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLog("📡 URL: https://kgggszofjfabtuwywsxl.supabase.co")
        addLog("")

        do {
            let supabase = SupabaseClientManager.shared
            addLog("🔄 发送测试请求...")

            let _: [EmptyModel] = try await supabase
                .from("non_existent_table")
                .select()
                .execute()
                .value

            addLog("✅ 连接成功（意外：表存在）")
        } catch {
            let errorStr = String(describing: error)
            addLog("📥 收到响应")

            if errorStr.contains("PGRST") ||
               errorStr.contains("relation") ||
               errorStr.contains("does not exist") {
                addLog("✅ 连接成功！")
                addLog("ℹ️ 服务器正常响应（表不存在是预期的）")
            } else {
                addLog("❌ 连接失败")
                addLog("错误: \(error.localizedDescription)")
                addLog("")
                addLog("📌 请检查：")
                addLog("   - 网络连接是否正常")
                addLog("   - Supabase URL 是否正确")
                addLog("   - Supabase 服务是否在线")
            }
        }
    }

    /// 退出登录
    private func performLogout() async {
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")
        addLog("👋 退出登录")
        addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━")

        await authManager.signOut()

        if !authManager.isAuthenticated {
            addLog("✅ 已退出登录")
        } else {
            addLog("❌ 退出失败")
        }
    }

    // MARK: - Helper

    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)\n"
        statusLog += logEntry
        print(logEntry)
    }
}

// MARK: - Empty Model

private struct EmptyModel: Decodable {}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuickAuthTestView()
            .environmentObject(AuthManager())
    }
}
