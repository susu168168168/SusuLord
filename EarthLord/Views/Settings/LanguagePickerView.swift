//
//  LanguagePickerView.swift
//  EarthLord
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI

/// 语言选择页面
struct LanguagePickerView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部导航栏
                navigationBar

                // 语言选项列表
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            LanguageOptionRow(
                                language: language,
                                isSelected: languageManager.currentLanguage == language
                            ) {
                                print("🎯 [UI] 用户点击了: \(language.displayName)")
                                languageManager.changeLanguage(to: language)
                                print("🎯 [UI] 当前语言已设置为: \(languageManager.currentLanguage.rawValue)")
                                // 延迟关闭，让用户看到选中效果
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }

                            if language != AppLanguage.allCases.last {
                                Divider()
                                    .background(ApocalypseTheme.textMuted.opacity(0.2))
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(ApocalypseTheme.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(ApocalypseTheme.textPrimary)
            }

            Spacer()

            Text("语言设置")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)

            Spacer()

            // 占位，保持标题居中
            Color.clear
                .frame(width: 44)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(ApocalypseTheme.cardBackground)
    }
}

// MARK: - Language Option Row

/// 语言选项行
struct LanguageOptionRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 语言名称
                Text(language.displayName)
                    .font(.body)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    LanguagePickerView()
}
