--[[
  REAPER Companion - Pomodoro 预设管理 (最终修复版)
  包含: get_preset, save_preset, get_current_preset_index 完整支持
]]

local PomodoroPresets = {}
local json = require("utils.json")
local Debug = require("utils.debug")
local r = reaper

-- 数据文件路径
local DATA_FILE = nil

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
local builtin_order = {"classic", "short", "long", "auto"}

-- 内部状态
local state = {
  custom_presets = {},
  current_preset_key = "classic", 
}

-- 辅助函数：文件读写
local function load_json_file(path)
  if not path then return nil end
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(json.decode, content)
    if ok and type(data) == "table" then return data end
  end
  return nil
end

local function save_json_file(path, data)
  if not path then return false end
  local dir = path:match("(.*)[/\\]")
  if dir then r.RecursiveCreateDirectory(dir, 0) end
  local file = io.open(path, "w+")
  if file then
    file:write(json.encode(data))
    file:close()
    return true
  end
  return false
end

-- 初始化
function PomodoroPresets.init(data_file_path)
  -- 自动寻找路径
  if not data_file_path then
    local script_path = debug.getinfo(1, "S").source:match("@(.*[\\//])")
    data_file_path = script_path .. "../data/companion_data.json"
  end
  DATA_FILE = data_file_path
  
  -- 加载数据
  local data = load_json_file(DATA_FILE)
  if data and data.pomo_system then
    state.custom_presets = data.pomo_system.custom_presets or {}
    state.current_preset_key = data.pomo_system.current_preset_key or "classic"
  else
    PomodoroPresets.save()
  end
end

-- 保存数据到硬盘
function PomodoroPresets.save()
  if not DATA_FILE then return end
  local data = load_json_file(DATA_FILE) or {}
  data.pomo_system = {
    custom_presets = state.custom_presets,
    current_preset_key = state.current_preset_key
  }
  save_json_file(DATA_FILE, data)
end

-- ================= API 修复补充 =================

-- [修复] 供 Settings 窗口调用，获取指定 key 的详细数据
function PomodoroPresets.get_preset(key)
  if builtin_presets[key] then
    return builtin_presets[key]
  end
  if state.custom_presets[key] then
    return state.custom_presets[key]
  end
  return nil
end

-- [修复] 供 Settings 窗口调用，保存新预设
-- 参数 global_stats 为了兼容性保留，但不再使用，因为数据现在独立保存了
function PomodoroPresets.save_preset(name, preset_data, global_stats)
  if not name or name == "" then return false end
  
  local safe_name = string.lower(string.gsub(name, "%s+", "_"))
  local key = "custom_" .. safe_name
  
  state.custom_presets[key] = {
    name = name,
    focus_min = preset_data.focus_min or 25,
    focus_sec = preset_data.focus_sec or 0,
    short_break_min = preset_data.short_break_min or 5,
    short_break_sec = preset_data.short_break_sec or 0,
    long_break_min = preset_data.long_break_min or 15,
    long_break_sec = preset_data.long_break_sec or 0,
    auto_start_breaks = preset_data.auto_start_breaks,
    auto_start_pomodoros = preset_data.auto_start_pomodoros,
    long_break_interval = preset_data.long_break_interval or 4
  }
  
  -- 自动选中新预设并保存
  state.current_preset_key = key
  PomodoroPresets.save()
  return true
end

-- ================= 核心逻辑 =================

function PomodoroPresets.apply_to_timer(PomodoroModule)
  if not PomodoroModule then return end
  local key = state.current_preset_key
  local data = PomodoroPresets.get_preset(key) or builtin_presets["classic"]

  local focus_sec = (data.focus_min or 25) * 60 + (data.focus_sec or 0)
  local short_sec = (data.short_break_min or 5) * 60 + (data.short_break_sec or 0)
  local long_sec  = (data.long_break_min or 15) * 60 + (data.long_break_sec or 0)

  PomodoroModule.set_focus_duration(focus_sec)
  PomodoroModule.set_short_break_duration(short_sec)
  PomodoroModule.set_long_break_duration(long_sec)
  PomodoroModule.set_auto_start_breaks(data.auto_start_breaks)
  PomodoroModule.set_auto_start_pomodoros(data.auto_start_pomodoros)
  PomodoroModule.set_long_break_interval(data.long_break_interval or 4)
  
  if PomodoroModule.get_state() == "idle" then
     PomodoroModule.reset() 
  end
end

function PomodoroPresets.set_current_preset(key, PomodoroModule)
  state.current_preset_key = key
  PomodoroPresets.save()
  if PomodoroModule then
    PomodoroPresets.apply_to_timer(PomodoroModule)
  end
end

-- Getters
function PomodoroPresets.get_builtin_presets() return builtin_presets end
function PomodoroPresets.get_custom_presets() return state.custom_presets end
function PomodoroPresets.get_builtin_order() return builtin_order end
function PomodoroPresets.get_current_preset_key() return state.current_preset_key end

-- UI 列表构建
function PomodoroPresets.build_preset_list()
  local names, keys = {}, {}
  for _, k in ipairs(builtin_order) do table.insert(names, builtin_presets[k].name); table.insert(keys, k) end
  for k, v in pairs(state.custom_presets) do table.insert(names, v.name); table.insert(keys, k) end
  return names, keys
end

-- [修复] 修正了函数名，Settings 窗口现在能找到了
function PomodoroPresets.get_current_preset_index()
  local _, keys = PomodoroPresets.build_preset_list()
  for i, k in ipairs(keys) do
    if k == state.current_preset_key then return i - 1 end
  end
  return 0
end

return PomodoroPresets