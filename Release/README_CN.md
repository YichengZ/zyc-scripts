# Zyc Scripts

高级音频脚本集合，目前专注于REAPER效果插件，通过ReaPack轻松安装和管理。

## 🎵 REAPER 脚本

### zyc_ReaPet (v1.0.4.9)
REAPER 桌面伴侣应用，具有以下特性：
- **操作统计** - 追踪操作次数、总时长和活跃时长（全局和项目级别）
- **番茄钟** - 专注/休息计时器，支持自定义预设
- **宝箱系统** - 随机发现和尝试新插件
- **金币系统和商店** - 赚取金币并解锁角色皮肤
- **8种角色皮肤** - 猫、狗、熊、兔子、考拉、狮子、洋葱、小鸡
- **多工程支持** - 自动在工程间切换数据

### zyc_startup_actions (v2.2.0)
启动项设置管理器，用于配置在 REAPER 启动时自动运行的命令：
- **启动命令配置** - 添加/删除在 REAPER 启动时运行的命令
- **ReaPet 集成** - 自动检测并将 ReaPet 添加到启动命令
- **SWS 扩展支持** - 使用 SWS 全局启动动作
- **多语言支持** - 英文和中文

### zyc_EnvFollower (v3.3)
高级包络跟随器，具有以下特性：
- **Peak/RMS检测模式** - 快速峰值检测或平滑RMS检测
- **滤波器预处理** - 高通和低通滤波器，频率范围20Hz-20kHz
- **平滑处理** - Cockos风格的时间基础平滑，消除跳跃显示
- **实时示波器** - 2秒窗口的实时波形显示
- **调试功能** - 完整的信号链调试信息

### zyc_LFO (v1.0)
高级LFO调制器，具有以下特性：
- **7种波形类型** - 正弦波、上升、下降、三角波、方波、随机、二进制
- **精确频率控制** - 精细和粗糙频率调节
- **抖动效果** - 添加随机变化
- **平滑处理** - 指数平滑算法
- **Hold和Retrigger** - 保持当前值和重新触发功能
- **实时可视化** - 实时波形显示

## 🚀 安装方法

### 通过ReaPack安装（推荐）

1. 确保已安装 [ReaPack插件](https://reapack.com/)
2. 在REAPER中：`Extensions` > `ReaPack` > `Manage repositories`
3. 点击 `Import a repository`
4. 根据你的网络环境选择以下链接之一：

   **🇨🇳 Gitee 镜像（国内用户推荐，访问最快最稳定）：**
   ```
   https://gitee.com/YichengEthanZhu/zyc-scripts/raw/main/index.xml
   ```

   **🌍 jsDelivr CDN（全球加速，国内访问快）：**
   ```
   https://cdn.jsdelivr.net/gh/YichengZ/zyc-scripts@main/index.xml
   ```

   **🇨🇳 GitHub 镜像代理（国内用户备选）：**
   ```
   https://ghproxy.com/https://github.com/YichengZ/zyc-scripts/raw/main/index.xml
   ```

   **🔷 GitHub 直接访问（国际用户）：**
   ```
   https://github.com/YichengZ/zyc-scripts/raw/main/index.xml
   ```

5. 点击 `OK` 然后 `Apply`
6. 在 `Extensions` > `ReaPack` > `Browse packages` 中搜索并安装脚本

> 💡 **提示**：国内用户推荐使用 Gitee 镜像链接，访问最快最稳定。如果遇到连接问题，也可以尝试 jsDelivr CDN 链接。

## 🔗 推荐配套脚本

为了获得更好的工作流程，我们建议与Zyc Scripts一起使用这些脚本：

### 必要依赖
- **[ReaTeam Scripts](https://github.com/ReaTeam/ReaScripts)** - 核心ReaTeam仓库
- **[MGUI](https://github.com/ReaTeam/ReaScripts/tree/master/ReaTeam Scripts/Development/MGUI)** - REAPER脚本的现代GUI框架

### 推荐配套脚本
- **[Paranormal FX](https://github.com/ReaTeam/ReaScripts/tree/master/ReaTeam Scripts/Effects/Paranormal%20FX)** - 高级音频效果集合
- **[Saxmand FX Router](https://github.com/ReaTeam/ReaScripts/tree/master/ReaTeam Scripts/Effects/Saxmand%20FX%20Router)** - 灵活的效果路由系统

### 安装顺序
1. 首先安装 [ReaPack](https://reapack.com/)
2. 添加ReaTeam仓库：`https://github.com/ReaTeam/ReaScripts/raw/master/index.xml`
3. 安装MGUI框架
4. 安装Paranormal FX和Saxmand FX Router
5. 添加Zyc Scripts仓库并安装我们的效果

## 📖 使用方法

### zyc_EnvFollower
1. 将效果添加到音频轨道
2. 调整输入增益和滤波器设置
3. 选择Peak或RMS检测模式
4. 设置Attack和Release时间
5. 使用Main Output控制包络跟随的输出

### zyc_LFO
1. 将效果添加到需要调制的参数轨道
2. 选择波形类型
3. 调整频率（Fine + Coarse）
4. 设置深度和偏移
5. 可选：添加抖动和平滑效果
6. 使用Hold和Retrigger功能

## 🔧 技术特性

- **高性能** - 优化的算法，低CPU占用
- **实时显示** - 60fps的实时波形显示
- **高质量平滑** - Cockos风格的时间基础平滑算法
- **完整调试** - 详细的信号链调试信息
- **现代UI** - 深色主题，清晰的视觉反馈

## 📝 版本历史

### zyc_ReaPet v1.0.4.9
- 计时器和预设功能改进
- 添加 earn_tip i18n 翻译（14种语言）
- UI 优化和 bug 修复

### zyc_ReaPet v1.0.4.8
- 经济系统优化：盲盒价格降至 300，直购价格降至 600，每日上限提升至 800
- 修复恢复出厂设置：自动切换回默认猫猫皮肤
- 优化商店 UI：将 "D: 800" 改为 "每日上限: 800" 提升可读性
- 修复统计框数字等宽字体功能并添加完整 i18n 翻译

### zyc_ReaPet v1.0.4.6
- 隐藏了 Developer Mode UI（生产版本）
- 更新了 UI 术语："Startup Actions" / "启动项设置"
- 修复了数据文件路径（跨平台兼容）
- 添加了自动数据迁移功能

### zyc_EnvFollower v3.3
- 高级包络跟随器，具有完整的Peak/RMS检测功能
- 实时示波器显示
- 完整的调试信息

### zyc_LFO v1.0
- 高级LFO调制器，7种波形类型
- 实时波形显示
- Hold和Retrigger功能

### zyc_startup_actions v2.2.0
- 启动项设置管理器
- ReaPet 集成
- 多语言支持

## 👨‍💻 作者

**EthanZhu** - [@yichengzhu316@outlook.com](mailto:yichengzhu316@outlook.com)

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](../../LICENSE) 文件。

第三方组件：
- `json.lua`: Copyright (c) 2020 rxi, MIT 许可证（位于 ReaPet/utils/json.lua）

## 🆘 支持

如有问题或建议，请通过GitHub Issues联系。
