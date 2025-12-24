# GitHub Actions 工作流故障排查

## 如果工作流没有显示

### 1. 检查工作流文件位置

确保文件在正确的位置：
```
.github/workflows/reapack-index.yml
```

### 2. 检查文件是否已推送

```bash
git log --name-only --oneline -1 | grep "reapack-index.yml"
```

### 3. 检查 GitHub 仓库设置

1. 访问：https://github.com/YichengZ/zyc-scripts/settings/actions
2. 确保 "Allow all actions and reusable workflows" 已启用
3. 检查 "Workflow permissions" 设置为 "Read and write permissions"

### 4. 手动触发工作流

1. 访问：https://github.com/YichengZ/zyc-scripts/actions
2. 点击左侧 "ReaPack Indexer"
3. 点击 "Run workflow" 按钮
4. 选择 `main` 分支
5. 点击 "Run workflow"

### 5. 检查工作流日志

如果工作流运行了但失败：
1. 点击失败的工作流运行
2. 查看错误日志
3. 常见问题：
   - Ruby 版本问题
   - reapack-index 安装失败
   - Git 权限问题

## 常见问题

### 问题 1：工作流没有触发

**原因**：
- 触发条件不匹配
- 工作流文件路径错误
- GitHub Actions 未启用

**解决**：
- 检查 `.github/workflows/` 目录
- 手动触发工作流测试

### 问题 2：工作流运行但失败

**常见错误**：
- `reapack-index: command not found` - 安装失败
- `Permission denied` - Git 推送权限问题
- `No such file or directory` - 路径问题

**解决**：
- 检查工作流日志
- 验证 Ruby 和 gem 安装
- 检查 Git 权限设置

### 问题 3：index.xml 没有更新

**原因**：
- 工作流没有检测到变化
- 提交失败
- 推送权限问题

**解决**：
- 检查 "Check for changes" 步骤的输出
- 验证 Git 配置
- 检查仓库权限

## 验证步骤

### 1. 检查工作流文件

```bash
cd /Users/zhuyicheng/Documents/GitHub/zyc_scripts
ls -la .github/workflows/
cat .github/workflows/reapack-index.yml
```

### 2. 检查是否已推送

```bash
git log origin/main --name-only | grep "reapack-index.yml"
```

### 3. 手动测试触发

在 GitHub 上手动触发工作流，查看是否能正常运行。

## 备用方案

如果 GitHub Actions 无法使用，可以手动生成：

```bash
cd /Users/zhuyicheng/Documents/GitHub/zyc_scripts
ruby scripts/generate_index.rb > Release/index.xml
git add Release/index.xml
git commit -m "Update ReaPack index manually"
git push origin main
```

