//
//  RootView.swift
//  EarthLord
//
//  Created by suyinghui on 2025/12/31.
//

import SwiftUI

/// 根视图：控制启动页、认证页与主界面的切换
struct RootView: View {
    /// 认证管理器
    @EnvironmentObject var authManager: AuthManager

    /// 语言管理器
    @ObservedObject private var languageManager = LanguageManager.shared

    /// 启动页是否完成
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if !splashFinished {
                // 启动页
                SplashView(isFinished: $splashFinished)
                    .transition(.opacity)
            } else if authManager.isAuthenticated {
                // 已认证：显示主界面
                ContentView()
                    .transition(.opacity)
            } else {
                // 未认证：显示登录/注册页面
                AuthView()
                    .transition(.opacity)
            }
        }
        .environment(\.locale, languageManager.currentLocale)
        .id(languageManager.languageChangeId)
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager())
}
