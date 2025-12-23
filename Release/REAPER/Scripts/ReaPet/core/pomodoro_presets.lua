--[[
  REAPER Companion - Pomodoro 预设管理
  管理内置预设和用户自定义预设
--]]

local PomodoroPresets = {}

-- 内置预设
local builtin_presets = {
  classic = {
    name = "Classic",
    focus_min = 25, focus_sec = 0,
    short_break_min = 5, short_break_sec = 0,
    long_break_min = 15, long_break_sec = 0,
    auto_start_breaks = true,
    auto_start_pomodoros = true,
    long_break_interval = 4
  },
  short = {
    name = "Short Sessions",
    focus_min = 15, focus_sec = 0,
    short_break_min = 3, short_break_sec = 0,
    long_break_min = 10, long_break_sec = 0,
    auto_start_breaks = true,
    auto_start_pomodoros = true,
    long_break_interval = 4
  },
  long = {
    name = "Long Sessions",
    focus_min = 50, focus_sec = 0,
    short_break_min = 10, short_break_sec = 0,
    long_break_min = 30, long_break_sec = 0,
    auto_start_breaks = true,
    auto_start_pomodoros = true,
    long_break_interval = 2
  },
  auto = {
    name = "Auto Flow",
    focus_min = 25, focus_sec = 0,
    short_break_min = 5, short_break_sec = 0,
    long_break_min = 15, long_break_sec = 0,
    auto_start_breaks = true,
    auto_start_pomodoros = true,
    long_break_interval = 4
  }
}

-- 内置预设顺序
local builtin_order = {"classic", "short", "long", "auto"}

-- 模块状态
local state = {
  custom_presets = {},  -- 用户自定义预设
  current_preset = "classic",  -- 当前选中的预设
}

-- ========= 初始化 =========
function PomodoroPresets.init(global_stats)
  if global_stats and global_stats.pomo_presets then
    state.custom_presets = global_stats.pomo_presets
  end
end

-- ========= 获取预设 =========
function PomodoroPresets.get_builtin_presets()
  return builtin_presets
end

function PomodoroPresets.get_custom_presets()
  return state.custom_presets
end

function PomodoroPresets.get_builtin_order()
  return builtin_order
end

function PomodoroPresets.get_current_preset()
  return state.current_preset
end

function PomodoroPresets.set_current_preset(preset_key)
  state.current_preset = preset_key
end

-- ========= 获取预设数据 =========
function PomodoroPresets.get_preset(preset_key)
  if string.sub(preset_key, 1, 8) == "custom_" then
    local custom_key = string.sub(preset_key, 9)
    return state.custom_presets[custom_key]
  else
    return builtin_presets[preset_key]
  end
end

-- ========= 保存预设 =========
function PomodoroPresets.save_preset(name, preset_data, global_stats)
  if not name or name == "" then
    return false
  end
  
  local preset_key = string.lower(string.gsub(name, "%s+", "_"))
  state.custom_presets[preset_key] = {
    name = name,
    focus_min = preset_data.focus_min or 25,
    focus_sec = preset_data.focus_sec or 0,
    short_break_min = preset_data.short_break_min or 5,
    short_break_sec = preset_data.short_break_sec or 0,
    long_break_min = preset_data.long_break_min or 15,
    long_break_sec = preset_data.long_break_sec or 0,
    auto_start_breaks = preset_data.auto_start_breaks,
    auto_start_pomodoros = preset_data.auto_start_pomodoros,
    long_break_interval = preset_data.long_break_interval
  }
  
  if global_stats then
    if not global_stats.pomo_presets then
      global_stats.pomo_presets = {}
    end
    global_stats.pomo_presets[preset_key] = state.custom_presets[preset_key]
  end
  
  state.current_preset = "custom_" .. preset_key
  return true
end

-- ========= 构建预设列表（用于 UI） =========
function PomodoroPresets.build_preset_list()
  local preset_names = {}
  local preset_keys = {}
  
  -- 先添加内置预设（按顺序）
  for _, key in ipairs(builtin_order) do
    if builtin_presets[key] then
      table.insert(preset_names, builtin_presets[key].name)
      table.insert(preset_keys, key)
    end
  end
  
  -- 再添加自定义预设
  for key, preset in pairs(state.custom_presets) do
    table.insert(preset_names, preset.name)
    table.insert(preset_keys, "custom_" .. key)
  end
  
  return preset_names, preset_keys
end

-- ========= 获取当前预设索引（用于 UI） =========
function PomodoroPresets.get_current_preset_index()
  local _, preset_keys = PomodoroPresets.build_preset_list()
  for i, key in ipairs(preset_keys) do
    if key == state.current_preset then
      return i - 1  -- ImGui 使用 0-based 索引
    end
  end
  return 0
end

return PomodoroPresets

