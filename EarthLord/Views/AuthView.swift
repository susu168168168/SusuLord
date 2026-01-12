//
//  AuthView.swift
//  EarthLord
//
//  Created by Claude on 2026/01/05.
//

import SwiftUI

/// 认证页面
/// 包含登录、注册、找回密码功能
struct AuthView: View {

    // MARK: - Environment

    @EnvironmentObject var authManager: AuthManager

    // MARK: - State

    /// 当前Tab：true = 登录, false = 注册
    @State private var isLoginTab = true

    /// 登录表单
    @State private var loginEmail = ""
    @State private var loginPassword = ""

    /// 注册表单
    @State private var registerEmail = ""
    @State private var registerOTP = ""
    @State private var registerPassword = ""
    @State private var registerConfirmPassword = ""

    /// 注册流程步骤：1=输入邮箱, 2=输入验证码, 3=设置密码
    @State private var registerStep = 1

    /// 忘记密码表单
    @State private var resetEmail = ""
    @State private var resetOTP = ""
    @State private var resetPassword = ""
    @State private var resetConfirmPassword = ""
    @State private var resetStep = 1

    /// 是否显示忘记密码弹窗
    @State private var showForgotPassword = false

    /// 验证码倒计时（秒）
    @State private var otpCountdown = 0
    @State private var countdownTimer: Timer?

    /// 显示Toast消息
    @State private var showToast = false
    @State private var toastMessage = ""

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景渐变
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    // Logo和标题
                    headerSection

                    // Tab切换
                    tabSelector

                    // 主内容区域
                    if isLoginTab {
                        loginSection
                    } else {
                        registerSection
                    }

                    // 第三方登录
                    thirdPartyLoginSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }

            // 加载中遮罩
            if authManager.isLoading {
                loadingOverlay
            }

            // Toast提示
            if showToast {
                toastView
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
        .onChange(of: authManager.otpVerified) { _, newValue in
            // 监听OTP验证状态，自动切换到密码设置步骤
            if newValue && !isLoginTab {
                registerStep = 3
            }
        }
        .onChange(of: authManager.errorMessage) { _, newValue in
            // 显示错误消息
            if let error = newValue {
                showToastMessage(error)
            }
        }
        .onDisappear {
            // 清理定时器
            countdownTimer?.invalidate()
        }
    }

    // MARK: - 背景渐变

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.08),
                Color(red: 0.10, green: 0.08, blue: 0.12),
                Color(red: 0.08, green: 0.08, blue: 0.10)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo图标
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ApocalypseTheme.primary, ApocalypseTheme.primaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // 标题
            Text("地球新主")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 副标题
            Text("成为末日世界的统治者")
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            // 登录Tab
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isLoginTab = true
                }
            }) {
                Text("登录")
                    .font(.headline)
                    .foregroundColor(isLoginTab ? ApocalypseTheme.textPrimary : ApocalypseTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isLoginTab ? ApocalypseTheme.cardBackground : Color.clear)
                    )
            }

            // 注册Tab
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isLoginTab = false
                }
            }) {
                Text("注册")
                    .font(.headline)
                    .foregroundColor(!isLoginTab ? ApocalypseTheme.textPrimary : ApocalypseTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(!isLoginTab ? ApocalypseTheme.cardBackground : Color.clear)
                    )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.3))
        )
    }

    // MARK: - Login Section

    private var loginSection: some View {
        VStack(spacing: 20) {
            // 邮箱输入框
            CustomTextField(
                icon: "envelope",
                placeholder: "邮箱",
                text: $loginEmail,
                keyboardType: .emailAddress
            )

            // 密码输入框
            CustomSecureField(
                icon: "lock",
                placeholder: "密码",
                text: $loginPassword
            )

            // 忘记密码链接
            HStack {
                Spacer()
                Button(action: {
                    showForgotPassword = true
                }) {
                    Text("忘记密码？")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }

            // 登录按钮
            PrimaryButton(title: "登录", isLoading: authManager.isLoading) {
                Task {
                    await performLogin()
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Register Section

    private var registerSection: some View {
        VStack(spacing: 20) {
            // 步骤指示器
            registerStepIndicator

            // 根据步骤显示不同内容
            Group {
                switch registerStep {
                case 1:
                    registerStep1View
                case 2:
                    registerStep2View
                case 3:
                    registerStep3View
                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - 注册步骤指示器

    private var registerStepIndicator: some View {
        HStack(spacing: 12) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step <= registerStep ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
                    .frame(width: step == registerStep ? 12 : 8, height: step == registerStep ? 12 : 8)
                    .animation(.spring(response: 0.3), value: registerStep)

                if step < 3 {
                    Rectangle()
                        .fill(step < registerStep ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 注册步骤1：输入邮箱

    private var registerStep1View: some View {
        VStack(spacing: 20) {
            Text("输入邮箱获取验证码")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            CustomTextField(
                icon: "envelope",
                placeholder: "邮箱",
                text: $registerEmail,
                keyboardType: .emailAddress
            )

            PrimaryButton(
                title: authManager.otpSent ? "验证码已发送" : "发送验证码",
                isLoading: authManager.isLoading
            ) {
                Task {
                    await sendRegisterOTP()
                }
            }
            .disabled(authManager.otpSent)
        }
    }

    // MARK: - 注册步骤2：输入验证码

    private var registerStep2View: some View {
        VStack(spacing: 20) {
            Text("输入6位验证码")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text(LanguageManager.shared.localizedString("验证码已发送到 %@", registerEmail))
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)

            // 验证码输入框
            CustomTextField(
                icon: "number",
                placeholder: "6位验证码",
                text: $registerOTP,
                keyboardType: .numberPad
            )
            .onChange(of: registerOTP) { _, newValue in
                // 限制只能输入数字且最多6位
                let filtered = newValue.filter { $0.isNumber }
                registerOTP = String(filtered.prefix(6))
            }

            // 重发倒计时
            if otpCountdown > 0 {
                Text("\(otpCountdown)秒后可重新发送")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            } else {
                Button(action: {
                    Task {
                        await sendRegisterOTP()
                    }
                }) {
                    Text("重新发送")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }

            PrimaryButton(title: "验证", isLoading: authManager.isLoading) {
                Task {
                    await verifyRegisterOTP()
                }
            }
            .padding(.top, 8)

            // 返回按钮
            Button(action: {
                withAnimation {
                    registerStep = 1
                    registerOTP = ""
                    authManager.otpSent = false
                }
            }) {
                Text("返回")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
    }

    // MARK: - 注册步骤3：设置密码

    private var registerStep3View: some View {
        VStack(spacing: 20) {
            Text("设置登录密码")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text("密码长度至少6位")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)

            CustomSecureField(
                icon: "lock",
                placeholder: "密码",
                text: $registerPassword
            )

            CustomSecureField(
                icon: "lock.fill",
                placeholder: "确认密码",
                text: $registerConfirmPassword
            )

            // 密码强度提示
            if !registerPassword.isEmpty {
                passwordStrengthIndicator(password: registerPassword)
            }

            PrimaryButton(title: "完成注册", isLoading: authManager.isLoading) {
                Task {
                    await completeRegistration()
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - 密码强度指示器

    private func passwordStrengthIndicator(password: String) -> some View {
        let strength = calculatePasswordStrength(password)

        return HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Rectangle()
                    .fill(index < strength ? strengthColor(strength) : ApocalypseTheme.textMuted)
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
        .padding(.horizontal, 40)
    }

    private func calculatePasswordStrength(_ password: String) -> Int {
        var strength = 0
        if password.count >= 6 { strength += 1 }
        if password.count >= 8 { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil &&
           password.rangeOfCharacter(from: .letters) != nil {
            strength += 1
        }
        return min(strength, 3)
    }

    private func strengthColor(_ strength: Int) -> Color {
        switch strength {
        case 1: return ApocalypseTheme.danger
        case 2: return ApocalypseTheme.warning
        case 3: return ApocalypseTheme.success
        default: return ApocalypseTheme.textMuted
        }
    }

    // MARK: - Third Party Login Section

    private var thirdPartyLoginSection: some View {
        VStack(spacing: 20) {
            // 分隔线
            HStack {
                Rectangle()
                    .fill(ApocalypseTheme.textMuted.opacity(0.3))
                    .frame(height: 1)
                Text("或者使用以下方式登录")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                Rectangle()
                    .fill(ApocalypseTheme.textMuted.opacity(0.3))
                    .frame(height: 1)
            }

            // Apple登录按钮
            ThirdPartyButton(
                icon: "apple.logo",
                title: "使用 Apple 登录",
                backgroundColor: .black,
                foregroundColor: .white
            ) {
                showToastMessage("Apple 登录即将开放")
            }

            // Google登录按钮
            ThirdPartyButton(
                icon: "g.circle.fill",
                title: "使用 Google 登录",
                backgroundColor: .white,
                foregroundColor: .black
            ) {
                Task {
                    await authManager.signInWithGoogle()
                }
            }
        }
    }

    // MARK: - Forgot Password Sheet

    private var forgotPasswordSheet: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    HStack {
                        Text("找回密码")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ApocalypseTheme.textPrimary)

                        Spacer()

                        Button(action: {
                            showForgotPassword = false
                            resetStep = 1
                            resetEmail = ""
                            resetOTP = ""
                            resetPassword = ""
                            resetConfirmPassword = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    }

                    // 步骤内容
                    Group {
                        switch resetStep {
                        case 1:
                            resetStep1View
                        case 2:
                            resetStep2View
                        case 3:
                            resetStep3View
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    // MARK: - 找回密码步骤1：输入邮箱

    private var resetStep1View: some View {
        VStack(spacing: 20) {
            Text("输入注册邮箱")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            CustomTextField(
                icon: "envelope",
                placeholder: "邮箱",
                text: $resetEmail,
                keyboardType: .emailAddress
            )

            PrimaryButton(
                title: authManager.otpSent ? "验证码已发送" : "发送验证码",
                isLoading: authManager.isLoading
            ) {
                Task {
                    await sendResetOTP()
                }
            }
            .disabled(authManager.otpSent)
        }
    }

    // MARK: - 找回密码步骤2：输入验证码

    private var resetStep2View: some View {
        VStack(spacing: 20) {
            Text("输入6位验证码")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text(LanguageManager.shared.localizedString("验证码已发送到 %@", resetEmail))
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)

            CustomTextField(
                icon: "number",
                placeholder: "6位验证码",
                text: $resetOTP,
                keyboardType: .numberPad
            )
            .onChange(of: resetOTP) { _, newValue in
                let filtered = newValue.filter { $0.isNumber }
                resetOTP = String(filtered.prefix(6))
            }

            if otpCountdown > 0 {
                Text("\(otpCountdown)秒后可重新发送")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            } else {
                Button(action: {
                    Task {
                        await sendResetOTP()
                    }
                }) {
                    Text("重新发送")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }

            PrimaryButton(title: "验证", isLoading: authManager.isLoading) {
                Task {
                    await verifyResetOTP()
                }
            }

            Button(action: {
                withAnimation {
                    resetStep = 1
                    resetOTP = ""
                    authManager.otpSent = false
                }
            }) {
                Text("返回")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
    }

    // MARK: - 找回密码步骤3：设置新密码

    private var resetStep3View: some View {
        VStack(spacing: 20) {
            Text("设置新密码")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            CustomSecureField(
                icon: "lock",
                placeholder: "新密码",
                text: $resetPassword
            )

            CustomSecureField(
                icon: "lock.fill",
                placeholder: "确认密码",
                text: $resetConfirmPassword
            )

            if !resetPassword.isEmpty {
                passwordStrengthIndicator(password: resetPassword)
            }

            PrimaryButton(title: "重置密码", isLoading: authManager.isLoading) {
                Task {
                    await performResetPassword()
                }
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                    .scaleEffect(1.5)

                Text("加载中...")
                    .foregroundColor(ApocalypseTheme.textPrimary)
            }
            .padding(32)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Toast View

    private var toastView: some View {
        VStack {
            Spacer()

            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.white)
                Text(toastMessage)
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(ApocalypseTheme.danger)
            .cornerRadius(12)
            .shadow(radius: 10)
            .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: showToast)
    }

    // MARK: - Actions

    /// 执行登录
    private func performLogin() async {
        guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
            showToastMessage("请输入邮箱和密码")
            return
        }

        await authManager.signIn(email: loginEmail, password: loginPassword)
    }

    /// 发送注册验证码
    private func sendRegisterOTP() async {
        guard !registerEmail.isEmpty else {
            showToastMessage("请输入邮箱")
            return
        }

        guard isValidEmail(registerEmail) else {
            showToastMessage("邮箱格式不正确")
            return
        }

        await authManager.sendRegisterOTP(email: registerEmail)

        if authManager.otpSent {
            withAnimation {
                registerStep = 2
            }
            startCountdown()
        }
    }

    /// 验证注册验证码
    private func verifyRegisterOTP() async {
        guard registerOTP.count == 6 else {
            showToastMessage("请输入6位验证码")
            return
        }

        await authManager.verifyRegisterOTP(email: registerEmail, code: registerOTP)

        // 如果验证成功，会自动触发 onChange 切换到步骤3
    }

    /// 完成注册
    private func completeRegistration() async {
        guard !registerPassword.isEmpty else {
            showToastMessage("请输入密码")
            return
        }

        guard registerPassword.count >= 6 else {
            showToastMessage("密码长度至少6位")
            return
        }

        guard registerPassword == registerConfirmPassword else {
            showToastMessage("两次输入的密码不一致")
            return
        }

        await authManager.completeRegistration(password: registerPassword)
    }

    /// 发送重置密码验证码
    private func sendResetOTP() async {
        guard !resetEmail.isEmpty else {
            showToastMessage("请输入邮箱")
            return
        }

        guard isValidEmail(resetEmail) else {
            showToastMessage("邮箱格式不正确")
            return
        }

        await authManager.sendResetOTP(email: resetEmail)

        if authManager.otpSent {
            withAnimation {
                resetStep = 2
            }
            startCountdown()
        }
    }

    /// 验证重置密码验证码
    private func verifyResetOTP() async {
        guard resetOTP.count == 6 else {
            showToastMessage("请输入6位验证码")
            return
        }

        await authManager.verifyResetOTP(email: resetEmail, code: resetOTP)

        if authManager.otpVerified {
            withAnimation {
                resetStep = 3
            }
        }
    }

    /// 执行重置密码
    private func performResetPassword() async {
        guard !resetPassword.isEmpty else {
            showToastMessage("请输入新密码")
            return
        }

        guard resetPassword.count >= 6 else {
            showToastMessage("密码长度至少6位")
            return
        }

        guard resetPassword == resetConfirmPassword else {
            showToastMessage("两次输入的密码不一致")
            return
        }

        await authManager.resetPassword(newPassword: resetPassword)

        if authManager.isAuthenticated {
            showForgotPassword = false
            showToastMessage("密码重置成功")
        }
    }

    // MARK: - Helper Methods

    /// 显示Toast消息
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showToast = false
            }
        }
    }

    /// 开始倒计时
    private func startCountdown() {
        otpCountdown = 60
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if otpCountdown > 0 {
                otpCountdown -= 1
            } else {
                timer.invalidate()
            }
        }
    }

    /// 验证邮箱格式
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Custom TextField

/// 自定义文本输入框
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Custom Secure Field

/// 自定义密码输入框
struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    @State private var isSecure = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Primary Button

/// 主按钮
struct PrimaryButton: View {
    let title: LocalizedStringKey
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [ApocalypseTheme.primary, ApocalypseTheme.primaryDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: ApocalypseTheme.primary.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isLoading)
    }
}

// MARK: - Third Party Button

/// 第三方登录按钮
struct ThirdPartyButton: View {
    let icon: String
    let title: LocalizedStringKey
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ApocalypseTheme.textMuted.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
