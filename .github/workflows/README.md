# GitHub Actions 工作流

## reapack-index.yml

自动生成和更新 ReaPack 索引文件。

### 触发条件

1. **自动触发**：
   - 当 `main` 或 `master` 分支有推送时
   - 且更改涉及 `Release/REAPER/**` 路径

2. **手动触发**：
   - 在 GitHub Actions 页面可以手动运行

### 工作流程

1. 检出仓库（包含完整 Git 历史）
2. 安装 Ruby 3.0
3. 安装 `reapack-index` gem
4. 在 `Release/` 目录运行 `reapack-index --rebuild`
5. 检查 `index.xml` 是否有变化
6. 如果有变化，自动提交并推送

### 输出

- 更新的 `Release/index.xml` 文件
- 自动提交信息：`Auto-update ReaPack index [skip ci]`

### 注意事项

- 工作流使用 `[skip ci]` 标记，避免循环触发
- 需要完整的 Git 历史记录（`fetch-depth: 0`）
- 自动提交需要仓库的写权限

