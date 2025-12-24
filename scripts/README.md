# zyc-scripts 工具脚本

## ReaPack Index 生成

本项目使用官方的 **`reapack-index`** 工具自动生成 ReaPack 索引文件。

### 自动生成（推荐）

GitHub Actions 工作流会自动生成和更新 `index.xml`：

- **触发条件**：推送 `main` 分支且更改涉及 `Release/REAPER/**`
- **工作流文件**：`.github/workflows/reapack-index.yml`
- **查看状态**：https://github.com/YichengZ/zyc-scripts/actions

### 本地生成

如果需要本地生成索引：

```bash
# 1. 安装 reapack-index
gem install reapack-index --user-install

# 2. 设置 PATH（临时）
export PATH="$HOME/.gem/ruby/$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')/bin:$PATH"

# 3. 生成索引
cd Release
reapack-index --rebuild
```

### 永久添加到 PATH

编辑 `~/.zshrc` 或 `~/.bash_profile`：

```bash
export PATH="$HOME/.gem/ruby/$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')/bin:$PATH"
```

然后重新加载：

```bash
source ~/.zshrc
```

## 官方工具优势

- ✅ 自动识别所有文件（Lua、PNG、JSON 等）
- ✅ 基于 Git 提交历史自动生成版本
- ✅ 支持多文件脚本和资源文件
- ✅ 自动提取元数据
- ✅ 官方维护，功能完善

## 参考资源

- **reapack-index GitHub**: https://github.com/cfillion/reapack-index
- **ReaPack 文档**: https://github.com/cfillion/reapack-index/wiki
