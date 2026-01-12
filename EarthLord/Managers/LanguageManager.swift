//
//  LanguageManager.swift
//  EarthLord
//
//  Created by Claude on 2026-01-10.
//

import Foundation
import SwiftUI
import Combine
import ObjectiveC

/// 语言选项枚举
enum AppLanguage: String, Codable, CaseIterable {
    case system = "system"      // 跟随系统
    case chinese = "zh-Hans"    // 简体中文
    case english = "en"         // English

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .chinese: return "简体中文"
        case .english: return "English"
        }
    }

    /// 获取实际使用的语言代码
    var localeIdentifier: String? {
        switch self {
        case .system: return nil  // nil表示使用系统语言
        case .chinese: return "zh-Hans"
        case .english: return "en"
        }
    }
}

// MARK: - Bundle Swizzling for Language Override

private var bundleKey: UInt8 = 0

extension Bundle {
    @objc func customLocalizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        // 如果设置了自定义语言 Bundle，使用它
        if let bundle = Bundle.customLanguageBundle {
            let result = bundle.customLocalizedString(forKey: key, value: value, table: tableName)
            // 调试日志（只打印前几个关键字符串）
            if key == "地图" || key == "登录" || key == "个人" {
                print("🔄 [Bundle] 翻译 '\(key)' -> '\(result)' (使用自定义Bundle)")
            }
            return result
        }
        // 否则使用原始方法（通过 swizzling，这里调用原始的实现）
        let result = self.customLocalizedString(forKey: key, value: value, table: tableName)
        if key == "地图" || key == "登录" || key == "个人" {
            print("🔄 [Bundle] 翻译 '\(key)' -> '\(result)' (使用默认Bundle)")
        }
        return result
    }

    static var customLanguageBundle: Bundle? {
        get {
            return objc_getAssociatedObject(self, &bundleKey) as? Bundle
        }
        set {
            objc_setAssociatedObject(self, &bundleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    static func swizzleLanguageBundle() {
        let originalMethod = class_getInstanceMethod(Bundle.self, #selector(localizedString(forKey:value:table:)))!
        let swizzledMethod = class_getInstanceMethod(Bundle.self, #selector(customLocalizedString(forKey:value:table:)))!
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

/// 语言管理器
/// 管理应用内语言切换，支持跟随系统、简体中文、English
@MainActor
class LanguageManager: ObservableObject {

    // MARK: - Singleton
    static let shared = LanguageManager()

    // MARK: - Published Properties

    /// 当前选择的语言
    @Published var currentLanguage: AppLanguage {
        didSet {
            saveLanguagePreference()
            applyLanguage()
        }
    }

    /// 语言变更触发器（用于强制刷新视图）
    @Published private(set) var languageChangeId = UUID()

    /// 当前的 Locale（用于 SwiftUI 环境）
    @Published private(set) var currentLocale: Locale = .current

    // MARK: - Private Properties

    /// UserDefaults存储Key
    private let languageKey = "app_language_preference"

    /// 是否已经执行过 swizzling
    private static var hasSwizzled = false

    // MARK: - Initialization

    private init() {
        // 执行 method swizzling（只执行一次）
        if !LanguageManager.hasSwizzled {
            print("🔧 [LanguageManager] 执行 Method Swizzling...")
            Bundle.swizzleLanguageBundle()
            LanguageManager.hasSwizzled = true
            print("✅ [LanguageManager] Method Swizzling 完成")
        }

        // 从UserDefaults读取保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // 默认跟随系统
            self.currentLanguage = .system
        }

        // 应用语言设置（首次启动时）
        applyLanguage()

        // 监听系统语言变化（仅在"跟随系统"模式下生效）
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if self?.currentLanguage == .system {
                    self?.applyLanguage()
                }
            }
        }
    }

    // MARK: - Public Methods

    /// 切换语言
    func changeLanguage(to language: AppLanguage) {
        currentLanguage = language
    }

    /// 获取本地化字符串（用于字符串插值）
    /// - Parameters:
    ///   - key: 字符串Key（中文原文）
    ///   - args: 格式化参数
    /// - Returns: 本地化后的字符串
    func localizedString(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return withVaList(args) { pointer in
            NSString(format: format, arguments: pointer) as String
        }
    }

    // MARK: - Private Methods

    /// 保存语言偏好到UserDefaults
    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
        UserDefaults.standard.synchronize()
    }

    /// 应用语言设置
    private func applyLanguage() {
        // 根据选择的语言设置 Bundle
        if let localeIdentifier = currentLanguage.localeIdentifier {
            // 设置特定语言
            setLanguageBundle(localeIdentifier)
            // 设置 SwiftUI 环境的 Locale
            currentLocale = Locale(identifier: localeIdentifier)
        } else {
            // 跟随系统语言
            Bundle.customLanguageBundle = nil
            currentLocale = .current
            print("✅ 已切换到跟随系统语言")
        }

        // 触发视图刷新
        languageChangeId = UUID()
    }

    /// 设置语言Bundle
    private func setLanguageBundle(_ languageCode: String) {
        print("🌐 [LanguageManager] setLanguageBundle 被调用，语言代码: \(languageCode)")

        // 对于英文，使用 en.lproj
        // 对于中文（源语言），使用 Bundle.main
        if languageCode == "en" {
            let path = Bundle.main.path(forResource: "en", ofType: "lproj")
            print("🔍 [LanguageManager] 查找 en.lproj 路径: \(path ?? "未找到")")

            if let path = path, let bundle = Bundle(path: path) {
                Bundle.customLanguageBundle = bundle
                print("✅ [LanguageManager] 已切换到英文 Bundle")
                print("📦 [LanguageManager] Bundle.customLanguageBundle = \(String(describing: Bundle.customLanguageBundle))")

                // 测试翻译
                let testKey = "地图"
                let testResult = NSLocalizedString(testKey, comment: "")
                print("🧪 [LanguageManager] 测试翻译 '\(testKey)' -> '\(testResult)'")
            } else {
                print("⚠️ [LanguageManager] 无法加载语言包: \(languageCode)，使用系统默认")
                Bundle.customLanguageBundle = nil
            }
        } else if languageCode == "zh-Hans" {
            // 中文是源语言，使用 nil 表示使用 Bundle.main
            Bundle.customLanguageBundle = nil
            print("✅ [LanguageManager] 已切换到中文（源语言），使用 Bundle.main")
        } else {
            Bundle.customLanguageBundle = nil
            print("⚠️ [LanguageManager] 不支持的语言: \(languageCode)，使用系统默认")
        }
    }
}
