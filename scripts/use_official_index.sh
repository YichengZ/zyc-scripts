#!/bin/bash
# 使用官方 reapack-index 工具生成索引

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 使用官方 reapack-index 生成索引 ==="
echo ""

# 检查 reapack-index 是否安装
RUBY_VERSION=$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]' 2>/dev/null || echo "2.6")
GEM_BIN_PATH="$HOME/.gem/ruby/$RUBY_VERSION/bin"

# 尝试找到 reapack-index
if [ -f "$GEM_BIN_PATH/reapack-index" ]; then
    REAPACK_INDEX="$GEM_BIN_PATH/reapack-index"
    export PATH="$GEM_BIN_PATH:$PATH"
elif command -v reapack-index &> /dev/null; then
    REAPACK_INDEX="reapack-index"
else
    echo "❌ reapack-index 未找到"
    echo ""
    echo "请先安装："
    echo "  1. 运行: bash $SCRIPT_DIR/install_reapack_index.sh"
    echo "  2. 或者手动: gem install reapack-index --user-install"
    echo ""
    exit 1
fi

echo "✅ 找到 reapack-index: $REAPACK_INDEX"
echo "版本: $($REAPACK_INDEX --version 2>&1 | head -1)"
echo ""

cd "$REPO_DIR"

# 备份现有索引
if [ -f "Release/index.xml" ]; then
    cp Release/index.xml Release/index_backup_$(date +%Y%m%d_%H%M%S).xml
    echo "✅ 已备份现有索引"
fi

echo "正在生成索引..."
echo ""

# 使用官方工具生成索引
# 注意：reapack-index 需要在 Git 仓库根目录运行
$REAPACK_INDEX --rebuild Release/ 2>&1 || {
    echo ""
    echo "⚠️  生成索引时出现问题"
    echo "尝试基本命令..."
    $REAPACK_INDEX Release/ 2>&1
}

echo ""
if [ -f "Release/index.xml" ]; then
    echo "✅ 索引生成完成: Release/index.xml"
    echo ""
    echo "统计信息："
    echo "  总行数: $(wc -l < Release/index.xml)"
    echo "  文件数: $(grep -c '<source' Release/index.xml || echo "0")"
    echo ""
    echo "主文件："
    grep 'main="main"' Release/index.xml | grep -v "Effects" | head -1
else
    echo "❌ 索引文件未生成"
    exit 1
fi

