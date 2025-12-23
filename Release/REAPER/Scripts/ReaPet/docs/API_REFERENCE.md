# 📚 Reaper Companion - API 参考文档

> 完整记录所有模块的公开接口（Public API）
> 
> 最后更新：2025-11-22

---

## 📋 目录

1. [皮肤系统 (Skin System)](#皮肤系统-skin-system)
2. [核心模块 (Core Modules)](#核心模块-core-modules)
   - [Tracker](#tracker)
   - [Pomodoro](#pomodoro)
   - [Treasure](#treasure)
3. [UI 模块](#ui-模块)
   - [Window](#window)
   - [Dashboard](#dashboard)
4. [工具模块 (Utils)](#工具模块-utils)
5. [配置模块 (Config)](#配置模块-config)

---

## 🎨 皮肤系统 (Skin System)

### BaseSkin (抽象接口)

**文件**: `ui/skins/base_skin.lua`

所有皮肤必须实现的抽象接口。

#### `BaseSkin.init()`
初始化皮肤，设置初始状态。

**参数**: 无  
**返回**: 无  
**说明**: 必须由子类实现

---

#### `BaseSkin.update(dt, char_state, ctx)`
更新动画状态（每帧调用）。

**参数**:
- `dt` (number): Delta time（秒）
- `char_state` (string): 角色状态 (`'idle'`, `'focus'`, `'operating'`, `'celebrating'`)
- `ctx` (ImGui Context): ImGui 上下文

**返回**: 无  
**说明**: 必须由子类实现，处理动画插值、输入检测等

---

#### `BaseSkin.draw(ctx, dl, x, y, w, h, char_state)`
绘制角色。

**参数**:
- `ctx` (ImGui Context): ImGui 上下文
- `dl` (ImGui DrawList): ImGui DrawList
- `x` (number): 绘制位置 X
- `y` (number): 绘制位置 Y
- `w` (number): 绘制宽度
- `h` (number): 绘制高度
- `char_state` (string): 角色状态

**返回**: 无  
**说明**: 必须由子类实现，负责所有绘图逻辑

---

#### `BaseSkin.get_recommended_size()`
获取推荐尺寸。

**参数**: 无  
**返回**: 
- `width` (number): 推荐宽度
- `height` (number): 推荐高度

**说明**: 必须由子类实现

---

#### `BaseSkin.trigger_action(action_type, is_manual)`
触发动作（供 Controller 调用）。

**参数**:
- `action_type` (string): 动作类型 (`"tap"`, `"tap_left"`, `"tap_right"`, `"celebrate"`)
- `is_manual` (boolean, 可选): 是否为手动触发（默认 `false`）

**返回**: 无  
**说明**: 必须由子类实现

---

#### `BaseSkin.get_last_manual_tap_time()`
获取上次手动触发的时间戳（用于去抖动）。

**参数**: 无  
**返回**: `number`: 时间戳（秒），如果从未手动触发则返回 `0`  
**说明**: 必须由子类实现

---

### BongoCat (具体实现)

**文件**: `ui/skins/bongo_cat.lua`

继承自 `BaseSkin`，实现了所有抽象接口，并提供了额外的功能。

#### `BongoCat.init()`
初始化 Bongo Cat 皮肤。

**参数**: 无  
**返回**: 无

---

#### `BongoCat.update(dt, char_state, ctx)`
更新 Bongo Cat 动画。

**参数**:
- `dt` (number): Delta time（秒）
- `char_state` (string): 角色状态
- `ctx` (ImGui Context): ImGui 上下文

**返回**: 无

---

#### `BongoCat.draw(ctx, dl, x, y, w, h, char_state)`
绘制 Bongo Cat。

**参数**: 同 `BaseSkin.draw()`  
**返回**: 无

---

#### `BongoCat.get_recommended_size()`
获取推荐尺寸。

**返回**: `300, 200` (base_w, base_h)

---

#### `BongoCat.trigger_action(action_type, is_manual)`
触发动作（供 Controller 调用）。

**参数**:
- `action_type` (string): 动作类型 (`"tap"`, `"tap_left"`, `"tap_right"`, `"celebrate"`)
- `is_manual` (boolean, 可选): 是否为手动触发（默认 `false`）

**返回**: 无  
**说明**: 
- `"tap"` 系列：触发拍打动画
- `"celebrate"`: 触发庆祝粒子特效
- `is_manual = true` 时会记录手动触发时间戳

---

#### `BongoCat.get_last_manual_tap_time()`
获取上次手动触发的时间戳（用于去抖动）。

**参数**: 无  
**返回**: `number`: 时间戳（秒），如果从未手动触发则返回 `0`

---

## 🔧 核心模块 (Core Modules)

### Tracker

**文件**: `core/tracker.lua`  
**类型**: 类（使用 `:new()` 创建实例）

#### `Tracker:new()`
创建新的 Tracker 实例。

**参数**: 无  
**返回**: `Tracker` 实例

**说明**: 
- 自动调用 `Tracker:init()` 加载数据
- 数据结构在构造函数中初始化

---

#### `Tracker:init()`
初始化 Tracker，加载全局和项目数据。

**参数**: 无  
**返回**: 无  
**说明**: 在 `new()` 中自动调用

---

#### `Tracker:update()`
更新统计（每帧调用）。

**参数**: 无  
**返回**: 
- `boolean`: `true` 表示检测到了用户操作，应该触发动画

**说明**: 
- 检测工程状态变化
- 检测 Undo 栈变化
- 更新计时器
- 自动保存项目数据（每 10 秒）

---

#### `Tracker:get_display_stats()`
获取当前统计摘要（用于 UI 显示）。

**参数**: 无  
**返回**: 
```lua
{
  total_ops = number,      -- 总操作数
  proj_ops = number,       -- 项目操作数
  active_time = number,    -- 活跃时间（秒）
  undo_count = number      -- 撤销次数
}
```

---

#### `Tracker:get_global_stats()`
获取全局统计数据。

**参数**: 无  
**返回**: `table`: 全局统计数据表

**说明**: 推荐使用此方法而不是直接访问 `tracker.global_stats`

---

#### `Tracker:get_project_stats()`
获取项目统计数据。

**参数**: 无  
**返回**: `table`: 项目统计数据表

**说明**: 推荐使用此方法而不是直接访问 `tracker.project_stats`

---

#### `Tracker:on_exit()`
退出清理，保存所有数据。

**参数**: 无  
**返回**: 无  
**说明**: 应该在程序退出时调用

---

#### `Tracker:get_or_create_project_id()`
获取或创建项目 ID。

**参数**: 无  
**返回**: `string`: 项目 ID

---

#### `Tracker:load_current_project_stats()`
加载当前项目的统计数据。

**参数**: 无  
**返回**: 无  
**说明**: 内部方法，自动在工程切换时调用

---

#### `Tracker:save_current_project_stats()`
保存当前项目的统计数据。

**参数**: 无  
**返回**: 无  
**说明**: 内部方法，自动定期调用

---

#### `Tracker:save_global_data()`
保存全局数据到 JSON 文件。

**参数**: 无  
**返回**: 无  
**说明**: 内部方法

---

### Pomodoro

**文件**: `core/pomodoro.lua`  
**类型**: 单例模块（直接调用函数）

#### `Pomodoro.init()`
初始化番茄钟。

**参数**: 无  
**返回**: 无

---

#### `Pomodoro.start_focus()`
开始专注时段。

**参数**: 无  
**返回**: 无  
**说明**: 
- 设置状态为 `"focus"`
- 剩余时间 = `Config.POMODORO_FOCUS_DURATION`
- 打印日志

---

#### `Pomodoro.start_break()`
开始休息时段。

**参数**: 无  
**返回**: 无  
**说明**: 
- 设置状态为 `"break"`
- 剩余时间 = `Config.POMODORO_BREAK_DURATION`
- 打印日志

---

#### `Pomodoro.toggle_pause()`
暂停/恢复番茄钟。

**参数**: 无  
**返回**: 无  
**说明**: 只在非 idle 状态下生效

---

#### `Pomodoro.reset()`
重置番茄钟到 idle 状态。

**参数**: 无  
**返回**: 无

---

#### `Pomodoro.skip_phase()`
跳过当前阶段。

**参数**: 无  
**返回**: 无  
**说明**: 
- `focus` → `break`
- `break` → `focus`

---

#### `Pomodoro.update(global_stats, project_stats)`
更新番茄钟状态（每帧调用）。

**参数**:
- `global_stats` (table, 可选): 全局统计数据（用于更新专注统计）
- `project_stats` (table, 可选): 项目统计数据（用于更新专注统计）

**返回**: 无  
**说明**: 
- 更新剩余时间
- 检测是否完成
- 专注完成时自动更新统计并触发回调
- 休息完成时触发回调

---

#### `Pomodoro.format_time(seconds)`
格式化时间为 MM:SS 格式。

**参数**:
- `seconds` (number): 秒数

**返回**: `string`: 格式化的时间字符串（如 `"25:00"`）

---

#### `Pomodoro.get_state()`
获取当前状态。

**参数**: 无  
**返回**: `string`: 状态 (`"idle"`, `"focus"`, `"break"`)

---

#### `Pomodoro.get_remaining_time()`
获取剩余时间（秒）。

**参数**: 无  
**返回**: `number`: 剩余秒数

---

#### `Pomodoro.is_paused()`
是否暂停。

**参数**: 无  
**返回**: `boolean`

---

#### `Pomodoro.get_focus_duration()`
获取专注时长（秒）。

**参数**: 无  
**返回**: `number`

---

#### `Pomodoro.get_break_duration()`
获取休息时长（秒）。

**参数**: 无  
**返回**: `number`

---

#### `Pomodoro.set_focus_duration(duration)`
设置专注时长。

**参数**:
- `duration` (number): 秒数

**返回**: 无

---

#### `Pomodoro.set_break_duration(duration)`
设置休息时长。

**参数**:
- `duration` (number): 秒数

**返回**: 无

---

#### `Pomodoro.set_on_focus_complete(callback)`
设置专注完成回调。

**参数**:
- `callback` (function): 回调函数 `function() end`

**返回**: 无  
**说明**: 专注完成时自动调用

---

#### `Pomodoro.set_on_break_complete(callback)`
设置休息完成回调。

**参数**:
- `callback` (function): 回调函数 `function() end`

**返回**: 无  
**说明**: 休息完成时自动调用

---

### Treasure

**文件**: `core/treasure.lua`  
**类型**: 单例模块（直接调用函数）

#### `Treasure.init(path)`
初始化 Treasure 模块。

**参数**:
- `path` (string): 脚本路径（用于加载 fx_scanner）

**返回**: 无  
**说明**: 加载 fx_scanner 依赖

---

#### `Treasure.init_plugin_cache(global_stats)`
初始化插件缓存。

**参数**:
- `global_stats` (table): 全局统计数据（包含插件缓存）

**返回**: 无  
**说明**: 
- 检查缓存是否存在和过期
- 如果需要，扫描并缓存插件列表

---

#### `Treasure.refresh_plugin_cache(global_stats)`
强制刷新插件缓存。

**参数**:
- `global_stats` (table): 全局统计数据

**返回**: 无  
**说明**: 强制重新扫描所有插件

---

#### `Treasure.show()`
显示宝箱（解锁）。

**参数**: 无  
**返回**: 无  
**说明**: 设置 `available = true`，Bongo Cat 状态变为 `'celebrating'`

---

#### `Treasure.open(global_stats)`
打开宝箱（插入随机插件）。

**参数**:
- `global_stats` (table): 全局统计数据（用于保存开箱历史）

**返回**: 无  
**说明**: 
- 随机选择一个插件
- 插入到当前选中的轨道
- 记录开箱历史
- 设置 `available = false`

---

#### `Treasure.is_available()`
宝箱是否可用。

**参数**: 无  
**返回**: `boolean`

---

#### `Treasure.get_plugin_count()`
获取缓存的插件数量。

**参数**: 无  
**返回**: `number`

---

#### `Treasure.get_opened_plugins()`
获取已开箱的插件历史。

**参数**: 无  
**返回**: `table`: 插件历史数组

---

#### `Treasure.get_debug_info()`
获取调试信息。

**参数**: 无  
**返回**: 
```lua
{
  candidates = number,
  last_pick = string,
  last_result = string,
  last_clicked = number
}
```

---

## 🖼️ UI 模块

### Window

**文件**: `ui/window.lua`

#### `Window.init(context, skin)`
初始化窗口模块。

**参数**:
- `context` (ImGui Context): ImGui 上下文
- `skin` (Skin): 当前皮肤实例

**返回**: 无

---

#### `Window.draw_main_window(current_skin, char_state, dt)`
绘制主窗口。

**参数**:
- `current_skin` (Skin): 当前皮肤实例
- `char_state` (string): 角色状态
- `dt` (number): Delta time

**返回**: 
- `boolean`: 窗口是否打开

---

#### `Window.check_and_save_settings(global_stats)`
检查并保存设置（如果已更改）。

**参数**:
- `global_stats` (table): 全局统计数据

**返回**: 无

---

#### `Window.do_font_refresh()`
执行字体刷新（如果需要）。

**参数**: 无  
**返回**: 无

---

### Dashboard

**文件**: `ui/windows/dashboard.lua`

#### `Dashboard.draw(ctx, open, data)`
绘制控制面板。

**参数**:
- `ctx` (ImGui Context): ImGui 上下文
- `open` (boolean): 窗口是否打开
- `data` (table): 数据对象
  ```lua
  {
    tracker = Tracker,      -- Tracker 实例
    pomodoro = Pomodoro,    -- Pomodoro 模块
    treasure = Treasure,    -- Treasure 模块
    config = Config         -- Config 模块
  }
  ```

**返回**: 
- `boolean`: 窗口是否打开（用户可能关闭窗口）

---

## 🛠️ 工具模块 (Utils)

### ImGuiUtils

**文件**: `utils/imgui_utils.lua`

#### `ImGuiUtils.init_font(ctx)`
初始化字体（在程序启动时调用）。

**参数**:
- `ctx` (ImGui Context): ImGui 上下文

**返回**: 无  
**说明**: 必须在 ImGui 帧开始之前调用

---

#### `ImGuiUtils.get_dynamic_font()`
获取动态字体。

**参数**: 无  
**返回**: `ImGui Font`: 字体对象

---

#### `ImGuiUtils.refresh_font()`
标记字体需要刷新。

**参数**: 无  
**返回**: 无  
**说明**: 设置标志，实际刷新在 `do_font_refresh()` 中执行

---

#### `ImGuiUtils.do_font_refresh(ctx)`
执行字体刷新（如果需要）。

**参数**:
- `ctx` (ImGui Context): ImGui 上下文

**返回**: 无  
**说明**: 必须在 ImGui 帧开始之前调用

---

#### `ImGuiUtils.push_ui_styles(ctx)`
应用 UI 样式（推入堆栈）。

**参数**:
- `ctx` (ImGui Context): ImGui 上下文

**返回**: 无  
**说明**: 应用字体、颜色、间距等样式

---

#### `ImGuiUtils.pop_ui_styles(ctx)`
弹出 UI 样式（从堆栈）。

**参数**:
- `ctx` (ImGui Context): ImGui 上下文

**返回**: 无  
**说明**: 与 `push_ui_styles()` 配对使用

---

#### `ImGuiUtils.get_default_window_flags()`
获取默认窗口标志。

**参数**: 无  
**返回**: `number`: 窗口标志位

---

## ⚙️ 配置模块 (Config)

**文件**: `config.lua`  
**类型**: 配置表（直接访问属性）

### 配置属性

#### UI 显示选项
- `Config.SHOW_GLOBAL_STATS` (boolean)
- `Config.SHOW_PROJECT_STATS` (boolean)
- `Config.SHOW_DEBUG_INFO` (boolean)
- `Config.SHOW_POMODORO` (boolean)
- `Config.SHOW_TREASURE_BOX` (boolean)
- `Config.SHOW_PERFORMANCE` (boolean)
- `Config.SHOW_TEST_BUTTONS` (boolean)

#### UI 设置
- `Config.CUSTOM_FONT` (boolean)
- `Config.FONT_SIZE` (number)
- `Config.UI_SPACING` (number)
- `Config.BUTTON_HEIGHT` (number)
- `Config.BUTTON_WIDTH` (number)
- `Config.UI_SCALE` (number)
- `Config.CHARACTER_SIZE` (number)

#### 颜色设置
- `Config.COLORS` (table)
  - `background` (number): RGBA 颜色值
  - `text` (number)
  - `button` (number)
  - `border` (number)
  - `highlight` (number)

#### Bongo Cat 配置
- `Config.BONGO_CAT` (table)
  - `base_w` (number): 基础宽度
  - `base_h` (number): 基础高度
  - `cat_fill` (number): 身体颜色
  - `paw_fill` (number): 爪子填充色
  - `paw_stroke` (number): 爪子描边色
  - `pad_pink` (number): 桌子颜色
  - `bg_transparent` (number): 背景透明色
  - `resize_margin` (number): 调整大小边距
  - `border_hover_col` (number): 悬停边框颜色
  - `face_col` (number): 五官颜色
  - `blush_col` (number): 腮红颜色

#### 业务逻辑配置
- `Config.AFK_THRESHOLD` (number): AFK 判定阈值（秒）
- `Config.POMODORO_FOCUS_DURATION` (number): 专注时长（秒）
- `Config.POMODORO_BREAK_DURATION` (number): 休息时长（秒）
- `Config.PLUGIN_CACHE_SCAN_INTERVAL` (number): 插件缓存扫描间隔（秒）

---

### 配置函数

#### `Config.init(script_path)`
初始化配置（设置数据文件路径）。

**参数**:
- `script_path` (string): 脚本路径

**返回**: 无

---

#### `Config.load_from_data(global_stats)`
从全局统计数据加载 UI 设置。

**参数**:
- `global_stats` (table): 全局统计数据（包含 `ui_settings`）

**返回**: 无

---

#### `Config.save_to_data(global_stats)`
保存 UI 设置到全局统计数据。

**参数**:
- `global_stats` (table): 全局统计数据

**返回**: 无  
**说明**: 修改 `global_stats.ui_settings`

---

#### `Config.reset_to_defaults()`
重置所有配置为默认值。

**参数**: 无  
**返回**: 无

---

## 📝 使用示例

### 基本使用

```lua
-- 1. 加载模块
local Tracker = require('core.tracker')
local Pomodoro = require('core.pomodoro')
local BongoCat = require('ui.skins.bongo_cat')

-- 2. 初始化
local tracker = Tracker:new()
Pomodoro.init()
BongoCat.init()

-- 3. 设置回调
Pomodoro.set_on_focus_complete(function()
  print("专注完成！")
end)

-- 4. 主循环
function Loop()
  -- 更新 Tracker
  local action_triggered = tracker:update()
  if action_triggered then
    BongoCat.trigger_action("tap", false)
  end
  
  -- 更新 Pomodoro
  Pomodoro.update(tracker.global_stats, tracker.project_stats)
  
  -- 绘制 Bongo Cat
  local char_state = Pomodoro.get_state() == 'focus' and 'focus' or 'idle'
  BongoCat.draw(ctx, dl, x, y, w, h, char_state)
  
  reaper.defer(Loop)
end
```

---

## 🔍 接口设计原则

1. **单一职责**: 每个模块只负责一个功能领域
2. **最小接口**: 只暴露必要的公开 API
3. **向后兼容**: 接口变更时保持兼容性
4. **文档完整**: 所有公开接口都有清晰的文档

---

## 📌 注意事项

1. **Tracker 是类**: 使用 `Tracker:new()` 创建实例，其他方法使用 `:` 调用
2. **Pomodoro/Treasure 是单例**: 直接调用函数，不需要创建实例
3. **皮肤系统**: 所有皮肤必须实现 `BaseSkin` 接口
4. **配置管理**: Config 是全局配置表，可以通过 `load_from_data()` 和 `save_to_data()` 持久化

---

**文档版本**: 1.0  
**最后更新**: 2025-11-22

