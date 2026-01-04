# Zyc Scripts

Advanced REAPER scripts collection by EthanZhu (Yicheng Zhu).

## 📁 Repository Structure

```
zyc-scripts/
├── Release/                   # 🚀 Published scripts
│   ├── REAPER/               # REAPER scripts
│   │   ├── Effects/          # Effect plugins (JSFX)
│   │   └── Scripts/          # Lua scripts
│   │       ├── ReaPet/      # ReaPet companion app
│   │       └── StartupActions/ # Startup Actions Manager
│   ├── README.md             # English documentation
│   └── README_CN.md          # Chinese documentation
├── Development/               # 🔧 Development files (not synced)
│   ├── zyc_EnvFollower.jsfx  # Development versions
│   └── zyc_LFO.jsfx
├── .github/                   # GitHub Actions workflows
│   └── workflows/
│       └── reapack-index.yml # Auto-generate index.xml and index-mirror.xml
├── index.xml                  # Standard ReaPack index (GitHub URLs)
├── index-mirror.xml           # Mirror index (jsDelivr CDN URLs, optimized for China)
└── README.md                  # This file
```

## 🎵 Current Scripts

### REAPER Scripts

* **zyc_ReaPet** (v1.0.5.0) - REAPER companion app with operation statistics, pomodoro timer, treasure box system, and 8 character skins
* **zyc_startup_actions** (v2.2.0) - Startup Actions Manager for configuring commands to run automatically when REAPER starts

### REAPER Effects

* **zyc_EnvFollower** (v3.3) - Advanced envelope follower with Peak/RMS detection
* **zyc_LFO** (v1.0) - Advanced LFO modulator with 7 waveform types

## 🚀 Installation

### For REAPER Users

1. **Install ReaPack plugin** (if not already installed)
   - Download from [reapack.com](https://reapack.com/)
   - Install and restart REAPER

2. **Add repository**
   - In REAPER: `Extensions` > `ReaPack` > `Manage repositories...`
   - Click `Import a repository`
   - Paste one of the following URLs:
     - **Standard (GitHub direct - recommended for most users)**: `https://github.com/YichengZ/zyc-scripts/raw/main/index.xml`
     - **Mirror (jsDelivr CDN - recommended for users in China)**: `https://cdn.jsdelivr.net/gh/YichengZ/zyc-scripts@main/index-mirror.xml`
     - **Alternative (jsDelivr CDN - standard index)**: `https://cdn.jsdelivr.net/gh/YichengZ/zyc-scripts@main/index.xml`
   - Click `OK` then `Apply`

3. **Install scripts**
   - `Extensions` > `ReaPack` > `Browse packages...`
   - Search for scripts (e.g., `zyc_ReaPet`, `zyc_EnvFollower`)
   - Click `Install`

4. **Run scripts**
   - Find scripts in `Actions` list or ReaPack browser
   - Run directly or add to toolbar

### For Developers

1. Clone the repository
2. Modify scripts in `Development/` folder
3. Copy to `Release/` when ready to publish
4. Update `Release/index.xml` with new version
5. Commit and push changes

## 📖 Documentation

### Scripts Documentation

* **English**: [Release/README.md](Release/README.md)
* **中文**: [Release/README_CN.md](Release/README_CN.md)

### ReaPet Documentation

* **User Guide**: See [Release/REAPER/Scripts/ReaPet/README.md](Release/REAPER/Scripts/ReaPet/README.md)
* **Assets Guide**: See [Release/REAPER/Scripts/ReaPet/assets/README.md](Release/REAPER/Scripts/ReaPet/assets/README.md)

## 🎯 Featured Scripts

### zyc_ReaPet (v1.0.5.0)

A comprehensive REAPER companion application featuring:

- 📊 **Operation Statistics** - Track operations, time, and active time (global and project level)
- 🍅 **Pomodoro Timer** - Focus/break timer with customizable presets
- 🎁 **Treasure Box System** - Discover and try new plugins randomly
- 💰 **Coin System & Shop** - Earn coins and unlock character skins
- 🎨 **8 Character Skins** - cat, dog, bear, rabbit, koala, lion, onion, chick
- 🔄 **Multi-Project Support** - Automatic data switching between projects
- 🌍 **Multi-language Support** - 14 languages supported

Perfect for tracking your REAPER workflow and staying focused!

### zyc_startup_actions (v2.2.0)

Startup Actions Manager for REAPER:

- ⚙️ **Configure Startup Commands** - Set commands to run automatically when REAPER starts
- 🔗 **ReaPet Integration** - Automatically add ReaPet to startup commands
- 🌍 **Multi-language Support** - English and Chinese
- 💾 **Persistent Configuration** - Settings saved in ResourcePath/Data/

## 🔧 Development Workflow

### For Effects (JSFX)

1. **Develop**: Edit scripts in `Development/` folder
2. **Test**: Ensure functionality works correctly
3. **Release**: Copy to `Release/REAPER/Effects/`
4. **Update**: Modify `Release/index.xml` with new version
5. **Commit**: Push changes to GitHub

### For Scripts (Lua)

1. **Develop**: Work in `dev` branch
2. **Test**: Ensure functionality works correctly
3. **Release**: Merge `dev` to `main` branch
4. **Auto-Update**: GitHub Actions automatically generates `index.xml` on push to `main`
5. **Commit**: Push changes to GitHub

## 👨‍💻 Author

**EthanZhu (Yicheng Zhu)** - @yichengzhu316@outlook.com

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

Third-party components:
- `json.lua`: Copyright (c) 2020 rxi, MIT License (included in Release/REAPER/Scripts/ReaPet/utils/json.lua)

## 🆘 Support

For questions or suggestions, please contact via GitHub Issues.
