# ReaPack 索引部署方案对比

## 重要说明

**`cfillion/reapack-index-action` 官方 Action 不存在！** ReaPack 官方只提供了 `reapack-index` 命令行工具，没有官方 GitHub Action。

## 方式 1：直接提交到 main 分支（当前方式）✅

### 优点
- ✅ 配置简单，易于理解
- ✅ index.xml 和脚本文件在同一分支，易于管理
- ✅ 无需额外配置 GitHub Pages
- ✅ 适合个人项目和小型仓库

### 配置
```yaml
name: ReaPack Indexer
on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  update-index:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
      
      - name: Install reapack-index
        run: gem install reapack-index
      
      - name: Run reapack-index
        run: |
          cd Release
          yes | reapack-index --rebuild
      
      - name: Commit and push
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add Release/index.xml
          git commit -m "Auto-update ReaPack index [skip ci]" || exit 0
          git push
```

### ReaPack URL
```
https://raw.githubusercontent.com/YichengZ/zyc-scripts/main/Release/index.xml
```

---

## 方式 2：部署到 gh-pages 分支

### 优点
- ✅ index.xml 与代码分离
- ✅ 可以使用自定义域名
- ✅ 可以有独立的 GitHub Pages 网站
- ⚠️  配置更复杂

### 配置
```yaml
name: ReaPack Indexer
on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
      
      - name: Install reapack-index
        run: gem install reapack-index
      
      - name: Run reapack-index
        run: |
          cd Release
          yes | reapack-index --rebuild
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: Release
          publish_branch: gh-pages
          force_orphan: true
```

### 额外步骤
1. 在 GitHub 仓库设置中启用 GitHub Pages
2. 选择 `gh-pages` 分支作为源

### ReaPack URL
```
https://yichengz.github.io/zyc-scripts/index.xml
```

---

## 推荐方案

**对于你的情况，推荐使用方式 1（当前方式）**，因为：

1. ✅ 你的项目是个人脚本库，不需要独立网站
2. ✅ 配置简单，维护成本低
3. ✅ GitHub raw URL 对 ReaPack 完全够用
4. ✅ 不需要额外配置 GitHub Pages

---

## 常见误区

❌ **错误**：使用 `cfillion/reapack-index-action@v1.9`
- 这个 Action 不存在！

✅ **正确**：直接安装并运行 `reapack-index` gem
```yaml
- run: gem install reapack-index
- run: reapack-index --rebuild
```

