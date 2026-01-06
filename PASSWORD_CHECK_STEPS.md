# 密码问题检查步骤

## 问题：注册后退出再登录失败

用户信息：
- 邮箱: suyinghui360@gmail.com
- 尝试登录密码: abc123@456
- 错误: "邮箱或密码错误"

## 请按以下步骤操作并截图：

### 步骤 1: 使用快速测试工具

1. 打开 App
2. 进入"更多"Tab
3. 点击"快速认证测试 ⭐️"
4. 输入：
   - 测试邮箱: suyinghui360@gmail.com
   - 测试密码: abc123@456
5. 点击"方案2：手动创建后测试登录"
6. **截图整个页面**（特别是日志部分）

### 步骤 2: 检查 Supabase 用户状态

1. 访问 https://app.supabase.com
2. 选择项目: kgggszofjfabtuwywsxl
3. 进入 Authentication → Users
4. 找到用户: suyinghui360@gmail.com
5. **截图用户列表**（显示该用户的状态）

### 步骤 3: 查看用户详情

1. 点击该用户邮箱进入详情
2. 检查：
   - Email Confirmed: 应该是 ✅
   - User Status: 应该是 Active
3. **截图用户详情页面**

## 快速修复方案

如果等不及排查，直接在 Supabase 控制台：

1. 进入用户编辑页面
2. 在 "Change user's password" 输入: abc123@456
3. 确保 "Email Confirmed" 已勾选
4. 点击 Save
5. 返回 App 登录

## 可能的原因

1. ✅ 注册时设置的密码和现在输入的不一致
2. ✅ 邮箱未验证
3. ✅ Supabase 密码存储问题
4. ✅ 用户状态异常

## 需要提供的信息

请截图并发送：
1. 快速测试工具的日志输出
2. Supabase 用户列表
3. 该用户的详情页面
