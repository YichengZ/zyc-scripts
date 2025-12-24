# 手动安装 reapack-index - 详细步骤

## 步骤 1：打开终端

确保你在终端中，可以运行命令。

## 步骤 2：检查 Ruby（应该已经有了）

```bash
ruby --version
```

应该显示类似：`ruby 2.6.10p210 ...`

如果没安装，先安装 Ruby：
```bash
brew install ruby
```

## 步骤 3：手动安装 reapack-index

**方法 A：用户级安装（推荐，无需 sudo）**

```bash
gem install reapack-index --user-install
```

**如果卡住或很慢**：
- 正常情况：首次安装可能需要 2-5 分钟（下载依赖）
- 如果超过 10 分钟：按 `Ctrl+C` 取消，尝试方法 B

**方法 B：使用国内镜像（如果网络慢）**

```bash
# 1. 添加国内镜像
gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/

# 2. 安装
gem install reapack-index --user-install
```

**方法 C：系统级安装（需要密码）**

```bash
sudo gem install reapack-index
```

## 步骤 4：找到安装位置

安装完成后，找到 reapack-index 的位置：

```bash
find ~/.gem -name "reapack-index" 2>/dev/null
```

或者：

```bash
gem env | grep "USER INSTALLATION"
```

会显示类似：`/Users/zhuyicheng/.gem/ruby/2.6.0`

那么 reapack-index 就在：`/Users/zhuyicheng/.gem/ruby/2.6.0/bin/reapack-index`

## 步骤 5：设置 PATH（临时测试）

```bash
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
```

## 步骤 6：验证安装

```bash
reapack-index --version
```

如果显示版本号，说明安装成功！

## 步骤 7：永久添加到 PATH

编辑 `~/.zshrc` 文件：

```bash
# 打开文件
nano ~/.zshrc

# 或者用其他编辑器
code ~/.zshrc  # VS Code
vim ~/.zshrc   # Vim
```

在文件末尾添加：

```bash
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
```

保存后，重新加载：

```bash
source ~/.zshrc
```

## 步骤 8：使用官方工具生成索引

```bash
cd /Users/zhuyicheng/Documents/GitHub/zyc_scripts

# 确保 PATH 已设置（如果还没永久添加）
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"

# 生成索引
reapack-index --rebuild Release/
```

## 如果安装还是失败

### 替代方案：使用自定义脚本

如果官方工具安装困难，可以使用已经准备好的自定义脚本：

```bash
cd /Users/zhuyicheng/Documents/GitHub/zyc_scripts
ruby scripts/generate_index.rb > Release/index.xml
```

这个脚本已经可以正常工作，生成的索引包含所有 97 个文件。

## 常见问题

### Q: `gem install` 一直卡住？

A: 
1. 等待 3-5 分钟（首次安装需要下载依赖）
2. 如果超过 10 分钟，按 `Ctrl+C` 取消
3. 尝试使用国内镜像（方法 B）
4. 或者直接使用自定义脚本

### Q: 找不到 `reapack-index` 命令？

A: 
1. 确保 PATH 已设置：`export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"`
2. 检查文件是否存在：`ls -la ~/.gem/ruby/2.6.0/bin/reapack-index`
3. 如果文件存在但命令找不到，检查 PATH 设置

### Q: 权限被拒绝？

A: 使用 `--user-install` 参数，不需要 sudo

### Q: Ruby 版本不对？

A: 如果系统 Ruby 太旧，使用 Homebrew 安装新版本：
```bash
brew install ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
```

## 快速检查清单

- [ ] Ruby 已安装：`ruby --version`
- [ ] reapack-index 已安装：`find ~/.gem -name "reapack-index"`
- [ ] PATH 已设置：`export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"`
- [ ] 命令可用：`reapack-index --version`
- [ ] 可以生成索引：`reapack-index --rebuild Release/`

