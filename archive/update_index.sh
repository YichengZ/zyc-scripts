#!/bin/bash
# ReaPack Index 更新脚本
# 用法：./update_index.sh

set -e

echo "=== ReaPack Index 更新工具 ==="
echo ""

# 检查是否安装了 reapack-index
if ! command -v reapack-index &> /dev/null; then
    echo "❌ 未找到 reapack-index"
    echo ""
    echo "安装方法："
    echo "  gem install reapack-index"
    echo ""
    echo "或者使用 Homebrew："
    echo "  brew install reapack-index"
    exit 1
fi

cd "$(dirname "$0")/Release"

echo "当前目录: $(pwd)"
echo ""

# 扫描并生成 index.xml
echo "正在扫描文件..."
reapack-index --scan

echo ""
echo "✅ index.xml 已更新"
echo ""

# 显示变化
if [ -n "$(git status --porcelain index.xml)" ]; then
    echo "📝 index.xml 有变化："
    git diff index.xml | head -30
    echo ""
    
    # 返回仓库根目录
    cd ..
    
    # 添加并提交
    git add Release/index.xml
    git commit -m "Update ReaPack index"
    
    echo "✅ 已提交"
    echo ""
    echo "推送到 GitHub? (y/n)"
    read -r answer
    if [ "$answer" = "y" ]; then
        git push origin main
        echo "✅ 已推送到 GitHub"
    else
        echo "⏸️  跳过推送（稍后手动执行 git push）"
    fi
else
    echo "ℹ️  index.xml 无变化"
fi

echo ""
echo "完成！"

