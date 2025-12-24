#!/bin/bash
# 安装 reapack-index 工具脚本

set -e

echo "=== ReaPack Index 工具安装脚本 ==="
echo ""

# 检查 Ruby
if ! command -v ruby &> /dev/null; then
    echo "❌ Ruby 未安装"
    echo "请先安装 Ruby:"
    echo "  brew install ruby"
    exit 1
fi

echo "✅ Ruby 已安装: $(ruby --version)"
echo ""

# 尝试用户级安装
echo "正在安装 reapack-index（用户级安装，无需 sudo）..."
gem install reapack-index --user-install

# 获取 Ruby 版本
RUBY_VERSION=$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')
GEM_BIN_PATH="$HOME/.gem/ruby/$RUBY_VERSION/bin"

# 检查安装是否成功
if [ -f "$GEM_BIN_PATH/reapack-index" ]; then
    echo ""
    echo "✅ reapack-index 安装成功！"
    echo ""
    echo "📝 请将以下内容添加到 ~/.zshrc 或 ~/.bash_profile："
    echo ""
    echo "export PATH=\"\$HOME/.gem/ruby/$RUBY_VERSION/bin:\$PATH\""
    echo ""
    echo "然后运行："
    echo "  source ~/.zshrc"
    echo ""
    echo "或者临时使用："
    echo "  export PATH=\"$GEM_BIN_PATH:\$PATH\""
    echo "  reapack-index --version"
else
    echo ""
    echo "⚠️  安装可能未完成，请检查错误信息"
    exit 1
fi

