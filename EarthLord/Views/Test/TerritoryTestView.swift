//
//  TerritoryTestView.swift
//  EarthLord
//
//  圈地功能测试界面 - 显示圈地模块的调试日志
//

import SwiftUI

struct TerritoryTestView: View {

    // MARK: - Environment

    /// 定位管理器（通过环境对象获取，监听追踪状态）
    @EnvironmentObject var locationManager: LocationManager

    // MARK: - Observed Objects

    /// 日志管理器（监听日志更新）
    @ObservedObject var logger = TerritoryLogger.shared

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景色
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // 状态指示器
                statusIndicator

                // 日志区域
                logScrollView

                // 底部按钮
                buttonRow
            }
            .padding()
        }
        .navigationTitle("圈地测试")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 状态指示器

    private var statusIndicator: some View {
        HStack(spacing: 12) {
            // 状态圆点
            Circle()
                .fill(locationManager.isTracking ? Color.green : Color.gray)
                .frame(width: 12, height: 12)

            // 状态文字
            Text(locationManager.isTracking ? "追踪中" : "未追踪")
                .font(.headline)
                .foregroundColor(locationManager.isTracking ? Color.green : ApocalypseTheme.textSecondary)

            Spacer()

            // 路径点数（追踪中显示）
            if locationManager.isTracking {
                Text("\(locationManager.pathCoordinates.count) 个点")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            // 闭环状态
            if locationManager.isPathClosed {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已闭环")
                        .foregroundColor(.green)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 日志滚动区域

    private var logScrollView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack {
                Text("调试日志")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                Spacer()

                Text("\(logger.logs.count) 条")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }

            // 日志内容
            ScrollViewReader { proxy in
                ScrollView {
                    if logger.logText.isEmpty {
                        Text("暂无日志，开始圈地追踪后将显示日志...")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(ApocalypseTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    } else {
                        // 使用 Text 显示格式化的日志
                        logContent
                            .id("logBottom")
                    }
                }
                .onChange(of: logger.logText) { _, _ in
                    // 日志更新时自动滚动到底部
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("logBottom", anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - 日志内容（带颜色）

    private var logContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(logger.logs) { entry in
                logEntryView(entry)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func logEntryView(_ entry: LogEntry) -> some View {
        let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter
        }()

        let timestamp = timeFormatter.string(from: entry.timestamp)
        let color = colorForLogType(entry.type)

        return HStack(alignment: .top, spacing: 4) {
            Text("[\(timestamp)]")
                .foregroundColor(ApocalypseTheme.textMuted)

            Text("[\(entry.type.rawValue)]")
                .foregroundColor(color)

            Text(entry.message)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Spacer()
        }
        .font(.system(.caption, design: .monospaced))
    }

    private func colorForLogType(_ type: LogType) -> Color {
        switch type {
        case .info:
            return ApocalypseTheme.textSecondary
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

    // MARK: - 底部按钮

    private var buttonRow: some View {
        HStack(spacing: 16) {
            // 清空按钮
            Button(action: {
                logger.clear()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("清空日志")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ApocalypseTheme.textSecondary)
                .cornerRadius(12)
            }

            // 导出按钮
            ShareLink(item: logger.export()) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("导出日志")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ApocalypseTheme.primary)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TerritoryTestView()
            .environmentObject(LocationManager())
    }
}
