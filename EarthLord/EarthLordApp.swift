//
//  EarthLordApp.swift
//  EarthLord
//
//  Created by suyinghui on 2025/12/31.
//

import SwiftUI

@main
struct EarthLordApp: App {
    /// 认证管理器（全局单例）
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}
