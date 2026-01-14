//
//  TerritoryLogger.swift
//  EarthLord
//
//  圈地功能日志管理器 - 记录圈地模块的调试日志
//

import Foundation
import Combine

/// 日志类型枚举
enum LogType: String {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"
}

/// 日志条目结构
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: LogType
}

/// 圈地功能日志管理器
/// 单例模式 + ObservableObject，支持 SwiftUI 数据绑定
final class TerritoryLogger: ObservableObject {

    // MARK: - 单例

    /// 全局共享实例
    static let shared = TerritoryLogger()

    // MARK: - Published Properties

    /// 日志数组
    @Published var logs: [LogEntry] = []

    /// 格式化的日志文本（用于显示）
    @Published var logText: String = ""

    // MARK: - Private Properties

    /// 最大日志条数（防止内存溢出）
    private let maxLogCount = 200

    /// 时间格式化器（显示用）
    private let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// 时间格式化器（导出用）
    private let exportFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    // MARK: - Initialization

    private init() {
        // 私有初始化，确保单例
    }

    // MARK: - Public Methods

    /// 添加日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - type: 日志类型（默认为 info）
    func log(_ message: String, type: LogType = .info) {
        // 确保在主线程更新
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 创建日志条目
            let entry = LogEntry(
                timestamp: Date(),
                message: message,
                type: type
            )

            // 添加到数组
            self.logs.append(entry)

            // 如果超过最大条数，移除最旧的日志
            if self.logs.count > self.maxLogCount {
                self.logs.removeFirst(self.logs.count - self.maxLogCount)
            }

            // 更新格式化文本
            self.updateLogText()
        }
    }

    /// 清空所有日志
    func clear() {
        DispatchQueue.main.async { [weak self] in
            self?.logs.removeAll()
            self?.logText = ""
        }
    }

    /// 导出日志为文本
    /// - Returns: 包含头信息的完整日志文本
    func export() -> String {
        var result = """
        === 圈地功能测试日志 ===
        导出时间: \(exportFormatter.string(from: Date()))
        日志条数: \(logs.count)

        """

        for entry in logs {
            let timestamp = exportFormatter.string(from: entry.timestamp)
            let typeStr = "[\(entry.type.rawValue)]".padding(toLength: 10, withPad: " ", startingAt: 0)
            result += "[\(timestamp)] \(typeStr) \(entry.message)\n"
        }

        return result
    }

    // MARK: - Private Methods

    /// 更新格式化的日志文本
    private func updateLogText() {
        var text = ""

        for entry in logs {
            let timestamp = displayFormatter.string(from: entry.timestamp)
            let typeStr = "[\(entry.type.rawValue)]".padding(toLength: 10, withPad: " ", startingAt: 0)
            text += "[\(timestamp)] \(typeStr) \(entry.message)\n"
        }

        logText = text
    }
}
