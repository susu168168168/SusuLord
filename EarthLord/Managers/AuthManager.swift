//
//  AuthManager.swift
//  EarthLord
//
//  Created by Claude on 2026/01/05.
//

import Foundation
import SwiftUI
import Supabase
import Combine
import GoogleSignIn

/// 认证管理器
/// 管理用户的注册、登录、找回密码等认证流程
///
/// 认证流程说明：
/// - 注册：发验证码 → 验证（此时已登录但没密码）→ 强制设置密码 → 完成
/// - 登录：邮箱 + 密码（直接登录）
/// - 找回密码：发验证码 → 验证（此时已登录）→ 设置新密码 → 完成
@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published Properties

    /// 是否已完全认证（已登录且完成所有流程）
    @Published var isAuthenticated: Bool = false

    /// 是否需要设置密码（OTP验证后需要设置密码）
    @Published var needsPasswordSetup: Bool = false

    /// 当前登录用户
    @Published var currentUser: User? = nil

    /// 是否正在加载中
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String? = nil

    /// OTP是否已发送
    @Published var otpSent: Bool = false

    /// OTP是否已验证（验证码已验证，等待设置密码）
    @Published var otpVerified: Bool = false

    // MARK: - Private Properties

    /// Supabase 客户端实例
    private let supabase = SupabaseClientManager.shared

    /// 认证状态监听任务
    private var authStateTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        // 初始化时检查会话
        Task {
            await checkSession()
        }

        // 启动认证状态监听
        startAuthStateListener()
    }

    deinit {
        // 清理监听任务
        authStateTask?.cancel()
    }

    // MARK: - 注册流程

    /// 发送注册验证码
    /// - Parameter email: 用户邮箱
    func sendRegisterOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 调用 Supabase Auth API 发送 OTP
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )

            // 成功发送
            otpSent = true
            print("✅ 注册验证码已发送到: \(email)")

        } catch {
            // 发送失败
            errorMessage = "发送验证码失败: \(error.localizedDescription)"
            print("❌ 发送注册验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 验证注册OTP
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 验证码
    ///
    /// 注意：验证成功后用户就已登录，但 isAuthenticated 保持 false，
    /// 直到用户完成密码设置
    func verifyRegisterOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )

            // 验证成功，用户已登录但需要设置密码
            currentUser = session.user
            otpVerified = true
            needsPasswordSetup = true
            // 注意：isAuthenticated 保持 false，等待密码设置

            print("✅ 注册验证码验证成功，用户ID: \(session.user.id)")
            print("⚠️ 用户需要设置密码才能完成注册")

        } catch {
            // 验证失败
            errorMessage = "验证码错误或已过期: \(error.localizedDescription)"
            print("❌ 验证注册OTP失败: \(error)")
        }

        isLoading = false
    }

    /// 完成注册（设置密码）
    /// - Parameter password: 新密码
    ///
    /// 这是注册流程的最后一步，设置密码后才能进入主页
    func completeRegistration(password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            let user = try await supabase.auth.update(
                user: UserAttributes(password: password)
            )

            // 密码设置成功，完成注册
            currentUser = user
            needsPasswordSetup = false
            isAuthenticated = true
            otpVerified = false
            otpSent = false

            print("✅ 注册完成，用户ID: \(user.id)")

        } catch {
            // 设置密码失败
            errorMessage = "设置密码失败: \(error.localizedDescription)"
            print("❌ 完成注册失败: \(error)")
        }

        isLoading = false
    }

    // MARK: - 登录

    /// 使用邮箱和密码登录
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 密码
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 使用邮箱密码登录
            let session = try await supabase.auth.signIn(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )

            // 登录成功
            currentUser = session.user
            isAuthenticated = true
            needsPasswordSetup = false

            print("✅ 登录成功，用户ID: \(session.user.id)")
            print("✅ 用户邮箱: \(session.user.email ?? "未知")")

        } catch {
            // 登录失败 - 提供更详细的错误信息
            let errorDetail = String(describing: error)

            if errorDetail.contains("Invalid login credentials") ||
               errorDetail.contains("invalid_grant") {
                errorMessage = "邮箱或密码错误，请检查后重试"
            } else if errorDetail.contains("Email not confirmed") {
                errorMessage = "邮箱未验证，请先验证邮箱"
            } else if errorDetail.contains("network") || errorDetail.contains("NSURLError") {
                errorMessage = "网络连接失败，请检查网络"
            } else {
                errorMessage = "登录失败: \(error.localizedDescription)"
            }

            print("❌ 登录失败详情: \(errorDetail)")
        }

        isLoading = false
    }

    // MARK: - 找回密码流程

    /// 发送重置密码验证码
    /// - Parameter email: 用户邮箱
    ///
    /// 这会触发 Supabase 的 Reset Password 邮件模板
    func sendResetOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 发送密码重置邮件
            try await supabase.auth.resetPasswordForEmail(email)

            // 成功发送
            otpSent = true
            print("✅ 密码重置验证码已发送到: \(email)")

        } catch {
            // 发送失败
            errorMessage = "发送重置验证码失败: \(error.localizedDescription)"
            print("❌ 发送密码重置验证码失败: \(error)")
        }

        isLoading = false
    }

    /// 验证密码重置OTP
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 验证码
    ///
    /// ⚠️ 注意：使用 .recovery 类型，不是 .email
    func verifyResetOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证密码重置 OTP（使用 .recovery 类型）
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .recovery  // ⚠️ 注意这里是 .recovery 不是 .email
            )

            // 验证成功，用户已登录但需要设置新密码
            currentUser = session.user
            otpVerified = true
            needsPasswordSetup = true
            // 注意：isAuthenticated 保持 false，等待密码设置

            print("✅ 密码重置验证码验证成功，用户ID: \(session.user.id)")
            print("⚠️ 用户需要设置新密码")

        } catch {
            // 验证失败
            errorMessage = "验证码错误或已过期: \(error.localizedDescription)"
            print("❌ 验证密码重置OTP失败: \(error)")
        }

        isLoading = false
    }

    /// 重置密码（设置新密码）
    /// - Parameter newPassword: 新密码
    func resetPassword(newPassword: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            let user = try await supabase.auth.update(
                user: UserAttributes(password: newPassword)
            )

            // 密码重置成功
            currentUser = user
            needsPasswordSetup = false
            isAuthenticated = true
            otpVerified = false
            otpSent = false

            print("✅ 密码重置成功，用户ID: \(user.id)")

        } catch {
            // 重置密码失败
            errorMessage = "重置密码失败: \(error.localizedDescription)"
            print("❌ 重置密码失败: \(error)")
        }

        isLoading = false
    }

    // MARK: - 第三方登录（预留）

    /// 使用 Apple 登录
    /// TODO: 实现 Sign in with Apple 功能
    func signInWithApple() async {
        // TODO: 实现 Apple 登录
        print("⚠️ Apple 登录功能尚未实现")
        errorMessage = "Apple 登录功能正在开发中"
    }

    /// 使用 Google 登录
    func signInWithGoogle() async {
        print("🔵 开始 Google 登录流程...")
        isLoading = true
        errorMessage = nil

        do {
            // 1. 获取 root view controller
            guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = await windowScene.windows.first?.rootViewController else {
                print("❌ 无法获取 root view controller")
                errorMessage = "初始化失败"
                isLoading = false
                return
            }

            // 2. Google Client ID
            let clientID = "115552931524-kq7og2961cc3bc7fs0m71ovcanerab1h.apps.googleusercontent.com"
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            print("🔵 正在打开 Google 登录页面...")

            // 3. 执行 Google 登录
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ 无法获取 Google ID Token")
                errorMessage = "Google 登录失败"
                isLoading = false
                return
            }

            print("✅ Google 登录成功，已获取 ID Token")
            print("🔵 正在使用 ID Token 登录 Supabase...")

            // 4. 使用 Google ID Token 登录 Supabase
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken
                )
            )

            // 5. 登录成功
            currentUser = session.user
            isAuthenticated = true
            needsPasswordSetup = false

            print("✅ Supabase 登录成功！")
            print("✅ 用户 ID: \(session.user.id)")
            print("✅ 用户邮箱: \(session.user.email ?? "未知")")

        } catch let error as GIDSignInError {
            // Google 登录错误
            if error.code == .canceled {
                print("ℹ️ 用户取消了 Google 登录")
                errorMessage = nil  // 取消不显示错误
            } else {
                print("❌ Google 登录失败: \(error.localizedDescription)")
                errorMessage = "Google 登录失败: \(error.localizedDescription)"
            }
        } catch {
            // Supabase 登录错误
            print("❌ Supabase 登录失败: \(error.localizedDescription)")
            print("❌ 错误详情: \(String(describing: error))")
            errorMessage = "登录失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 其他方法

    /// 退出登录
    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            // 调用 Supabase 登出
            try await supabase.auth.signOut()

            // 清空所有状态
            currentUser = nil
            isAuthenticated = false
            needsPasswordSetup = false
            otpSent = false
            otpVerified = false

            print("✅ 已退出登录")

        } catch {
            // 退出失败
            errorMessage = "退出登录失败: \(error.localizedDescription)"
            print("❌ 退出登录失败: \(error)")
        }

        isLoading = false
    }

    /// 检查当前会话
    /// 应用启动时调用，检查是否有有效的登录会话
    func checkSession() async {
        do {
            // 获取当前会话
            let session = try await supabase.auth.session

            // 如果有会话，说明用户已登录
            currentUser = session.user

            // 检查用户是否已设置密码
            // 如果用户通过 OTP 登录但没有设置密码，需要强制设置密码
            // 这里假设通过密码登录的用户都已有密码
            // 实际项目中可能需要额外的标志位来判断

            // 暂时默认有会话就是完全认证
            isAuthenticated = true
            needsPasswordSetup = false

            print("✅ 检测到有效会话，用户ID: \(session.user.id)")

        } catch {
            // 没有有效会话或会话已过期
            handleSessionExpired()
            print("ℹ️ 未检测到有效会话: \(error.localizedDescription)")
        }
    }

    /// 处理会话过期
    /// 当会话过期或无效时，清空所有认证状态
    private func handleSessionExpired() {
        currentUser = nil
        isAuthenticated = false
        needsPasswordSetup = false
        otpSent = false
        otpVerified = false
        errorMessage = nil

        print("⚠️ 会话已过期，已清空认证状态")
    }

    // MARK: - 认证状态监听

    /// 启动认证状态监听
    /// 监听 Supabase Auth 的状态变化，自动更新认证状态
    private func startAuthStateListener() {
        authStateTask = Task {
            // 监听认证状态变化
            for await (event, session) in supabase.auth.authStateChanges {
                await handleAuthStateChange(event: event, session: session)
            }
        }
    }

    /// 处理认证状态变化
    /// - Parameters:
    ///   - event: 认证事件类型
    ///   - session: 会话信息（可选）
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        print("🔔 认证状态变化: \(event)")

        switch event {
        case .signedIn:
            // 用户登录
            if let session = session {
                currentUser = session.user

                // 如果不是在密码设置流程中，则标记为已认证
                if !needsPasswordSetup {
                    isAuthenticated = true
                }

                print("✅ 用户已登录，ID: \(session.user.id)")
            } else {
                // 登录事件但没有会话，可能是会话过期
                handleSessionExpired()
            }

        case .signedOut:
            // 用户登出或会话过期
            handleSessionExpired()
            print("✅ 用户已登出")

        case .userUpdated:
            // 用户信息更新（例如设置密码后）
            if let session = session {
                currentUser = session.user
                print("✅ 用户信息已更新，ID: \(session.user.id)")
            }

        case .tokenRefreshed:
            // Token 刷新
            if let session = session {
                currentUser = session.user
                print("🔄 Token 已刷新")
            } else {
                // Token 刷新失败，可能是会话过期
                handleSessionExpired()
                print("⚠️ Token 刷新失败，会话可能已过期")
            }

        case .passwordRecovery:
            // 密码恢复
            print("🔑 密码恢复流程")

        case .initialSession:
            // 初始会话
            if let session = session {
                currentUser = session.user
                isAuthenticated = true
                print("✅ 初始会话加载，用户ID: \(session.user.id)")
            } else {
                // 没有初始会话
                handleSessionExpired()
            }

        @unknown default:
            print("⚠️ 未知认证状态事件")
        }
    }
}
