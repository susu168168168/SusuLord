//
//  AppDelegate.swift
//  EarthLord
//
//  Created by Claude on 2026/01/08.
//

import UIKit
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {

    /// 应用启动时调用
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("🔵 应用启动完成")
        return true
    }

    /// 处理 URL 回调（用于 Google 登录）
    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("🔵 收到 URL 回调: \(url)")

        // 将 URL 传递给 Google Sign-In 处理
        let handled = GIDSignIn.sharedInstance.handle(url)

        if handled {
            print("✅ Google Sign-In 已处理 URL 回调")
        } else {
            print("⚠️ URL 未被 Google Sign-In 处理")
        }

        return handled
    }
}
