# REAPER Forum Post - ReaPet v1.0.5.1

## 📋 Thread Title

```
[Script] ReaPet - Your Adorable Productivity Companion for REAPER
```

---

## 📝 Full Post Content (BBCode Format for Cockos Forum)

Copy and paste the following content directly into the forum editor:

```
[size=18][b]ReaPet - Your Adorable Productivity Companion for REAPER[/b][/size]

ReaPet is a delightful productivity companion designed specifically for REAPER users, helping you stay motivated and track your creative workflow.

[img]YOUR_MAIN_WINDOW_GIF_URL[/img]

---

[b][size=16]What is ReaPet?[/size][/b]

ReaPet is a cute productivity companion that combines operation statistics, a Pomodoro timer, a treasure box system, and an adorable pet system to help you stay motivated and track your workflow.

[img]YOUR_MAIN_WINDOW_GIF_URL[/img]

---

[b][size=16]Key Features[/size][/b]

[b]Operation Statistics[/b]
[list]
[*]Track total operations, time, and active time (global and project level)
[*]Monitor your daily active usage and working habits
[*]Automatic data switching between projects
[*]AFK detection (stops counting after 60 seconds of inactivity)
[/list]

[img]YOUR_STATS_GIF_URL[/img]

[b]Pomodoro Timer[/b]
[list]
[*]Built-in focus/break timer system
[*]Customizable presets (25/5, 45/15, etc.)
[*]Auto-start options for breaks and focus sessions
[*]Earn coins by completing focus sessions
[*]Visual and audio notifications
[*]Reminds you to rest your ears, stand up, and stay hydrated
[/list]

[img]YOUR_POMODORO_GIF_URL[/img]

[b]Treasure Box System[/b]
[list]
[*]Discover and try new plugins randomly
[*]Automatic VST plugin scanning
[*]Random plugin insertion on tracks
[*]Expand your plugin collection organically
[/list]

[img]YOUR_TREASURE_BOX_GIF_URL[/img]

[b]Coin System & Shop[/b]
[list]
[*]Earn coins by completing focus sessions
[*]Daily coin limit (800 coins per day)
[*]Purchase character skins in the shop
[*]Blind box system (300 coins) or direct purchase (600 coins)
[*]Refund system for duplicate skins
[/list]

[img]YOUR_SHOP_GIF_URL[/img]

[b]8 Character Skins[/b]
[list]
[*]Cat (default), Dog, Bear, Rabbit, Koala, Lion, Onion, Chick
[*]Animated characters that respond to your activity
[*]Unlock new skins by earning coins
[*]Switch between skins anytime
[/list]

[img]YOUR_SKINS_GIF_URL[/img]

[b]Multi-language Support[/b]
[list]
[*]14 languages: English, Chinese, Japanese, Korean, Spanish, French, German, Italian, Portuguese, Russian, Thai, Vietnamese, Indonesian, Turkish
[*]Automatic language detection based on system settings
[*]All UI elements fully translated
[/list]

[b]Startup Actions Manager[/b]
[list]
[*]Companion script for configuring startup commands
[*]Automatically detects and adds ReaPet to startup
[*]SWS Extension integration
[*]Easy-to-use interface for managing startup actions
[/list]

---

[b][size=16]Installation[/size][/b]

[b]Via ReaPack (Recommended)[/b]

[list=1]
[*]Ensure [url=https://reapack.com/]ReaPack plugin[/url] is installed
[*]In REAPER: [b]Extensions[/b] > [b]ReaPack[/b] > [b]Manage repositories...[/b]
[*]Click [b]Import a repository[/b]
[*]Paste one of the following URLs (choose based on your network):

[b]Standard (GitHub direct - recommended for most users):[/b]
[code]https://github.com/YichengZ/zyc-scripts/raw/main/index.xml[/code]

[b]Mirror (recommended for users in China):[/b]
[code]https://group.reaget.com/mirrors/YichengZ/zyc-scripts/index.xml[/code]
This mirror service is provided by the REAPER community, optimized for users in China with faster access speeds.

[b]Alternative (jsDelivr CDN):[/b]
[code]https://cdn.jsdelivr.net/gh/YichengZ/zyc-scripts@main/index.xml[/code]

[*]Click [b]OK[/b] then [b]Apply[/b]
[*]Search for [b]zyc_ReaPet[/b] in [b]Extensions[/b] > [b]ReaPack[/b] > [b]Browse packages[/b]
[*]Click [b]Install[/b]
[/list]

[b]Requirements:[/b]
[list]
[*]REAPER 7.0 or later (required)
[*]ReaImGui extension (for UI rendering) - v0.10.0.2 or later (required)
[*]SWS Extension (recommended, for Startup Actions integration)
[/list]

[b]Note:[/b] If you see an error message about outdated ReaImGui or REAPER version, the script will provide detailed instructions on how to update.

---

[b][size=16]Quick Start[/size][/b]

[list=1]
[*][b]Install ReaPet[/b] via ReaPack
[*][b]Run the script[/b] from Actions list: [code]Script: zyc_ReaPet.lua[/code]
[*]The main window will appear with your companion pet
[*][b]Start a Pomodoro session[/b] by clicking the timer
[*][b]Earn coins[/b] by completing focus sessions
[*][b]Visit the shop[/b] to unlock new character skins
[/list]

---

[b][size=16]How to Earn Coins[/size][/b]

[list]
[*]Complete Pomodoro focus sessions (earn coins based on session duration)
[*]Daily limit: 800 coins per day
[*]Click the timer on the main window to start a focus session
[*]Stay focused and complete the session to earn rewards
[*]Reset daily limit when reached (remember to take breaks!)
[/list]

---

[b][size=16]Settings & Customization[/size][/b]

ReaPet offers extensive customization options:
[list]
[*]Language selection (14 languages)
[*]Font preferences (default or monospace for numbers)
[*]Window appearance and behavior
[*]Pomodoro timer presets
[*]Factory reset option
[*]Project-specific statistics reset
[/list]

---

[b][size=16]Version History[/size][/b]

[b]v1.0.5.1[/b] (Latest)
[list]
[*]Fixed ImGui_End error in ReaImGui 0.10.0.2
[*]Improved window lifecycle management
[/list]

[b]v1.0.5.0[/b]
[list]
[*]Updated character skin assets (lion and panda)
[*]Improved product description wording
[*]Minor UI refinements
[/list]

[b]v1.0.4.9[/b]
[list]
[*]Timer and preset feature improvements
[*]Added earn_tip i18n translations (14 languages)
[*]UI refinements and bug fixes
[/list]

[b]v1.0.4.8[/b]
[list]
[*]Economic system rebalancing (lowered prices, increased daily limit to 800)
[*]Fixed factory reset skin switching
[*]Optimized shop UI (Daily Limit display)
[*]Fixed monospace font feature and added i18n translations
[/list]

View full changelog: [url=https://github.com/YichengZ/zyc-scripts]GitHub Repository[/url]

---

[b][size=16]Related Scripts[/size][/b]

[b]zyc_startup_actions (v2.2.0)[/b]
[list]
[*]Startup Actions Manager for configuring commands to run automatically when REAPER starts
[*]Automatically detects and adds ReaPet to startup commands
[*]SWS Extension integration
[*]Multi-language support
[/list]

[b]zyc_EnvFollower (v3.3)[/b]
[list]
[*]Advanced envelope follower with Peak/RMS detection
[*]Real-time oscilloscope display
[*]Complete debugging information
[/list]

[b]zyc_LFO (v1.0)[/b]
[list]
[*]Advanced LFO modulator with 7 waveform types
[*]Precise frequency control
[*]Real-time visualization
[/list]

---

[b][size=16]Technical Details[/size][/b]

[b]Architecture:[/b]
[list]
[*]MVC (Model-View-Controller) pattern
[*]Modular design for easy maintenance and extension
[*]Cross-platform compatibility (Windows, macOS, Linux)
[/list]

[b]Data Storage:[/b]
[list]
[*]User data stored in [code]ResourcePath/Data/ReaPet/companion_data.json[/code]
[*]Automatic data migration from old script directory locations
[*]Project-specific data stored in RPP file extension state
[/list]

[b]Performance:[/b]
[list]
[*]Optimized algorithms for low CPU usage
[*]Efficient state management
[*]Smooth 60fps UI rendering
[/list]

---

[b][size=16]Support & Feedback[/size][/b]

[list]
[*][url=https://github.com/YichengZ/zyc-scripts/issues]GitHub Issues[/url] - Report bugs and request features
[*][url=https://github.com/YichengZ/zyc-scripts]GitHub Repository[/url] - Source code and documentation
[*]Questions? Feel free to ask in this thread!
[/list]

---

[b][size=16]License[/size][/b]

This project is licensed under the [b]MIT License[/b]. Free to use, modify, and distribute.

---

[b][size=16]Credits[/size][/b]

[list]
[*]Developed by [b]Yicheng Zhu (Ethan)[/b]
[*]Built with ReaImGui for modern UI
[*]Uses [url=https://github.com/rxi/json.lua]rxi/json.lua[/url] (MIT License)
[/list]

---

[size=16][b]Try ReaPet today and make your REAPER workflow more enjoyable![/b][/size]
```

---

## 📋 Usage Instructions

### Step 1: Prepare GIFs
Replace all placeholder URLs in the post:
- `YOUR_MAIN_WINDOW_GIF_URL` - Main window overview GIF
- `YOUR_STATS_GIF_URL` - Statistics feature GIF
- `YOUR_POMODORO_GIF_URL` - Pomodoro timer GIF
- `YOUR_TREASURE_BOX_GIF_URL` - Treasure box system GIF
- `YOUR_SHOP_GIF_URL` - Shop purchase flow GIF
- `YOUR_SKINS_GIF_URL` - Character skins showcase GIF

### Step 2: Post to Cockos Forum
1. Go to [Cockos Forum](https://forum.cockos.com/)
2. Navigate to **"REAPER General Discussion Forum"** > **"New Scripts"** section
3. Click **"New Thread"** or **"Post New Thread"**
4. Use the title: `[Script] ReaPet - Your Adorable Productivity Companion for REAPER`
5. Paste the BBCode content (with GIF URLs replaced)
6. Preview the post to check formatting
7. Click **"Submit"** or **"Post Thread"**

---

## ✅ Pre-Post Checklist

- [ ] All GIF URLs replaced with actual image links
- [ ] Version number correct (v1.0.5.1)
- [ ] ReaPack repository URLs correct (standard and mirror)
- [ ] All links tested and working
- [ ] BBCode formatting verified
- [ ] Post previewed in forum editor

---

## 📝 Notes

1. **BBCode Format**: This post uses standard Cockos Forum BBCode tags
2. **GIF Hosting**: Recommended services: Imgur, GitHub, or imgbb.com
3. **Image Format**: Use GIF or WebP format, keep file sizes under 5MB
4. **Links**: All external links use `[url=...]...[/url]` format
5. **Code Blocks**: Use `[code]...[/code]` for code snippets
6. **Lists**: Use `[list]` and `[list=1]` for bulleted and numbered lists

---

**Ready to post! Good luck with your forum release! 🚀**
