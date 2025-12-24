# 安装和使用官方 reapack-index 工具

## 方法 1：使用 gem 安装（推荐）

### 步骤 1：安装 Ruby（如果未安装）

**macOS（使用 Homebrew）**：
```bash
brew install ruby
```

**验证安装**：
```bash
ruby --version
```

### 步骤 2：安装 reapack-index

**系统级安装（需要管理员权限）**：
```bash
sudo gem install reapack-index
```

**用户级安装（推荐，无需 sudo）**：
```bash
gem install reapack-index --user-install
```

安装后，将 gem 的 bin 目录添加到 PATH：
```bash
export PATH="$HOME/.gem/ruby/$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')/bin:$PATH"
```

**永久添加到 PATH**（添加到 `~/.zshrc` 或 `~/.bash_profile`）：
```bash
echo 'export PATH="$HOME/.gem/ruby/$(ruby -e "puts RUBY_VERSION[/\d+\.\d+/]")/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 步骤 3：验证安装

```bash
reapack-index --version
```

## 方法 2：使用 Homebrew 安装 Ruby + gem

```bash
# 安装 Homebrew Ruby（如果系统 Ruby 版本太旧）
brew install ruby

# 使用 Homebrew 的 Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# 安装 reapack-index
gem install reapack-index
```

## 使用 reapack-index

### 基本用法

```bash
cd /Users/zhuyicheng/Documents/GitHub/zyc_scripts
reapack-index
```

### 常用选项

```bash
# 重新构建整个索引
reapack-index --rebuild

# 扫描新提交
reapack-index --scan

# 检查索引（不生成）
reapack-index --check

# 指定目录
reapack-index Release/
```

### 配置选项

reapack-index 会读取 Git 仓库信息，自动生成索引。

**重要配置**：
- 确保在 Git 仓库根目录运行
- 索引文件会生成在运行目录
- 默认扫描所有提交

## 对比：官方工具 vs 自定义脚本

### 官方 reapack-index

**优点**：
- ✅ 官方维护，功能完整
- ✅ 自动版本管理
- ✅ 支持 Git 提交历史
- ✅ 自动检测文件变化

**缺点**：
- ❌ 需要安装 Ruby gem
- ❌ 可能需要管理员权限

### 自定义脚本（generate_index.rb）

**优点**：
- ✅ 无需额外安装
- ✅ 简单直接
- ✅ 专门为 zyc-scripts 定制

**缺点**：
- ❌ 需要手动更新版本号
- ❌ 不自动检测 Git 提交

## 推荐方案

1. **开发阶段**：使用自定义脚本（快速迭代）
2. **发布阶段**：使用官方工具（更规范）

## 故障排除

### 问题 1：`gem: command not found`

**解决**：安装 Ruby
```bash
brew install ruby
```

### 问题 2：`Permission denied`

**解决**：使用用户级安装
```bash
gem install reapack-index --user-install
```

### 问题 3：`reapack-index: command not found`

**解决**：添加 gem bin 目录到 PATH
```bash
export PATH="$HOME/.gem/ruby/$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')/bin:$PATH"
```

## 参考资源

- **reapack-index GitHub**: https://github.com/cfillion/reapack-index
- **ReaPack 文档**: https://github.com/cfillion/reapack-index/wiki

