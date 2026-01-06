//
//  MoreTabView.swift
//  EarthLord
//
//  Created by suyinghui on 2025/12/31.
//

import SwiftUI

struct MoreTabView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                ApocalypseTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 开发者工具区域
                        sectionHeader("开发者工具")

                        // Supabase 测试入口
                        NavigationLink(destination: SupabaseTestView()) {
                            menuRow(
                                icon: "server.rack",
                                title: "Supabase 连接测试",
                                subtitle: "检测后端服务连接状态"
                            )
                        }

                        // 快速认证测试（推荐）
                        NavigationLink(destination: QuickAuthTestView()) {
                            menuRow(
                                icon: "checkmark.shield.fill",
                                title: "快速认证测试 ⭐️",
                                subtitle: "一键创建测试账号并登录"
                            )
                        }

                        // 认证调试入口
                        NavigationLink(destination: AuthDebugView()) {
                            menuRow(
                                icon: "person.badge.key.fill",
                                title: "认证功能调试",
                                subtitle: "详细测试登录、注册、找回密码"
                            )
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("更多")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - 分区标题

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ApocalypseTheme.textSecondary)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - 菜单行

    private func menuRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ApocalypseTheme.primary.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(ApocalypseTheme.primary)
            }

            // 文字
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Spacer()

            // 箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    MoreTabView()
}
