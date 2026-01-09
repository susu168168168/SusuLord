//
//  EarthLordApp.swift
//  EarthLord
//
//  Created by suyinghui on 2025/12/31.
//

import SwiftUI
import GoogleSignIn

@main
struct EarthLordApp: App {
    /// 连接 AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// 认证管理器（全局单例）
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    // 处理 Google Sign-In 的 URL 回调
                    print("🔵 收到 URL 回调: \(url)")
                    let handled = GIDSignIn.sharedInstance.handle(url)
                    if handled {
                        print("✅ Google Sign-In 已处理 URL 回调")
                    } else {
                        print("⚠️ URL 未被 Google Sign-In 处理")
                    }
                }
        }
    }
}
