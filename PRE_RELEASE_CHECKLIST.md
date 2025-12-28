# 上线前检查清单

> 最后更新：2025-12-28

## ✅ 代码质量检查

### 1. 版权和许可证
- [x] 已创建 LICENSE 文件（MIT License）
- [x] 已移除所有明确的第三方引用（nvk, Sexan等）
- [x] 已保留 json.lua 的 MIT 许可证声明
- [x] 所有文件作者信息正确（Yicheng Zhu (Ethan)）
- [x] README 中已更新许可证信息

### 2. 代码注释
- [x] 已移除所有"借鉴"、"参考"等可能引起版权问题的注释
- [x] 代码注释专业、清晰
- [x] 无 TODO/FIXME 等开发标记（已检查，均为正常注释）

### 3. 功能完整性
- [x] SWS 扩展检测已添加
- [x] 数据路径修复完成（跨平台兼容）
- [x] 自动启动功能正常
- [x] 所有 i18n 文件更新完成

## ✅ 文档检查

### 1. Markdown 文件
- [x] README.md - 格式正确，链接有效
- [x] Release/README.md - 格式正确，链接有效
- [x] Release/README_CN.md - 格式正确，链接有效
- [x] Release/REAPER/Scripts/ReaPet/README.md - 格式正确
- [x] Release/REAPER/Scripts/ReaPet/assets/README.md - 格式正确
- [x] docs/SCRIPT_INTEGRATION_PATTERNS.md - 已移除第三方引用
- [x] docs/REAPACK_DEPLOYMENT_OPTIONS.md - 格式正确
- [x] scripts/README.md - 格式正确
- [x] RELEASE_STATUS.md - 格式正确
- [x] RELEASE_VERIFICATION.md - 格式正确

### 2. 文档内容
- [x] 所有链接指向正确的文件/URL
- [x] 安装说明清晰完整
- [x] 功能描述准确
- [x] 版本信息正确

## ✅ 文件结构检查

### 1. 必需文件
- [x] LICENSE 文件存在
- [x] README.md 存在
- [x] index.xml 存在（由 GitHub Actions 自动生成）
- [x] 所有脚本文件包含 ReaPack metadata

### 2. 不应包含的文件
- [x] 用户数据文件已排除（.gitignore 已配置）
- [x] 开发文件在 Development/ 目录（不发布）
- [x] 临时文件已清理

## ✅ 版本和元数据

### 1. 版本号
- [x] zyc_ReaPet: v1.0.4.1
- [x] zyc_EnvFollower: v3.3
- [x] zyc_LFO: v1.0
- [x] Startup Actions: v2.2.0
- [x] 所有 i18n 文件版本号已更新

### 2. ReaPack Metadata
- [x] 所有脚本包含 @description
- [x] 所有脚本包含 @version
- [x] 所有脚本包含 @author
- [x] 所有脚本包含 @about
- [x] 所有脚本包含 @changelog
- [x] 所有脚本包含 @provides（如适用）

## ✅ 功能测试清单

### 1. 基础功能
- [ ] 在 Windows 上测试安装和运行
- [ ] 在 macOS 上测试安装和运行
- [ ] 在 Linux 上测试安装和运行（如适用）
- [ ] 测试数据文件路径（ResourcePath/Data/）
- [ ] 测试数据迁移功能

### 2. ReaPet 功能
- [ ] 统计功能正常
- [ ] 番茄钟功能正常
- [ ] 宝箱系统正常
- [ ] 商店系统正常
- [ ] 皮肤切换正常
- [ ] 设置保存正常
- [ ] 自动启动功能正常

### 3. Startup Actions 功能
- [ ] 打开 Startup Actions 正常
- [ ] 添加动作正常
- [ ] 保存配置正常
- [ ] 自动注册到 SWS 正常

### 4. 效果插件
- [ ] zyc_EnvFollower 加载正常
- [ ] zyc_LFO 加载正常
- [ ] 参数调制功能正常

## ✅ 依赖检查

### 1. 必需扩展
- [x] ReaImGui - 已检测并提示
- [x] js_ReaScriptAPI - 已检测并提示
- [x] SWS Extension - 已检测并提示

### 2. 可选依赖
- [x] ReaPack - 用于安装（文档中已说明）

## ✅ GitHub 仓库检查

### 1. 仓库设置
- [ ] 仓库描述已设置
- [ ] 仓库主题标签已设置
- [ ] 仓库可见性正确（Public）
- [ ] 默认分支设置为 main

### 2. GitHub Actions
- [ ] .github/workflows/reapack-index.yml 存在
- [ ] 工作流配置正确
- [ ] 测试工作流运行成功

### 3. 分支管理
- [ ] main 分支为发布分支
- [ ] dev 分支为开发分支
- [ ] 分支保护规则已设置（如需要）

## ✅ ReaPack 集成

### 1. index.xml
- [ ] GitHub Actions 自动生成成功
- [ ] 所有脚本都包含在索引中
- [ ] 版本号正确
- [ ] 下载链接正确

### 2. 安装测试
- [ ] 通过 ReaPack 安装成功
- [ ] 所有文件正确安装
- [ ] 脚本可以正常运行

## ✅ 用户体验

### 1. 错误提示
- [x] SWS 未安装时显示友好提示
- [x] ReaImGui 未安装时显示友好提示
- [x] js_ReaScriptAPI 未安装时显示友好提示
- [x] 脚本未找到时显示友好提示

### 2. 多语言支持
- [x] 英文翻译完整
- [x] 中文翻译完整
- [x] 其他语言回退到英文

### 3. 文档完整性
- [x] 安装说明清晰
- [x] 使用说明完整
- [x] 故障排除信息（如适用）

## 🚀 发布前最后步骤

### 1. 代码提交
- [ ] 所有更改已提交到 dev 分支
- [ ] 代码已 review
- [ ] 合并到 main 分支
- [ ] **Developer Mode UI 已隐藏（生产版本必须隐藏）**

### 2. 版本标记
- [ ] 创建 Git tag（如 v1.0.4.1）
- [ ] 标签描述包含更新内容

### 3. 发布准备
- [ ] 更新 CHANGELOG（如适用）
- [ ] 准备发布说明
- [ ] 通知用户（如适用）

## 📝 注意事项

1. **数据路径**：用户数据现在保存在 `ResourcePath/Data/`，更新不会丢失数据
2. **SWS 检测**：首次运行会检测 SWS，未安装会提示
3. **自动启动**：描述已更新为"自动启动管理器"，更直观
4. **跨平台**：所有路径处理已优化，支持 Windows/macOS/Linux

## ✅ 检查完成

完成所有检查项后，可以安全发布！

