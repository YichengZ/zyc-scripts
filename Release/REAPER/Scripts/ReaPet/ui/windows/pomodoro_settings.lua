--[[
  REAPER Companion - Pomodoro 设置窗口 UI
  番茄钟时长设置和预设管理
  这是一个纯 UI 模块，数据由 main.lua 传入
--]]

local PomodoroSettings = {}

local Pomodoro = require('core.pomodoro')
local PomodoroPresets = require('core.pomodoro_presets')
local I18n = require('utils.i18n')

-- 模块状态
local state = {
  -- 自定义时长输入（分钟和秒数）
  custom_focus_min = nil,
  custom_focus_sec = nil,
  custom_short_break_min = nil,
  custom_short_break_sec = nil,
  custom_long_break_min = nil,
  custom_long_break_sec = nil,
  
  -- 输入框缓冲区 (用于支持自由格式输入)
  input_buffers = {},
  
  -- 保存预设状态
  save_preset_name = nil,  -- nil 表示未在保存状态
}

-- ========= 辅助函数 =========

-- 解析灵活的时间格式字符串
-- 支持: "25", "25:00", "2500", "25 00"
local function parse_time_string(time_str)
  -- 移除首尾空格
  time_str = time_str:match("^%s*(.-)%s*$")
  if not time_str or time_str == "" then return nil, nil end

  -- 1. 尝试匹配分隔符格式 (MM:SS 或 MM SS)
  local min_str, sec_str = time_str:match("^(%d+)[:%s](%d+)$")
  if min_str and sec_str then
    local new_min = tonumber(min_str) or 0
    local new_sec = tonumber(sec_str) or 0
    -- 进位处理
    if new_sec >= 60 then
      new_min = new_min + math.floor(new_sec / 60)
      new_sec = new_sec % 60
    end
    return new_min, new_sec
  end
  
  -- 2. 尝试匹配纯数字
  local num_str = time_str:match("^(%d+)$")
  if num_str then
    local val = tonumber(num_str)
    
    -- 规则 A: <= 2 位数，视为分钟 (例如 "25" -> 25m, "90" -> 90m)
    if #num_str <= 2 then
      return val, 0
    end
    
    -- 规则 B: >= 3 位数，视为 MMSS (例如 "2500" -> 25m 00s, "100" -> 1m 00s)
    local len = #num_str
    local sec_part = tonumber(num_str:sub(len-1, len)) -- 后两位
    local min_part = tonumber(num_str:sub(1, len-2))   -- 前面的
    
    if sec_part >= 60 then
      min_part = min_part + math.floor(sec_part / 60)
      sec_part = sec_part % 60
    end
    return min_part, sec_part
  end
  
  return nil, nil
end

-- 格式化时间为 MM:SS 字符串
local function format_time(min, sec)
  return string.format("%02d:%02d", min or 0, sec or 0)
end

-- 处理时长输入（支持灵活格式）
local function handle_time_input(ctx, label, id, buffer_key, current_min, current_sec, on_change)
  reaper.ImGui_Text(ctx, label)
  reaper.ImGui_SetNextItemWidth(ctx, 120)
  
  -- 初始化 buffer
  if not state.input_buffers[buffer_key] then
    state.input_buffers[buffer_key] = format_time(current_min, current_sec)
  end
  
  local changed, new_str = reaper.ImGui_InputText(ctx, id, state.input_buffers[buffer_key], reaper.ImGui_InputTextFlags_None())
  
  if changed then
    state.input_buffers[buffer_key] = new_str
  end
  
  -- 编辑完成（回车或失去焦点）时解析并应用
  if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
    local new_min, new_sec = parse_time_string(state.input_buffers[buffer_key])
    if new_min and new_sec then
      -- 限制范围
      new_min = math.max(0, math.min(120, new_min))
      new_sec = math.max(0, math.min(59, new_sec))
      on_change(new_min, new_sec)
      
      -- 更新 buffer 为标准格式
      state.input_buffers[buffer_key] = format_time(new_min, new_sec)
    else
      -- 解析失败，回退
      state.input_buffers[buffer_key] = format_time(current_min, current_sec)
    end
  end
  
  -- 如果不在编辑状态，确保 buffer 与当前值同步（响应外部预设变更）
  if not reaper.ImGui_IsItemActive(ctx) and not reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
    state.input_buffers[buffer_key] = format_time(current_min, current_sec)
  end
  
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_Text(ctx, I18n.get("pomodoro_settings.time_format"))
  reaper.ImGui_Spacing(ctx)
end

-- ========= 主绘制函数 =========
-- @param ctx ImGui context
-- @param open boolean 窗口是否打开
-- @param data table 包含所有逻辑对象的表 { pomodoro, tracker, current_p_state, main_window_x, main_window_y, main_window_w, main_window_h }
-- @return boolean 新的 open 状态
function PomodoroSettings.draw(ctx, open, data)
  if not open then 
    -- 窗口关闭时重置状态
    state.save_preset_name = nil
    return false 
  end
  
  local Pomodoro = data.pomodoro
  local tracker = data.tracker
  local current_p_state = data.current_p_state
  local main_window_x = data.main_window_x
  local main_window_y = data.main_window_y
  local main_window_w = data.main_window_w
  local main_window_h = data.main_window_h
  
  local settings_window_width = 360
  local settings_window_height = 480
  local spacing = 10
  
  -- 设置窗口位置和大小
  if main_window_x and main_window_y and main_window_w and main_window_h then
    reaper.ImGui_SetNextWindowPos(ctx, main_window_x + main_window_w + spacing, main_window_y, reaper.ImGui_Cond_FirstUseEver())
  end
  reaper.ImGui_SetNextWindowSize(ctx, settings_window_width, settings_window_height, reaper.ImGui_Cond_FirstUseEver())
  
  -- 应用样式（参考 UI_DESIGN_STANDARDS.md）
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 12.0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 16, 16)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 8.0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ButtonTextAlign(), 0.5, 0.5)
  
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x2A2A2AFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x3A3A3AFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x4A4A4AFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x4ECDC4FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x4D9FFFFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x5DAFFFFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x3D8FEFFF)
  
  local settings_flags = reaper.ImGui_WindowFlags_NoTitleBar() | 
                         reaper.ImGui_WindowFlags_NoScrollbar()
  
  local win_title = (I18n.get("pomodoro_settings.title") or "Timer Settings") .. "###ZycTimerSettingsWindow"
  local visible, new_open = reaper.ImGui_Begin(ctx, win_title, true, settings_flags)
  local done_button_clicked = false
  local close_button_clicked = false
  
  if visible then
    -- 获取当前时长（分钟和秒数）
    local current_focus_total = Pomodoro.get_focus_duration()
    local current_focus_min = math.floor(current_focus_total / 60)
    local current_focus_sec = current_focus_total % 60
    
    local current_short_break_total = Pomodoro.get_short_break_duration()
    local current_short_break_min = math.floor(current_short_break_total / 60)
    local current_short_break_sec = current_short_break_total % 60
    
    local current_long_break_total = Pomodoro.get_long_break_duration()
    local current_long_break_min = math.floor(current_long_break_total / 60)
    local current_long_break_sec = current_long_break_total % 60
    
    -- 初始化输入值（如果还没有设置）
    if state.custom_focus_min == nil then state.custom_focus_min = current_focus_min end
    if state.custom_focus_sec == nil then state.custom_focus_sec = current_focus_sec end
    if state.custom_short_break_min == nil then state.custom_short_break_min = current_short_break_min end
    if state.custom_short_break_sec == nil then state.custom_short_break_sec = current_short_break_sec end
    if state.custom_long_break_min == nil then state.custom_long_break_min = current_long_break_min end
    if state.custom_long_break_sec == nil then state.custom_long_break_sec = current_long_break_sec end
    
    -- 确保秒数在有效范围内
    if state.custom_focus_sec and state.custom_focus_sec > 59 then
      state.custom_focus_min = (state.custom_focus_min or 0) + math.floor(state.custom_focus_sec / 60)
      state.custom_focus_sec = state.custom_focus_sec % 60
    end
    if state.custom_short_break_sec and state.custom_short_break_sec > 59 then
      state.custom_short_break_min = (state.custom_short_break_min or 0) + math.floor(state.custom_short_break_sec / 60)
      state.custom_short_break_sec = state.custom_short_break_sec % 60
    end
    if state.custom_long_break_sec and state.custom_long_break_sec > 59 then
      state.custom_long_break_min = (state.custom_long_break_min or 0) + math.floor(state.custom_long_break_sec / 60)
      state.custom_long_break_sec = state.custom_long_break_sec % 60
    end
    
    -- 标题栏
    reaper.ImGui_Text(ctx, I18n.get("pomodoro_settings.title"))
    
    local window_width = reaper.ImGui_GetWindowWidth(ctx)
    local button_size = 24
    local padding = 8
    reaper.ImGui_SameLine(ctx, window_width - button_size - padding)
    
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x00000000)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x3A3A3AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x4A4A4AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xCCCCCCFF)
    
    if reaper.ImGui_Button(ctx, "×", button_size, button_size) then
      close_button_clicked = true
    end
    
    reaper.ImGui_PopStyleColor(ctx, 4)
    reaper.ImGui_Spacing(ctx)
    
    -- 控制按钮
    local control_button_width = 120
    local control_button_height = 32
    reaper.ImGui_SetCursorPosX(ctx, (window_width - control_button_width) * 0.5)
    
    if current_p_state == "idle" then
      if reaper.ImGui_Button(ctx, I18n.get("pomodoro_settings.start"), control_button_width, control_button_height) then
        Pomodoro.start_focus()
      end
    else
      if reaper.ImGui_Button(ctx, I18n.get("pomodoro_settings.skip"), control_button_width, control_button_height) then
        Pomodoro.skip_phase()
      end
    end
    
    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)
    
    -- 预设选择
    reaper.ImGui_Text(ctx, I18n.get("pomodoro_settings.preset") .. ":")
    reaper.ImGui_SetNextItemWidth(ctx, 200)
    
    local preset_names, preset_keys = PomodoroPresets.build_preset_list()
    local current_preset_idx = PomodoroPresets.get_current_preset_index()
    
    local changed_preset, new_preset_idx = reaper.ImGui_Combo(ctx, "##preset_combo", current_preset_idx, table.concat(preset_names, "\0") .. "\0", #preset_names)
    if changed_preset and new_preset_idx >= 0 and new_preset_idx < #preset_keys then
      local selected_key = preset_keys[new_preset_idx + 1]
      PomodoroPresets.set_current_preset(selected_key, Pomodoro)
      
      local preset = PomodoroPresets.get_preset(selected_key)
      if preset then
        state.custom_focus_min = preset.focus_min
        state.custom_focus_sec = preset.focus_sec
        state.custom_short_break_min = preset.short_break_min
        state.custom_short_break_sec = preset.short_break_sec
        state.custom_long_break_min = preset.long_break_min
        state.custom_long_break_sec = preset.long_break_sec
        
        Pomodoro.set_focus_duration(preset.focus_min * 60 + preset.focus_sec)
        Pomodoro.set_short_break_duration(preset.short_break_min * 60 + preset.short_break_sec)
        Pomodoro.set_long_break_duration(preset.long_break_min * 60 + preset.long_break_sec)
        Pomodoro.set_auto_start_breaks(preset.auto_start_breaks)
        Pomodoro.set_auto_start_pomodoros(preset.auto_start_pomodoros)
        Pomodoro.set_long_break_interval(preset.long_break_interval)
      end
    end
    
    reaper.ImGui_SameLine(ctx, 220)
    if reaper.ImGui_Button(ctx, I18n.get("pomodoro_settings.save"), 60, 0) then
      state.save_preset_name = ""
    end
    
    reaper.ImGui_Spacing(ctx)
    
    -- 保存预设输入框
    if state.save_preset_name ~= nil then
      reaper.ImGui_SetNextItemWidth(ctx, 200)
      local changed_name, new_name = reaper.ImGui_InputText(ctx, "##save_preset_name", state.save_preset_name or "", reaper.ImGui_InputTextFlags_None())
      if changed_name then
        state.save_preset_name = new_name
      end
      
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, I18n.get("pomodoro_settings.confirm"), 80, 0) then
        if state.save_preset_name and state.save_preset_name ~= "" then
          local global_stats = tracker:get_global_stats()
          PomodoroPresets.save_preset(state.save_preset_name, {
            focus_min = state.custom_focus_min or 25,
            focus_sec = state.custom_focus_sec or 0,
            short_break_min = state.custom_short_break_min or 5,
            short_break_sec = state.custom_short_break_sec or 0,
            long_break_min = state.custom_long_break_min or 15,
            long_break_sec = state.custom_long_break_sec or 0,
            auto_start_breaks = Pomodoro.get_auto_start_breaks(),
            auto_start_pomodoros = Pomodoro.get_auto_start_pomodoros(),
            long_break_interval = Pomodoro.get_long_break_interval()
          }, global_stats)
          tracker:save_global_data()
          state.save_preset_name = nil
        end
      end
      
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, I18n.get("pomodoro_settings.cancel"), 60, 0) then
        state.save_preset_name = nil
      end
    end
    
    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)
    
    -- 时长输入
    handle_time_input(ctx, I18n.get("pomodoro_settings.focus") .. ":", "##focus_time", "focus",
      state.custom_focus_min, state.custom_focus_sec,
      function(min, sec)
        state.custom_focus_min = min
        state.custom_focus_sec = sec
        local total_seconds = min * 60 + sec
        if total_seconds > 0 then
          Pomodoro.set_focus_duration(total_seconds)
        end
      end)
    
    handle_time_input(ctx, I18n.get("pomodoro_settings.short_break") .. ":", "##short_break_time", "short_break",
      state.custom_short_break_min, state.custom_short_break_sec,
      function(min, sec)
        state.custom_short_break_min = min
        state.custom_short_break_sec = sec
        local total_seconds = min * 60 + sec
        if total_seconds > 0 then
          Pomodoro.set_short_break_duration(total_seconds)
        end
      end)
    
    handle_time_input(ctx, I18n.get("pomodoro_settings.long_break") .. ":", "##long_break_time", "long_break",
      state.custom_long_break_min, state.custom_long_break_sec,
      function(min, sec)
        state.custom_long_break_min = min
        state.custom_long_break_sec = sec
        local total_seconds = min * 60 + sec
        if total_seconds > 0 then
          Pomodoro.set_long_break_duration(total_seconds)
        end
      end)
    
    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Spacing(ctx)
    
    -- Auto Start 选项
    local auto_start_breaks = Pomodoro.get_auto_start_breaks()
    local changed_auto_breaks, new_auto_breaks = reaper.ImGui_Checkbox(ctx, I18n.get("pomodoro_settings.auto_start_breaks"), auto_start_breaks)
    if changed_auto_breaks then
      Pomodoro.set_auto_start_breaks(new_auto_breaks)
    end
    
    reaper.ImGui_Spacing(ctx)
    
    local auto_start_pomodoros = Pomodoro.get_auto_start_pomodoros()
    local changed_auto_pomodoros, new_auto_pomodoros = reaper.ImGui_Checkbox(ctx, I18n.get("pomodoro_settings.auto_start_focus"), auto_start_pomodoros)
    if changed_auto_pomodoros then
      Pomodoro.set_auto_start_pomodoros(new_auto_pomodoros)
    end
    
    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)
    
    -- Long Break Interval
    reaper.ImGui_Text(ctx, I18n.get("pomodoro_settings.long_break_interval") .. ":")
    local current_interval = Pomodoro.get_long_break_interval()
    reaper.ImGui_SetNextItemWidth(ctx, 100)
    local changed_interval, new_interval = reaper.ImGui_InputInt(ctx, "##long_break_interval", current_interval, 1, 1, reaper.ImGui_InputTextFlags_None())
    if changed_interval then
      Pomodoro.set_long_break_interval(math.max(1, math.min(20, new_interval)))
    end
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, I18n.get("pomodoro_settings.focus_sessions"))
    
    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)
    
    -- Done 按钮
    local button_width = 120
    reaper.ImGui_SetCursorPosX(ctx, (window_width - button_width) * 0.5)
    if reaper.ImGui_Button(ctx, I18n.get("pomodoro_settings.done"), button_width, 32) then
      done_button_clicked = true
    end
    
    reaper.ImGui_End(ctx)
  end
  
  -- 恢复样式
  reaper.ImGui_PopStyleColor(ctx, 7)
  reaper.ImGui_PopStyleVar(ctx, 4)
  
  -- 更新窗口状态
  if done_button_clicked or close_button_clicked then
    return false
  elseif not visible then
    return false
  else
    return new_open
  end
end

return PomodoroSettings

