# Google 登录配置说明

## ✅ 已完成的代码实现

以下代码已经添加到项目中：

1. **AuthManager.swift** - Google 登录逻辑（带中文调试日志）
2. **AppDelegate.swift** - URL 回调处理
3. **EarthLordApp.swift** - URL scheme 处理
4. **AuthView.swift** - Google 登录按钮

## ⚠️ 需要手动配置的部分

### 在 Xcode 中添加 URL Scheme

**重要：** 必须手动在 Xcode 中添加 URL Scheme，否则 Google 登录无法正常工作。

#### 配置步骤：

1. **打开 Xcode 项目**
   - 打开 `EarthLord.xcodeproj`

2. **选择项目**
   - 在左侧导航栏中点击项目根节点 `EarthLord`
   - 选择 TARGETS 下的 `EarthLord`

3. **进入 Info 选项卡**
   - 点击顶部的 `Info` 选项卡

4. **添加 URL Types**
   - 在 `URL Types` 部分，点击 `+` 按钮
   - 填入以下信息：
     - **Identifier**: `com.googleusercontent.apps.115552931524-kq7og2961cc3bc7fs0m71ovcanerab1h`
     - **URL Schemes**: `115552931524-kq7og2961cc3bc7fs0m71ovcanerab1h.apps.googleusercontent.com`
     - **Role**: `Editor`

5. **保存并重新编译**
   - ⌘ + B 编译项目

## 📱 测试 Google 登录

配置完成后，运行 App：

1. 点击 "使用 Google 登录" 按钮
2. 会打开 Google 登录页面
3. 选择 Google 账号并授权
4. 自动返回 App 并完成登录

## 🔍 调试日志

登录过程中会输出以下中文日志：

- `🔵 开始 Google 登录流程...`
- `🔵 正在打开 Google 登录页面...`
- `✅ Google 登录成功，已获取 ID Token`
- `🔵 正在使用 ID Token 登录 Supabase...`
- `✅ Supabase 登录成功！`
- `✅ 用户 ID: xxx`
- `✅ 用户邮箱: xxx`

如果出错会显示：
- `❌ Google 登录失败: xxx`
- `❌ Supabase 登录失败: xxx`
- `ℹ️ 用户取消了 Google 登录`

## 🔧 技术细节

### Google Client ID
```
115552931524-kq7og2961cc3bc7fs0m71ovcanerab1h.apps.googleusercontent.com
```

### Supabase 配置
- Google Provider 已启用
- Authorized Client IDs 已填入
- Skip nonce check 已开启

## ❗常见问题

### 1. 点击按钮没有反应
- 检查是否已添加 URL Scheme
- 查看 Xcode 控制台日志

### 2. 登录后返回 App 但未成功
- 检查 Supabase 配置
- 查看控制台是否有错误日志

### 3. Google 页面打开后无法返回
- 确认 URL Scheme 配置正确
- 检查 AppDelegate 是否正确处理回调

## ✨ 完成！

配置完成后，用户就可以使用 Google 账号一键登录了！
