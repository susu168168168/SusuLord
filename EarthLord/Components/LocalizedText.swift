//
//  LocalizedText.swift
//  EarthLord
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI

/// 支持动态语言切换的 Text 组件
struct LocalizedText: View {
    let key: String
    @ObservedObject private var languageManager = LanguageManager.shared

    init(_ key: String) {
        self.key = key
    }

    var body: some View {
        Text(localizedString)
            .id(languageManager.languageChangeId) // 语言变化时强制刷新
    }

    private var localizedString: String {
        let bundle = Bundle.customLanguageBundle ?? Bundle.main
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
