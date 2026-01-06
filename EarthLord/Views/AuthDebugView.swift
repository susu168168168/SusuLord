//
//  AuthDebugView.swift
//  EarthLord
//
//  Created by Claude on 2026/01/06.
//

import SwiftUI
import Supabase

/// 认证调试页面
/// 用于测试和调试认证功能
struct AuthDebugView: View {
    @EnvironmentObject var authManager: AuthManager

    // MARK: - State

    @State private var testEmail = ""
    @State private var testPassword = ""
    @State private var testOTP = ""

    @State private var debugLog = ""
    @State private var isTestRunning = false

    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 状态卡片
                        statusCard

                        // 测试输入
                        inputSection

                        // 快速测试按钮
                        quickTestSection

                        // 完整流程测试
                        fullFlowTestSection

                        // 调试日志
                        debugLogSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("认证调试")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前状态")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Divider()

            statusRow(
                label: "认证状态",
                value: authManager.isAuthenticated ? "✅ 已登录" : "❌ 未登录",
                color: authManager.isAuthenticated ? ApocalypseTheme.success : ApocalypseTheme.danger
            )

            statusRow(
                label: "当前用户",
                value: authManager.currentUser?.email ?? "无",
                color: ApocalypseTheme.textSecondary
            )

            statusRow(
                label: "需要设置密码",
                value: authManager.needsPasswordSetup ? "是" : "否",
                color: ApocalypseTheme.textSecondary
            )

            statusRow(
                label: "OTP已发送",
                value: authManager.otpSent ? "是" : "否",
                color: ApocalypseTheme.textSecondary
            )

            statusRow(
                label: "OTP已验证",
                value: authManager.otpVerified ? "是" : "否",
                color: ApocalypseTheme.textSecondary
            )

            if let error = authManager.errorMessage {
                Divider()
                Text("错误: \(error)")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.danger)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    private func statusRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 16) {
            Text("测试数据")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("测试邮箱", text: $testEmail)
                .textFieldStyle(DebugTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("测试密码", text: $testPassword)
                .textFieldStyle(DebugTextFieldStyle())

            TextField("验证码（6位）", text: $testOTP)
                .textFieldStyle(DebugTextFieldStyle())
                .keyboardType(.numberPad)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Quick Test Section

    private var quickTestSection: some View {
        VStack(spacing: 12) {
            Text("快速测试")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 测试连接
            testButton(
                title: "1️⃣ 测试 Supabase 连接",
                color: ApocalypseTheme.info
            ) {
                await testConnection()
            }

            // 测试注册
            testButton(
                title: "2️⃣ 测试注册（发送OTP）",
                color: ApocalypseTheme.primary
            ) {
                await testRegister()
            }

            // 测试验证OTP
            testButton(
                title: "3️⃣ 验证 OTP",
                color: ApocalypseTheme.warning
            ) {
                await testVerifyOTP()
            }

            // 测试登录
            testButton(
                title: "4️⃣ 测试登录",
                color: ApocalypseTheme.success
            ) {
                await testLogin()
            }

            // 退出登录
            testButton(
                title: "5️⃣ 退出登录",
                color: ApocalypseTheme.danger
            ) {
                await testLogout()
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Full Flow Test Section

    private var fullFlowTestSection: some View {
        VStack(spacing: 12) {
            Text("完整流程测试")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            testButton(
                title: "🚀 测试完整注册流程",
                color: .purple
            ) {
                await testFullRegistrationFlow()
            }

            testButton(
                title: "🔄 检查会话状态",
                color: .blue
            ) {
                await testCheckSession()
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Debug Log Section

    private var debugLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("调试日志")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                Button(action: {
                    debugLog = ""
                }) {
                    Text("清空")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }

            ScrollView {
                Text(debugLog.isEmpty ? "等待测试..." : debugLog)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 200)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Test Button Component

    private func testButton(title: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button(action: {
            Task {
                isTestRunning = true
                await action()
                isTestRunning = false
            }
        }) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if isTestRunning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
        .disabled(isTestRunning)
    }

    // MARK: - Test Functions

    /// 测试 Supabase 连接
    private func testConnection() async {
        addLog("🔍 开始测试连接...")
        addLog("📡 URL: https://kgggszofjfabtuwywsxl.supabase.co")

        do {
            let supabase = SupabaseClientManager.shared
            let _: [EmptyResponse] = try await supabase
                .from("test_table")
                .select()
                .execute()
                .value

            addLog("✅ 连接成功（意外：表存在）")
        } catch {
            let errorStr = String(describing: error)
            if errorStr.contains("PGRST") || errorStr.contains("relation") {
                addLog("✅ 连接成功！(服务器已响应)")
                addLog("ℹ️ 表不存在是正常的")
            } else {
                addLog("❌ 连接失败: \(error.localizedDescription)")
            }
        }
    }

    /// 测试注册
    private func testRegister() async {
        guard !testEmail.isEmpty else {
            addLog("❌ 请先输入测试邮箱")
            return
        }

        addLog("📧 发送注册验证码到: \(testEmail)")
        await authManager.sendRegisterOTP(email: testEmail)

        if authManager.otpSent {
            addLog("✅ 验证码发送成功")
            addLog("ℹ️ 请检查邮箱并输入验证码")
        } else if let error = authManager.errorMessage {
            addLog("❌ 发送失败: \(error)")
        }
    }

    /// 测试验证 OTP
    private func testVerifyOTP() async {
        guard !testEmail.isEmpty else {
            addLog("❌ 请先输入测试邮箱")
            return
        }

        guard testOTP.count == 6 else {
            addLog("❌ 请输入6位验证码")
            return
        }

        addLog("🔐 验证 OTP: \(testOTP)")
        await authManager.verifyRegisterOTP(email: testEmail, code: testOTP)

        if authManager.otpVerified {
            addLog("✅ OTP 验证成功")
            addLog("ℹ️ 用户已登录，但需要设置密码")
        } else if let error = authManager.errorMessage {
            addLog("❌ 验证失败: \(error)")
        }
    }

    /// 测试登录
    private func testLogin() async {
        guard !testEmail.isEmpty, !testPassword.isEmpty else {
            addLog("❌ 请输入邮箱和密码")
            return
        }

        addLog("🔑 尝试登录...")
        addLog("📧 邮箱: \(testEmail)")
        await authManager.signIn(email: testEmail, password: testPassword)

        if authManager.isAuthenticated {
            addLog("✅ 登录成功！")
            addLog("👤 用户ID: \(authManager.currentUser?.id.uuidString ?? "未知")")
        } else if let error = authManager.errorMessage {
            addLog("❌ 登录失败: \(error)")
        }
    }

    /// 测试退出登录
    private func testLogout() async {
        addLog("👋 退出登录...")
        await authManager.signOut()

        if !authManager.isAuthenticated {
            addLog("✅ 已退出登录")
        } else {
            addLog("❌ 退出失败")
        }
    }

    /// 测试完整注册流程
    private func testFullRegistrationFlow() async {
        addLog("🚀 开始完整注册流程测试...")
        addLog("ℹ️ 这将测试：发送OTP → 验证 → 设置密码")
        addLog("⚠️ 需要手动输入收到的验证码")

        // 步骤1：发送 OTP
        await testRegister()
    }

    /// 测试检查会话
    private func testCheckSession() async {
        addLog("🔍 检查当前会话...")
        await authManager.checkSession()

        if authManager.isAuthenticated {
            addLog("✅ 检测到有效会话")
            addLog("👤 用户: \(authManager.currentUser?.email ?? "未知")")
        } else {
            addLog("ℹ️ 没有有效会话")
        }
    }

    // MARK: - Helper

    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)\n"
        debugLog += logEntry
        print(logEntry)
    }
}

// MARK: - Debug Text Field Style

struct DebugTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.black.opacity(0.3))
            .foregroundColor(ApocalypseTheme.textPrimary)
            .cornerRadius(8)
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Decodable {}

// MARK: - Preview

#Preview {
    AuthDebugView()
        .environmentObject(AuthManager())
}
