# Zyc Scripts

Advanced audio scripts collection by EthanZhu.

## 📁 Repository Structure

```
zyc-scripts/
├── Release/                    # 🚀 Published scripts
│   ├── REAPER/                # REAPER scripts
│   │   └── Effects/           # Effect plugins
│   ├── index.xml              # ReaPack index
│   ├── README.md              # English documentation
│   └── README_CN.md           # Chinese documentation
├── Development/                # 🔧 Development files
│   ├── zyc_EnvFollower.jsfx   # Development versions
│   └── zyc_LFO.jsfx
└── README.md                   # This file
```

## 🎵 Current Scripts

### REAPER Effects
- **zyc_EnvFollower** - Advanced envelope follower with Peak/RMS detection
- **zyc_LFO** - Advanced LFO modulator with 7 waveform types

## 🚀 Installation

### For REAPER Users
1. Install ReaPack plugin
2. Add repository: `https://github.com/YichengZ/zyc-scripts/raw/main/Release/index.xml`
3. Browse and install scripts

### For Developers
1. Clone the repository
2. Modify scripts in `Development/` folder
3. Copy to `Release/` when ready to publish
4. Update version numbers and commit

## 📖 Documentation

- **English**: [Release/README.md](Release/README.md)
- **中文**: [Release/README_CN.md](Release/README_CN.md)

## 🔧 Development Workflow

1. **Develop**: Edit scripts in `Development/` folder
2. **Test**: Ensure functionality works correctly
3. **Release**: Copy to `Release/REAPER/Effects/`
4. **Update**: Modify `Release/index.xml` with new version
5. **Commit**: Push changes to GitHub

## 👨‍💻 Author

**EthanZhu** - [@yichengzhu316@outlook.com](mailto:yichengzhu316@outlook.com)

## 📄 License

Open source license. Feel free to use and modify.

## 🆘 Support

For questions or suggestions, please contact via GitHub Issues.
