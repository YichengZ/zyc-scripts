# ReaPet

REAPER 操作计数器 & 时长统计工具，支持多工程切换、番茄钟、宝箱系统等功能。

## 📁 项目结构

```
ReaPet/
├── zyc_ReaPet.lua            # [Controller] 程序入口，负责初始化、主循环、事件分发
├── config.lua                # [Config] 用户配置文件 (颜色、按键映射、开关)
├── core/                     # [Model] 业务逻辑层 (不含任何绘图代码)
│   ├── tracker.lua           # 统计逻辑 (Undo检测、活跃时间、总操作数)
│   ├── pomodoro.lua          # 番茄钟状态机
│   ├── treasure.lua          # 宝箱逻辑
│   └── fx_scanner.lua        # 插件扫描器
├── utils/                    # [Utils] 通用工具
│   ├── json.lua              # JSON库
│   └── imgui_utils.lua       # ImGui 辅助函数 (字体加载、窗口标志等)
└── ui/                       # [View] 视觉表现层
    ├── window.lua            # 主窗口管理 (创建窗口、处理Docking)
    └── skins/                # [Skin System] 皮肤文件夹
        ├── cat_base.lua      # 默认猫咪皮肤 (PNG 分层)
        ├── dog_base.lua      # 狗狗皮肤
        ├── bear_base.lua     # 熊皮肤
        ├── rabbit_base.lua   # 兔子皮肤
        ├── koala_base.lua    # 考拉皮肤
        ├── lion_base.lua     # 狮子皮肤
        └── onion_base.lua    # 洋葱皮肤
```

## 🏗️ 架构说明

### MVC 架构

- **Model (core/)**: 业务逻辑层，不包含任何 UI 代码
- **View (ui/)**: 视觉表现层，负责所有 UI 渲染
- **Controller (zyc_ReaPet.lua)**: 控制器，协调 Model 和 View

### 模块说明

#### 核心模块 (core/)

- **tracker.lua**: 操作统计、数据管理、项目回顾
- **pomodoro.lua**: 番茄钟状态机，专注/休息时间管理
- **treasure.lua**: 宝箱系统，插件扫描和随机插入
- **fx_scanner.lua**: VST 插件扫描器

#### UI 模块 (ui/)

- **window.lua**: 主窗口管理、设置面板
- **skins/**: 可扩展的皮肤系统
  - **cat_base.lua**: 默认猫咪皮肤（PNG 分层渲染）
  - 其他皮肤：dog_base, bear_base, rabbit_base, koala_base, lion_base, onion_base

#### 工具模块 (utils/)

- **json.lua**: JSON 编码/解码库
- **imgui_utils.lua**: ImGui 辅助函数（字体、样式等）

## 🚀 快速开始

1. 确保已安装 ReaImGui 扩展
2. 在 REAPER 中运行 `zyc_ReaPet.lua`
3. 窗口会自动打开，显示操作统计和功能面板

## ⚙️ 配置

所有配置都在 `config.lua` 中管理，包括：
- UI 显示选项
- 字体和布局设置
- 颜色主题
- 业务逻辑参数（AFK阈值、番茄钟时长等）

## 🎨 皮肤系统

项目支持可扩展的皮肤系统，使用 PNG 分层渲染：

1. 在 `ui/skins/` 目录下创建新的皮肤文件
2. 参考现有皮肤（如 `cat_base.lua`）实现皮肤逻辑
3. 在 `ui/skins/skin_manager.lua` 中注册新皮肤
4. 准备对应的 PNG 资源文件（head, face, hands, desk 等）

当前可用皮肤：cat_base（默认）、dog_base、bear_base、rabbit_base、koala_base、lion_base、onion_base

## 📝 开发说明

### 分支结构

- **main**: 稳定版本，随时可发布
- **dev**: 开发分支，用于测试新功能

### 添加新功能

1. 业务逻辑 → 添加到 `core/`
2. UI 界面 → 添加到 `ui/`
3. 工具函数 → 添加到 `utils/`
4. 配置项 → 添加到 `config.lua`

## 📄 许可证

本项目采用 MIT 许可证。详见根目录的 [LICENSE](../../../../LICENSE) 文件。

## 🙏 致谢

- ReaImGui 扩展提供 UI 框架支持
- REAPER 社区提供的开发工具和参考

