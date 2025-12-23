# ReaPet 集成到 zyc-scripts 仓库指南

> 最后更新：2025-12-24

## 🎯 为什么需要集成？

[zyc-scripts](https://github.com/YichengZ/zyc-scripts) 仓库包含 ReaPack 的 `index.xml`，可以让 REAPER 用户通过 ReaPack 插件管理器直接安装和更新脚本。

**优势**：
- ✅ 用户可以通过 ReaPack 一键安装
- ✅ 自动更新功能
- ✅ 集中管理所有脚本
- ✅ 统一的发布流程

## 📁 zyc-scripts 仓库结构

根据 [zyc-scripts 仓库](https://github.com/YichengZ/zyc-scripts) 的结构：

```
zyc-scripts/
├── Release/                   # 🚀 发布的脚本
│   ├── REAPER/               # REAPER 脚本
│   │   ├── Effects/          # 效果脚本（JSFX）
│   │   └── Scripts/          # Lua 脚本（建议添加）
│   ├── index.xml             # ReaPack 索引文件
│   ├── README.md             # 英文文档
│   └── README_CN.md          # 中文文档
├── Development/               # 🔧 开发文件
└── README.md                 # 仓库说明
```

## 📋 ReaPet 集成方案

### 方案 A：作为独立脚本目录（推荐）

**目录结构**：
```
zyc-scripts/
├── Release/
│   ├── REAPER/
│   │   ├── Effects/          # 现有的效果脚本
│   │   └── Scripts/          # 新增：Lua 脚本目录
│   │       └── ReaPet/      # ReaPet 完整项目
│   │           ├── zyc_ReaPet.lua
│   │           ├── config.lua
│   │           ├── core/
│   │           ├── ui/
│   │           ├── utils/
│   │           └── assets/
│   ├── index.xml             # 需要更新
│   └── README.md             # 需要更新
```

**优点**：
- ✅ 保持 ReaPet 的完整结构
- ✅ 不影响现有的 Effects 脚本
- ✅ 清晰的目录组织

### 方案 B：扁平化结构（不推荐）

将所有文件放在一个目录，但会破坏 ReaPet 的模块结构。

## 🔧 集成步骤

### 步骤 1：准备 ReaPet 发布版本

```bash
# 在 ReaPet 仓库中
cd /Users/zhuyicheng/Documents/GitHub/ReaperCompanion  # 或 ReaPet（如果已重命名）

# 确保在 release/v1.0.0 分支
git checkout release/v1.0.0

# 确保所有更改已提交
git status
```

### 步骤 2：克隆/更新 zyc-scripts 仓库

```bash
cd /Users/zhuyicheng/Documents/GitHub

# 如果不存在，克隆仓库
git clone https://github.com/YichengZ/zyc-scripts.git

# 如果已存在，更新
cd zyc-scripts
git pull origin main
```

### 步骤 3：创建 Scripts 目录（如果不存在）

```bash
cd zyc-scripts/Release/REAPER
mkdir -p Scripts
```

### 步骤 4：复制 ReaPet 到 zyc-scripts

**选项 A：使用 git subtree（保留历史，推荐）**

```bash
cd zyc-scripts

# 添加 ReaPet 作为 subtree
git subtree add --prefix=Release/REAPER/Scripts/ReaPet \
  https://github.com/YichengZ/ReaperCompanion.git release/v1.0.0 \
  --squash

# 或者不使用 --squash（保留完整历史）
git subtree add --prefix=Release/REAPER/Scripts/ReaPet \
  https://github.com/YichengZ/ReaperCompanion.git release/v1.0.0
```

**选项 B：简单复制（不保留历史）**

```bash
# 从 ReaPet 仓库复制
cp -r /Users/zhuyicheng/Documents/GitHub/ReaperCompanion \
  zyc-scripts/Release/REAPER/Scripts/ReaPet

# 删除 .git 目录（移除原仓库信息）
rm -rf zyc-scripts/Release/REAPER/Scripts/ReaPet/.git

# 删除不需要的文件
rm -rf zyc-scripts/Release/REAPER/Scripts/ReaPet/docs/archive
rm -rf zyc-scripts/Release/REAPER/Scripts/ReaPet/data/companion_data.json

# 提交
cd zyc-scripts
git add Release/REAPER/Scripts/ReaPet
git commit -m "Add ReaPet v1.0.0"
```

### 步骤 5：更新 index.xml

在 `zyc-scripts/Release/index.xml` 中添加 ReaPet 条目：

```xml
<?xml version="1.0" encoding="utf-8"?>
<index version="1" name="zyc-scripts">
  <!-- 现有的效果脚本条目 -->
  
  <!-- ReaPet 条目 -->
  <reapack>
    <name>zyc_ReaPet</name>
    <type>script</type>
    <version>1.0.0</version>
    <author>Yicheng Zhu (Ethan)</author>
    <description>REAPER 操作计数器 & 时长统计工具，支持多工程切换、番茄钟、宝箱系统等功能。</description>
    <link>https://github.com/YichengZ/zyc-scripts</link>
    <changelog>
      <![CDATA[
        v1.0.0 (2025-12-24)
        - 初始发布
        - 支持操作统计、番茄钟、宝箱系统
        - 8 种角色皮肤（cat, dog, bear, rabbit, koala, lion, onion, chick）
      ]]>
    </changelog>
    <category>Scripts</category>
    <metadata>
      <description>
        <![CDATA[
          ReaPet 是一个 REAPER 桌面伴侣应用，提供：
          - 📊 操作统计（全局和项目级别）
          - 🍅 番茄钟功能
          - 🎁 宝箱系统（插件推荐）
          - 🎨 多种角色皮肤
          - 💰 金币系统
        ]]>
      </description>
    </metadata>
    <source>REAPER/Scripts/ReaPet/zyc_ReaPet.lua</source>
  </reapack>
</index>
```

**注意**：
- `<source>` 路径是相对于 `Release/` 目录的
- ReaPet 是模块化项目，主入口文件是 `zyc_ReaPet.lua`
- 其他文件会作为依赖自动包含

### 步骤 6：更新 README

在 `zyc-scripts/Release/README.md` 和 `README_CN.md` 中添加 ReaPet 说明：

```markdown
## 🎵 Current Scripts

### REAPER Effects
- **zyc_EnvFollower** - Advanced envelope follower with Peak/RMS detection
- **zyc_LFO** - Advanced LFO modulator with 7 waveform types

### REAPER Scripts
- **zyc_ReaPet** - REAPER companion app with stats tracking, pomodoro timer, treasure box system, and multiple character skins
```

### 步骤 7：提交和推送

```bash
cd zyc-scripts
git add .
git commit -m "Add ReaPet v1.0.0 to zyc-scripts"
git push origin main
```

## 🔄 后续更新流程

### 更新 ReaPet 到新版本

```bash
cd zyc-scripts

# 拉取 ReaPet 的更新
git subtree pull --prefix=Release/REAPER/Scripts/ReaPet \
  https://github.com/YichengZ/ReaperCompanion.git release/v1.1.0 \
  --squash

# 更新 index.xml 中的版本号
# 编辑 Release/index.xml，更新版本号和 changelog

# 提交
git add .
git commit -m "Update ReaPet to v1.1.0"
git push origin main
```

## 📝 ReaPack index.xml 格式说明

ReaPack 的 `index.xml` 格式：

```xml
<reapack>
  <name>脚本名称</name>              <!-- 在 ReaPack 中显示的名称 -->
  <type>script</type>               <!-- script 或 effect -->
  <version>1.0.0</version>          <!-- 版本号 -->
  <author>作者名</author>           <!-- 作者 -->
  <description>描述</description>   <!-- 简短描述 -->
  <link>仓库链接</link>             <!-- GitHub 链接 -->
  <changelog>...</changelog>        <!-- 更新日志 -->
  <category>Scripts</category>      <!-- 分类 -->
  <source>相对路径</source>          <!-- 主文件路径 -->
</reapack>
```

**重要**：
- `<source>` 路径是相对于 `index.xml` 所在目录的
- 对于模块化项目，只需要指定主入口文件
- ReaPack 会自动处理依赖文件

## ⚠️ 注意事项

1. **路径问题**：
   - ReaPet 使用 `debug.getinfo(1, "S").source` 获取脚本路径
   - 这个路径在 ReaPack 安装后可能会改变
   - 需要测试确保路径解析正确

2. **资源文件**：
   - `assets/` 目录需要完整保留
   - 确保所有 PNG 文件都包含在仓库中

3. **数据文件**：
   - `data/companion_data.json` 不应包含在发布版本中
   - 确保 `.gitignore` 正确配置

4. **文档**：
   - 可以保留用户文档（如 `docs/API_REFERENCE.md`）
   - 开发文档应移除或归档

## 🚀 快速集成命令（推荐）

```bash
# 1. 准备 ReaPet
cd /Users/zhuyicheng/Documents/GitHub/ReaperCompanion
git checkout release/v1.0.0
git push origin release/v1.0.0

# 2. 集成到 zyc-scripts
cd /Users/zhuyicheng/Documents/GitHub
git clone https://github.com/YichengZ/zyc-scripts.git  # 如果不存在
cd zyc-scripts
mkdir -p Release/REAPER/Scripts

# 3. 使用 subtree 添加（保留历史）
git subtree add --prefix=Release/REAPER/Scripts/ReaPet \
  https://github.com/YichengZ/ReaperCompanion.git release/v1.0.0 \
  --squash

# 4. 更新 index.xml（手动编辑）
# 5. 更新 README（手动编辑）

# 6. 提交
git add .
git commit -m "Add ReaPet v1.0.0"
git push origin main
```

## 📖 用户安装指南

用户安装 ReaPet 的步骤：

1. **安装 ReaPack**（如果还没有）
   - 下载并安装 ReaPack 插件

2. **添加仓库**
   - 在 REAPER 中：`Extensions > ReaPack > Import a repository...`
   - 输入：`https://github.com/YichengZ/zyc-scripts/raw/main/Release/index.xml`

3. **安装 ReaPet**
   - `Extensions > ReaPack > Browse Packages...`
   - 搜索 "zyc_ReaPet"
   - 点击 Install

4. **运行脚本**
   - `Extensions > ReaPack > Browse Packages...`
   - 找到 "zyc_ReaPet"，点击 Run

## ✅ 检查清单

集成前检查：
- [ ] ReaPet 代码已测试，功能正常
- [ ] 所有更改已提交到 release/v1.0.0
- [ ] 不需要的文件已移除（archive、测试文件等）
- [ ] index.xml 格式正确
- [ ] README 已更新
- [ ] 路径解析测试通过
- [ ] 资源文件完整

---

**推荐工作流程**：
1. 在 ReaPet 仓库开发 → `develop` 分支
2. 准备发布 → `release/v1.0.0` 分支
3. 集成到 zyc-scripts → 使用 git subtree
4. 更新 index.xml 和 README
5. 推送并发布

