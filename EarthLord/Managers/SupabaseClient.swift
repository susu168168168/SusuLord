//
//  SupabaseClient.swift
//  EarthLord
//
//  Created by Claude on 2026/01/05.
//

import Foundation
import Supabase

/// Supabase 客户端单例
/// 提供全局访问的 Supabase 客户端实例
enum SupabaseClientManager {
    /// 共享的 Supabase 客户端实例
    static let shared = SupabaseClient(
        supabaseURL: URL(string: "https://kgggszofjfabtuwywsxl.supabase.co")!,
        supabaseKey: "sb_publishable_G-7193PIKZh1oSwpWSuzmQ_6Y5IWh7h"
    )
}
