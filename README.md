# Zyc Scripts

Advanced REAPER scripts collection by EthanZhu (Yicheng Zhu).

## 📁 Repository Structure

```
zyc-scripts/
├── Release/                   # 🚀 Published scripts
│   ├── REAPER/               # REAPER scripts
│   │   ├── Effects/          # Effect plugins (JSFX)
│   │   └── Scripts/          # Lua scripts
│   │       └── ReaPet/      # ReaPet companion app
│   ├── index.xml             # ReaPack index
│   ├── README.md             # English documentation
│   └── README_CN.md          # Chinese documentation
├── Development/               # 🔧 Development files
│   ├── zyc_EnvFollower.jsfx  # Development versions
│   └── zyc_LFO.jsfx
└── README.md                 # This file
```

## 🎵 Current Scripts

### REAPER Scripts

* **zyc_ReaPet** - REAPER companion app with operation statistics, pomodoro timer, treasure box system, and 8 character skins

### REAPER Effects

* **zyc_EnvFollower** - Advanced envelope follower with Peak/RMS detection
* **zyc_LFO** - Advanced LFO modulator with 7 waveform types

## 🚀 Installation

### For REAPER Users

1. **Install ReaPack plugin** (if not already installed)
   - Download from [reapack.com](https://reapack.com/)
   - Install and restart REAPER

2. **Add repository**
   - In REAPER: `Extensions` > `ReaPack` > `Manage repositories...`
   - Click `Import a repository`
   - Paste: `https://github.com/YichengZ/zyc-scripts/raw/main/Release/index.xml`
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
* **API Reference**: See [Release/REAPER/Scripts/ReaPet/docs/API_REFERENCE.md](Release/REAPER/Scripts/ReaPet/docs/API_REFERENCE.md)
* **Skin Configuration**: See [Release/REAPER/Scripts/ReaPet/docs/SKIN_CONFIGURATION_GUIDE.md](Release/REAPER/Scripts/ReaPet/docs/SKIN_CONFIGURATION_GUIDE.md)

## 🎯 Featured Scripts

### zyc_ReaPet

A comprehensive REAPER companion application featuring:

- 📊 **Operation Statistics** - Track operations, time, and active time (global and project level)
- 🍅 **Pomodoro Timer** - Focus/break timer with customizable presets
- 🎁 **Treasure Box System** - Discover and try new plugins randomly
- 💰 **Coin System & Shop** - Earn coins and unlock character skins
- 🎨 **8 Character Skins** - cat, dog, bear, rabbit, koala, lion, onion, chick
- 🔄 **Multi-Project Support** - Automatic data switching between projects

Perfect for tracking your REAPER workflow and staying focused!

## 🔧 Development Workflow

### For Effects (JSFX)

1. **Develop**: Edit scripts in `Development/` folder
2. **Test**: Ensure functionality works correctly
3. **Release**: Copy to `Release/REAPER/Effects/`
4. **Update**: Modify `Release/index.xml` with new version
5. **Commit**: Push changes to GitHub

### For Scripts (Lua)

1. **Develop**: Work in separate repository (e.g., ReaPet)
2. **Test**: Ensure functionality works correctly
3. **Release**: Merge to `main` branch
4. **Sync**: Use sync script to update zyc-scripts
   ```bash
   ./scripts/sync_to_zyc_scripts.sh v1.0.0
   ```
5. **Update**: Modify `Release/index.xml` with new version
6. **Commit**: Push changes to GitHub

## 👨‍💻 Author

**EthanZhu (Yicheng Zhu)** - @yichengzhu316@outlook.com

## 📄 License

Open source license. Feel free to use and modify.

## 🆘 Support

For questions or suggestions, please contact via GitHub Issues.
