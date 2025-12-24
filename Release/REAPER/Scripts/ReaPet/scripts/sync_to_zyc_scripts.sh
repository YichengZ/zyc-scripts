#!/bin/bash
# 同步 ReaPet main 分支到 zyc-scripts 仓库
# 使用方法: ./scripts/sync_to_zyc_scripts.sh [version]

set -e

REAPET_REPO="/Users/zhuyicheng/Documents/GitHub/ReaperCompanion"
ZYCS_REPO="/Users/zhuyicheng/Documents/GitHub/zyc_scripts"
VERSION=${1:-""}

echo "🔄 Syncing ReaPet to zyc-scripts..."

# 1. 确保在 ReaPet main 分支
cd "$REAPET_REPO"
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "⚠️  Warning: Not on main branch (current: $CURRENT_BRANCH)"
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

git pull origin main || echo "No remote changes"

# 2. 切换到 zyc-scripts
cd "$ZYCS_REPO"
if [ ! -d ".git" ]; then
  echo "❌ Error: zyc-scripts is not a git repository"
  exit 1
fi

git checkout main
git pull origin main

# 3. 使用 subtree pull 更新
echo "📥 Pulling changes from ReaPet main branch..."
git subtree pull --prefix=Release/REAPER/Scripts/ReaPet \
  https://github.com/YichengZ/ReaperCompanion.git main \
  --squash -m "Update ReaPet from main branch${VERSION:+ (v$VERSION)}" || {
  echo "⚠️  Subtree pull failed, trying alternative method..."
  
  # 备用方案：简单复制
  echo "📋 Using copy method..."
  rm -rf Release/REAPER/Scripts/ReaPet/*
  
  rsync -av --exclude='.git' \
    --exclude='docs/archive' \
    --exclude='data/companion_data.json' \
    --exclude='*.DS_Store' \
    --exclude='scripts/' \
    "$REAPET_REPO/" Release/REAPER/Scripts/ReaPet/
  
  # 清理临时文件
  cd Release/REAPER/Scripts/ReaPet
  rm -rf core/rabbit_base.png 2>/dev/null || true
  rm -rf tool/ 2>/dev/null || true
  rm -rf backup/ 2>/dev/null || true
  rm -rf releases/ 2>/dev/null || true
  
  cd "$ZYCS_REPO"
  git add Release/REAPER/Scripts/ReaPet
  git commit -m "Update ReaPet from main branch${VERSION:+ (v$VERSION)}" || echo "No changes to commit"
}

# 4. 检查是否需要更新 index.xml
if [ -n "$VERSION" ]; then
  echo "📝 Updating index.xml version to v$VERSION..."
  # 这里可以添加自动更新版本号的逻辑
  # sed -i '' "s/<version name=\"[^\"]*\"/<version name=\"$VERSION\"/" Release/index.xml
fi

# 5. 显示更改
echo ""
echo "📊 Changes:"
git status --short

# 6. 询问是否推送
read -p "Push to GitHub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  git push origin main
  echo "✅ Pushed to GitHub!"
else
  echo "⏸️  Changes committed locally, not pushed"
fi

echo "✅ Sync completed!"

