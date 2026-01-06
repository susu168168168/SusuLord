//
//  SupabaseTestView.swift
//  EarthLord
//
//  Created by suyinghui on 2025/12/31.
//

import SwiftUI
import Supabase

// MARK: - Supabase Client 初始化

private let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://kgggszofjfabtuwywsxl.supabase.co")!,
    supabaseKey: "sb_publishable_G-7193PIKZh1oSwpWSuzmQ_6Y5IWh7h"
)

// MARK: - Supabase 测试视图

struct SupabaseTestView: View {
    /// 连接状态：nil=未测试, true=成功, false=失败
    @State private var connectionStatus: Bool? = nil

    /// 调试日志
    @State private var debugLog: String = "点击按钮开始测试连接..."

    /// 是否正在测试中
    @State private var isTesting: Bool = false

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 标题
                Text("Supabase 连接测试")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                // 状态图标
                statusIcon
                    .padding(.vertical, 20)

                // 调试日志区域
                debugLogView

                Spacer()

                // 测试按钮
                testButton
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .navigationTitle("Supabase 测试")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 状态图标

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusBackgroundColor.opacity(0.2))
                .frame(width: 120, height: 120)

            Circle()
                .fill(statusBackgroundColor.opacity(0.3))
                .frame(width: 90, height: 90)

            if isTesting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                    .scaleEffect(2)
            } else {
                Image(systemName: statusIconName)
                    .font(.system(size: 50))
                    .foregroundColor(statusIconColor)
            }
        }
    }

    private var statusIconName: String {
        switch connectionStatus {
        case .some(true):
            return "checkmark.circle.fill"
        case .some(false):
            return "exclamationmark.triangle.fill"
        case .none:
            return "questionmark.circle"
        }
    }

    private var statusIconColor: Color {
        switch connectionStatus {
        case .some(true):
            return ApocalypseTheme.success
        case .some(false):
            return ApocalypseTheme.danger
        case .none:
            return ApocalypseTheme.textSecondary
        }
    }

    private var statusBackgroundColor: Color {
        switch connectionStatus {
        case .some(true):
            return ApocalypseTheme.success
        case .some(false):
            return ApocalypseTheme.danger
        case .none:
            return ApocalypseTheme.textSecondary
        }
    }

    // MARK: - 调试日志视图

    private var debugLogView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("调试日志")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textSecondary)

            ScrollView {
                Text(debugLog)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 200)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - 测试按钮

    private var testButton: some View {
        Button(action: testConnection) {
            HStack {
                if isTesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                }
                Text(isTesting ? "测试中..." : "测试连接")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isTesting ? ApocalypseTheme.textSecondary : ApocalypseTheme.primary)
            .cornerRadius(12)
        }
        .disabled(isTesting)
    }

    // MARK: - 测试连接逻辑

    private func testConnection() {
        isTesting = true
        connectionStatus = nil
        debugLog = "[\(timestamp)] 开始测试连接...\n"
        debugLog += "[\(timestamp)] URL: https://kgggszofjfabtuwywsxl.supabase.co\n"
        debugLog += "[\(timestamp)] 尝试查询不存在的表 'non_existent_table'...\n"

        Task {
            do {
                // 故意查询一个不存在的表来测试连接
                let _: [EmptyResponse] = try await supabase
                    .from("non_existent_table")
                    .select()
                    .execute()
                    .value

                // 如果没有抛出错误（理论上不应该发生）
                await MainActor.run {
                    debugLog += "[\(timestamp)] 查询成功（意外情况）\n"
                    connectionStatus = true
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                    isTesting = false
                }
            }
        }
    }

    // MARK: - 错误处理

    private func handleError(_ error: Error) {
        let errorString = String(describing: error)
        let errorLocalizedDescription = error.localizedDescription

        debugLog += "[\(timestamp)] 收到响应，分析错误类型...\n"
        debugLog += "[\(timestamp)] 错误信息: \(errorLocalizedDescription)\n"

        // 检查是否是 PostgreSQL REST API 错误（说明连接成功，只是表不存在）
        if errorString.contains("PGRST") ||
           errorString.contains("Could not find") ||
           errorString.contains("relation") && errorString.contains("does not exist") ||
           errorLocalizedDescription.contains("PGRST") ||
           errorLocalizedDescription.contains("Could not find") {

            debugLog += "[\(timestamp)] 检测到 PostgreSQL REST API 错误\n"
            debugLog += "[\(timestamp)] ✅ 连接成功（服务器已响应）\n"
            debugLog += "[\(timestamp)] 说明: 表不存在是预期行为，证明服务器可达\n"
            connectionStatus = true

        } else if errorString.contains("hostname") ||
                  errorString.contains("URL") ||
                  errorString.contains("NSURLErrorDomain") ||
                  errorString.contains("Could not connect") ||
                  errorString.contains("network") ||
                  errorLocalizedDescription.contains("网络") ||
                  errorLocalizedDescription.contains("连接") {

            debugLog += "[\(timestamp)] ❌ 连接失败：URL 错误或无网络\n"
            debugLog += "[\(timestamp)] 详细错误: \(errorString)\n"
            connectionStatus = false

        } else {
            // 其他错误 - 可能是认证问题等，但说明网络是通的
            debugLog += "[\(timestamp)] 收到其他类型错误\n"
            debugLog += "[\(timestamp)] 详细错误: \(errorString)\n"

            // 如果能收到服务器响应，即使是错误也算连接成功
            if errorString.contains("401") || errorString.contains("403") ||
               errorString.contains("Invalid") || errorString.contains("Unauthorized") {
                debugLog += "[\(timestamp)] ✅ 连接成功（服务器已响应，可能是认证问题）\n"
                connectionStatus = true
            } else {
                debugLog += "[\(timestamp)] ⚠️ 未知错误类型\n"
                connectionStatus = false
            }
        }
    }

    // MARK: - 辅助方法

    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - 空响应模型

private struct EmptyResponse: Decodable {}

// MARK: - Preview

#Preview {
    NavigationStack {
        SupabaseTestView()
    }
}
