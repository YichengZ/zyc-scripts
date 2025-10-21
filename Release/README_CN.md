# Zyc Scripts

高级音频脚本集合，目前专注于REAPER效果插件，通过ReaPack轻松安装和管理。

## 🎵 REAPER 脚本

### zyc_EnvFollower
高级包络跟随器，具有以下特性：
- **Peak/RMS检测模式** - 快速峰值检测或平滑RMS检测
- **滤波器预处理** - 高通和低通滤波器，频率范围20Hz-20kHz
- **平滑处理** - Cockos风格的时间基础平滑，消除跳跃显示
- **实时示波器** - 2秒窗口的实时波形显示
- **调试功能** - 完整的信号链调试信息

### zyc_LFO
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
4. 粘贴以下URL：
   ```
   https://github.com/YichengZ/zyc-scripts/raw/main/Release/index.xml
   ```
5. 点击 `OK` 然后 `Apply`
6. 在 `Extensions` > `ReaPack` > `Browse packages` 中搜索并安装脚本

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

### zyc_EnvFollower v1.0.0
- 初始发布
- 高级包络跟随器，具有完整的Peak/RMS检测功能

### zyc_LFO v1.0.0
- 初始发布
- 精简版本，保留核心LFO功能
- 优化的性能和简化的UI

## 👨‍💻 作者

**EthanZhu** - [@yichengzhu316@outlook.com](mailto:yichengzhu316@outlook.com)

## 📄 许可证

本项目采用开源许可证，欢迎使用和修改。

## 🆘 支持

如有问题或建议，请通过GitHub Issues联系。
