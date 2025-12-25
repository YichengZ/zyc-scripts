--[[
  REAPER Companion - 配置文件
  用户配置：颜色、按键映射、开关等
--]]

local Config = {}

-- ========= UI 显示选项 =========
Config.SHOW_GLOBAL_STATS = true
Config.SHOW_PROJECT_STATS = true
Config.SHOW_DEBUG_INFO = false     -- 默认关闭（开发者功能）
Config.SHOW_POMODORO = true
Config.SHOW_TREASURE_BOX = true
Config.SHOW_PERFORMANCE = false    -- 默认关闭（开发者功能）
Config.SHOW_TEST_BUTTONS = false  -- 默认关闭（开发者功能）
Config.SHOW_DEBUG_CONSOLE = false  -- Debug Console 输出开关（默认关闭，开发者功能）
Config.DEVELOPER_MODE = false      -- 开发者模式开关（默认关闭，可通过配置文件启用）
Config.DEBUG_TREASURE_ON_SKIP = false  -- Debug: 跳过focus也显示宝箱（默认关闭，开发者功能）
Config.CURRENT_SKIN_ID = "cat_base"  -- 默认使用 PNG 皮肤（cat_base）

-- ========= UI 设置 =========
-- 字体设置
Config.CUSTOM_FONT = false
Config.FONT_SIZE = 16

-- 布局设置
Config.UI_SPACING = 10
Config.BUTTON_HEIGHT = 30
Config.BUTTON_WIDTH = 120
Config.UI_SCALE = 1.0
Config.STATS_BOX_SCALE = 1.0  -- StatsBox 独立缩放
Config.STATS_BOX_OFFSET_X = 0
Config.STATS_BOX_OFFSET_Y = 100
Config.STATS_BOX_TEXT_OFFSET_X = 0.01  -- StatsBox 文本水平偏移（相对于box宽度）
Config.STATS_BOX_TEXT_OFFSET_Y = -0.12  -- StatsBox 文本垂直偏移（相对于box高度）
Config.MENU_BUTTON_SCALE = 1.0  -- Menu Button 独立缩放
Config.MENU_BUTTON_OFFSET_X = 230
Config.MENU_BUTTON_OFFSET_Y = 0
Config.TIMER_SCALE = 1.0      -- Timer 独立缩放
Config.CHARACTER_SIZE = 140

-- 颜色设置
Config.COLORS = {
  background = 0x1A1A1AFF,  -- 背景色 (深灰色)
  text = 0xE6E6E6FF,        -- 文字色 (浅灰色)
  button = 0x333333FF,      -- 按钮色 (中灰色)
  border = 0x666666FF,      -- 边框色 (浅灰色)
  highlight = 0x4D9FFF      -- 高亮色 (蓝色)
}

-- ========= 宝箱 UI 配置 =========
Config.TREASURE_BOX = {
  width = 180,                  -- 宝箱宽度
  height = 180,                 -- 宝箱高度
  offset_x = 0,                 -- X 轴偏移 (相对于中心)
  offset_y = 0,                 -- Y 轴偏移 (相对于中心)
  margin_left = 20,             -- (Deprecated) 左侧边距
  margin_between = 20,          -- 宝箱和猫之间的间距
  glow_color = 0xFFD700FF,      -- 发光颜色 (金色)
  box_color = 0xFFA500FF,       -- 宝箱颜色 (橙色)
  lock_color = 0x888888FF,      -- 锁定状态颜色 (灰色)
  pulse_speed = 2.0,            -- 脉冲动画速度
  glow_intensity = 0.8          -- 发光强度
}

-- ========= Pomodoro Timer UI 配置 =========
Config.POMODORO_TIMER = {
  width = 100,                  -- UI 宽度
  height = 100,                 -- UI 高度
  margin_right = 10,            -- 右侧边距
  margin_top = 10,              -- 顶部边距
  -- 颜色在 ui/pomodoro_timer.lua 中定义
}

-- ========= 业务逻辑配置 =========
Config.AFK_THRESHOLD = 60  -- AFK判定阈值（秒）

-- 番茄钟配置
Config.POMODORO_FOCUS_DURATION = 25 * 60  -- 专注时长（默认25分钟）
Config.POMODORO_BREAK_DURATION = 5 * 60   -- 休息时长（默认5分钟）

-- 插件缓存配置
Config.PLUGIN_CACHE_SCAN_INTERVAL = 24 * 60 * 60  -- 扫描间隔（24小时）

-- ========= 数据路径配置 =========
Config.DATA_FILE = nil  -- 将在初始化时设置
Config.PROJ_KEY = "ReaperCompanion_stats"
Config.PROJ_ID_KEY = "project_id"

-- ========= 初始化函数 =========
function Config.init(script_path)
  -- script_path 已经是脚本所在目录（如 /path/to/ReaperCompanion/）
  -- data 文件夹在项目根目录下，所以应该是 script_path .. "data/companion_data.json"
  Config.DATA_FILE = script_path .. "data/companion_data.json"
end

-- ========= 加载配置（从 global_stats.ui_settings） =========
function Config.load_from_data(global_stats)
  if not global_stats or not global_stats.ui_settings then
    return
  end
  
  local settings = global_stats.ui_settings
  
  -- 加载显示选项
  Config.SHOW_GLOBAL_STATS = settings.show_global_stats ~= false
  Config.SHOW_PROJECT_STATS = settings.show_project_stats ~= false
  Config.SHOW_DEBUG_INFO = settings.show_debug_info ~= false
  Config.SHOW_POMODORO = settings.show_pomodoro ~= false
  Config.SHOW_TREASURE_BOX = settings.show_treasure_box ~= false
  Config.SHOW_PERFORMANCE = settings.show_performance ~= false
  Config.SHOW_TEST_BUTTONS = settings.show_test_buttons ~= false
  Config.SHOW_DEBUG_CONSOLE = settings.show_debug_console or false
  Config.DEVELOPER_MODE = settings.developer_mode or false
  Config.CURRENT_SKIN_ID = settings.current_skin_id or Config.CURRENT_SKIN_ID
  
  -- 加载字体设置
  Config.CUSTOM_FONT = settings.custom_font or false
  Config.FONT_SIZE = settings.font_size or 16
  
  -- 加载布局设置
  Config.UI_SPACING = settings.ui_spacing or 10
  Config.BUTTON_HEIGHT = settings.button_height or 30
  Config.BUTTON_WIDTH = settings.button_width or 120
  Config.UI_SCALE = settings.ui_scale or 1.0
  Config.STATS_BOX_SCALE = settings.stats_box_scale or 1.0
  Config.STATS_BOX_OFFSET_X = settings.stats_box_offset_x or 0
  Config.STATS_BOX_OFFSET_Y = settings.stats_box_offset_y or 100
  Config.STATS_BOX_TEXT_OFFSET_X = settings.stats_box_text_offset_x or 0.01
  Config.STATS_BOX_TEXT_OFFSET_Y = settings.stats_box_text_offset_y or -0.12
  Config.MENU_BUTTON_SCALE = settings.menu_button_scale or 1.0
  Config.MENU_BUTTON_OFFSET_X = settings.menu_button_offset_x or 230
  Config.MENU_BUTTON_OFFSET_Y = settings.menu_button_offset_y or 0
  Config.TIMER_SCALE = settings.timer_scale or 1.0
  Config.CHARACTER_SIZE = settings.character_size or 140
  
  -- 加载颜色设置
  if settings.colors then
    Config.COLORS.background = settings.colors.background or 0x1A1A1AFF
    Config.COLORS.text = settings.colors.text or 0xE6E6E6FF
    Config.COLORS.button = settings.colors.button or 0x333333FF
    Config.COLORS.border = settings.colors.border or 0x666666FF
    Config.COLORS.highlight = settings.colors.highlight or 0x4D9FFF
  end
end

-- ========= 保存配置（到 global_stats.ui_settings） =========
function Config.save_to_data(global_stats)
  if not global_stats.ui_settings then
    global_stats.ui_settings = {}
  end
  
  local settings = global_stats.ui_settings
  
  -- 保存显示选项
  settings.show_global_stats = Config.SHOW_GLOBAL_STATS
  settings.show_project_stats = Config.SHOW_PROJECT_STATS
  settings.show_debug_info = Config.SHOW_DEBUG_INFO
  settings.show_pomodoro = Config.SHOW_POMODORO
  settings.show_treasure_box = Config.SHOW_TREASURE_BOX
  settings.show_performance = Config.SHOW_PERFORMANCE
  settings.show_test_buttons = Config.SHOW_TEST_BUTTONS
  settings.show_debug_console = Config.SHOW_DEBUG_CONSOLE
  settings.developer_mode = Config.DEVELOPER_MODE
  settings.current_skin_id = Config.CURRENT_SKIN_ID
  
  -- 保存字体设置
  settings.custom_font = Config.CUSTOM_FONT
  settings.font_size = Config.FONT_SIZE
  
  -- 保存布局设置
  settings.ui_spacing = Config.UI_SPACING
  settings.button_height = Config.BUTTON_HEIGHT
  settings.button_width = Config.BUTTON_WIDTH
  settings.ui_scale = Config.UI_SCALE
  settings.stats_box_scale = Config.STATS_BOX_SCALE
  settings.stats_box_offset_x = Config.STATS_BOX_OFFSET_X
  settings.stats_box_offset_y = Config.STATS_BOX_OFFSET_Y
  settings.stats_box_text_offset_x = Config.STATS_BOX_TEXT_OFFSET_X
  settings.stats_box_text_offset_y = Config.STATS_BOX_TEXT_OFFSET_Y
  settings.menu_button_scale = Config.MENU_BUTTON_SCALE
  settings.menu_button_offset_x = Config.MENU_BUTTON_OFFSET_X
  settings.menu_button_offset_y = Config.MENU_BUTTON_OFFSET_Y
  settings.timer_scale = Config.TIMER_SCALE
  settings.character_size = Config.CHARACTER_SIZE
  
  -- 保存颜色设置
  settings.colors = {
    background = Config.COLORS.background,
    text = Config.COLORS.text,
    button = Config.COLORS.button,
    border = Config.COLORS.border,
    highlight = Config.COLORS.highlight
  }
end

-- ========= 重置为默认值 =========
function Config.reset_to_defaults()
  Config.SHOW_GLOBAL_STATS = true
  Config.SHOW_PROJECT_STATS = true
  Config.SHOW_DEBUG_INFO = false     -- 默认关闭（开发者功能）
  Config.SHOW_POMODORO = true
  Config.SHOW_TREASURE_BOX = true
  Config.SHOW_PERFORMANCE = false    -- 默认关闭（开发者功能）
  Config.SHOW_TEST_BUTTONS = false  -- 默认关闭（开发者功能）
  Config.SHOW_DEBUG_CONSOLE = false  -- 默认关闭（开发者功能）
  Config.DEVELOPER_MODE = false      -- 默认关闭（开发者功能，可通过配置文件启用）
  Config.CURRENT_SKIN_ID = "cat_base"
  Config.CUSTOM_FONT = false
  Config.FONT_SIZE = 16
  Config.UI_SPACING = 10
  Config.BUTTON_HEIGHT = 30
  Config.BUTTON_WIDTH = 120
  Config.UI_SCALE = 1.0
  Config.STATS_BOX_SCALE = 1.0
  Config.STATS_BOX_OFFSET_X = 0
  Config.STATS_BOX_OFFSET_Y = 100
  Config.STATS_BOX_TEXT_OFFSET_X = 0.01
  Config.STATS_BOX_TEXT_OFFSET_Y = -0.12
  Config.MENU_BUTTON_SCALE = 1.0
  Config.MENU_BUTTON_OFFSET_X = 230
  Config.MENU_BUTTON_OFFSET_Y = 0
  Config.TIMER_SCALE = 1.0
  Config.CHARACTER_SIZE = 140
  Config.COLORS.background = 0x1A1A1AFF
  Config.COLORS.text = 0xE6E6E6FF
  Config.COLORS.button = 0x333333FF
  Config.COLORS.border = 0x666666FF
  Config.COLORS.highlight = 0x4D9FFF
end

return Config

