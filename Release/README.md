# Zyc Scripts

Advanced audio scripts collection, currently focused on REAPER effect plugins, easily installable and manageable through ReaPack.

## 🎵 REAPER Scripts

### zyc_ReaPet (v1.0.4.6)
REAPER companion app with the following features:
- **Operation Statistics** - Track operations, time, and active time (global and project level)
- **Pomodoro Timer** - Focus/break timer with customizable presets
- **Treasure Box System** - Discover and try new plugins randomly
- **Coin System & Shop** - Earn coins and unlock character skins
- **8 Character Skins** - cat, dog, bear, rabbit, koala, lion, onion, chick
- **Multi-Project Support** - Automatic data switching between projects

### zyc_startup_actions (v2.2.0)
Startup Actions Manager for configuring commands to run automatically when REAPER starts:
- **Startup Commands Configuration** - Add/remove commands to run on REAPER launch
- **ReaPet Integration** - Automatically detect and add ReaPet to startup commands
- **SWS Extension Support** - Uses SWS Global Startup Actions
- **Multi-language Support** - English and Chinese

### zyc_EnvFollower (v3.3)
Advanced envelope follower with the following features:
- **Peak/RMS Detection Modes** - Fast peak detection or smooth RMS detection
- **Filter Preprocessing** - High-pass and low-pass filters, frequency range 20Hz-20kHz
- **Smooth Processing** - Cockos-style time-based smoothing, eliminating display jumps
- **Real-time Oscilloscope** - 2-second window real-time waveform display
- **Debug Features** - Complete signal chain debugging information

### zyc_LFO (v1.0)
Advanced LFO modulator with the following features:
- **7 Waveform Types** - Sine, Up, Down, Triangle, Square, Random, Binary
- **Precise Frequency Control** - Fine and coarse frequency adjustment
- **Jitter Effect** - Add random variations
- **Smooth Processing** - Exponential smoothing algorithm
- **Hold and Retrigger** - Hold current value and retrigger functionality
- **Real-time Visualization** - Real-time waveform display

## 🚀 Installation

### Via ReaPack (Recommended)

1. Ensure [ReaPack plugin](https://reapack.com/) is installed
2. In REAPER: `Extensions` > `ReaPack` > `Manage repositories`
3. Click `Import a repository`
4. Paste the following URL:
   ```
   https://github.com/YichengZ/zyc-scripts/raw/main/index.xml
   ```
5. Click `OK` then `Apply`
6. Search and install scripts in `Extensions` > `ReaPack` > `Browse packages`

## 🔗 Recommended Companion Scripts

For enhanced workflow, we recommend using these scripts together with Zyc Scripts:

### Essential Dependencies
- **[ReaTeam Scripts](https://github.com/ReaTeam/ReaScripts)** - Core ReaTeam repository
- **[MGUI](https://github.com/ReaTeam/ReaScripts/tree/master/ReaTeam Scripts/Development/MGUI)** - Modern GUI framework for REAPER scripts

### Recommended Companion Scripts
- **[Paranormal FX](https://github.com/ReaTeam/ReaScripts/tree/master/ReaTeam Scripts/Effects/Paranormal%20FX)** - Advanced audio effects collection
- **[Saxmand FX Router](https://github.com/ReaTeam/ReaScripts/tree/master/ReaTeam Scripts/Effects/Saxmand%20FX%20Router)** - Flexible effects routing system

### Installation Order
1. Install [ReaPack](https://reapack.com/) first
2. Add ReaTeam repository: `https://github.com/ReaTeam/ReaScripts/raw/master/index.xml`
3. Install MGUI framework
4. Install Paranormal FX and Saxmand FX Router
5. Add Zyc Scripts repository and install our effects

## 📖 Usage

### zyc_EnvFollower
1. Add effect to audio track
2. Adjust input gain and filter settings
3. Select Peak or RMS detection mode
4. Set Attack and Release times
5. Use Main Output to control envelope follower output

### zyc_LFO
1. Add effect to parameter track that needs modulation
2. Select waveform type
3. Adjust frequency (Fine + Coarse)
4. Set depth and offset
5. Optional: Add jitter and smooth effects
6. Use Hold and Retrigger functions

## 🔧 Technical Features

- **High Performance** - Optimized algorithms, low CPU usage
- **Real-time Display** - 60fps real-time waveform display
- **High-quality Smoothing** - Cockos-style time-based smoothing algorithm
- **Complete Debugging** - Detailed signal chain debugging information
- **Modern UI** - Dark theme, clear visual feedback

## 📝 Version History

### zyc_ReaPet v1.0.4.6
- Hidden Developer Mode UI in production release
- Updated UI terminology: "Startup Actions" / "启动项设置"
- Fixed data file paths for cross-platform compatibility
- Added automatic data migration

### zyc_EnvFollower v3.3
- Advanced envelope follower with complete Peak/RMS detection functionality
- Real-time oscilloscope display
- Complete debugging information

### zyc_LFO v1.0
- Advanced LFO modulator with 7 waveform types
- Real-time waveform visualization
- Hold and Retrigger functionality

### zyc_startup_actions v2.2.0
- Startup Actions Manager
- ReaPet integration
- Multi-language support

## 👨‍💻 Author

**EthanZhu** - [@yichengzhu316@outlook.com](mailto:yichengzhu316@outlook.com)

## 📄 License

This project is licensed under the MIT License. See [LICENSE](../../LICENSE) file for details.

Third-party components:
- `json.lua`: Copyright (c) 2020 rxi, MIT License (included in ReaPet/utils/json.lua)

## 🆘 Support

For questions or suggestions, please contact via GitHub Issues.