--[[
  REAPER Companion - 窗口管理模块
  负责主窗口创建、UI渲染、设置面板等
--]]

local Window = {}
local Config = require('config')
local ImGuiUtils = require('utils.imgui_utils')

-- ========= 内部状态 =========
local ctx = nil
local OPEN_SETTINGS = false
local current_skin = nil

-- ========= 初始化 =========
function Window.init(context, skin)
  ctx = context
  current_skin = skin
end

-- ========= 设置面板 =========
function Window.draw_settings_panel(save_callback, reset_callback)
  if not OPEN_SETTINGS then return end
  
  local settings_changed = false
  
  reaper.ImGui_BeginChild(ctx, 'SETTINGS_SIDEBAR', 320, 500)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x000000EE)
  
  reaper.ImGui_Text(ctx, "UI Settings")
  reaper.ImGui_Separator(ctx)

  -- 显示选项
  reaper.ImGui_Text(ctx, "Display Options:")
  if reaper.ImGui_Checkbox(ctx, "Global Stats", Config.SHOW_GLOBAL_STATS) then
    Config.SHOW_GLOBAL_STATS = not Config.SHOW_GLOBAL_STATS
    settings_changed = true
  end
  if reaper.ImGui_Checkbox(ctx, "Project Stats", Config.SHOW_PROJECT_STATS) then
    Config.SHOW_PROJECT_STATS = not Config.SHOW_PROJECT_STATS
    settings_changed = true
  end
  if reaper.ImGui_Checkbox(ctx, "Debug Info", Config.SHOW_DEBUG_INFO) then
    Config.SHOW_DEBUG_INFO = not Config.SHOW_DEBUG_INFO
    settings_changed = true
  end
  if reaper.ImGui_Checkbox(ctx, "Pomodoro Timer", Config.SHOW_POMODORO) then
    Config.SHOW_POMODORO = not Config.SHOW_POMODORO
    settings_changed = true
  end
  if reaper.ImGui_Checkbox(ctx, "Treasure Box", Config.SHOW_TREASURE_BOX) then
    Config.SHOW_TREASURE_BOX = not Config.SHOW_TREASURE_BOX
    settings_changed = true
  end
  if reaper.ImGui_Checkbox(ctx, "Performance", Config.SHOW_PERFORMANCE) then
    Config.SHOW_PERFORMANCE = not Config.SHOW_PERFORMANCE
    settings_changed = true
  end
  if reaper.ImGui_Checkbox(ctx, "Test Buttons", Config.SHOW_TEST_BUTTONS) then
    Config.SHOW_TEST_BUTTONS = not Config.SHOW_TEST_BUTTONS
    settings_changed = true
  end

  reaper.ImGui_Separator(ctx)
  
  -- 字体设置
  reaper.ImGui_Text(ctx, "Font Settings:")
  if reaper.ImGui_Checkbox(ctx, "Custom Font", Config.CUSTOM_FONT) then
    Config.CUSTOM_FONT = not Config.CUSTOM_FONT
    settings_changed = true
    ImGuiUtils.refresh_font()
  end
  reaper.ImGui_Text(ctx, "Font Size: " .. tostring(Config.FONT_SIZE))
  local old_font_size = Config.FONT_SIZE
  _, Config.FONT_SIZE = reaper.ImGui_SliderInt(ctx, "##font_size", Config.FONT_SIZE, 12, 24)
  if Config.FONT_SIZE ~= old_font_size then
    settings_changed = true
    ImGuiUtils.refresh_font()
  end

  reaper.ImGui_Separator(ctx)
  
  -- 布局设置
  reaper.ImGui_Text(ctx, "Layout Settings:")
  reaper.ImGui_Text(ctx, "Spacing: " .. tostring(Config.UI_SPACING))
  local old_spacing = Config.UI_SPACING
  _, Config.UI_SPACING = reaper.ImGui_SliderInt(ctx, "##ui_spacing", Config.UI_SPACING, 5, 50)
  if Config.UI_SPACING ~= old_spacing then
    settings_changed = true
  end
  
  reaper.ImGui_Text(ctx, "Button Height: " .. tostring(Config.BUTTON_HEIGHT))
  local old_btn_h = Config.BUTTON_HEIGHT
  _, Config.BUTTON_HEIGHT = reaper.ImGui_SliderInt(ctx, "##btn_height", Config.BUTTON_HEIGHT, 20, 60)
  if Config.BUTTON_HEIGHT ~= old_btn_h then
    settings_changed = true
  end
  
  reaper.ImGui_Text(ctx, "Button Width: " .. tostring(Config.BUTTON_WIDTH))
  local old_btn_w = Config.BUTTON_WIDTH
  _, Config.BUTTON_WIDTH = reaper.ImGui_SliderInt(ctx, "##btn_width", Config.BUTTON_WIDTH, 60, 200)
  if Config.BUTTON_WIDTH ~= old_btn_w then
    settings_changed = true
  end
  
  reaper.ImGui_Text(ctx, "UI Scale: " .. string.format("%.1f", Config.UI_SCALE))
  local old_scale = Config.UI_SCALE
  _, Config.UI_SCALE = reaper.ImGui_SliderDouble(ctx, "##ui_scale", Config.UI_SCALE, 0.5, 2.0)
  if Config.UI_SCALE ~= old_scale then
    settings_changed = true
  end

  reaper.ImGui_Separator(ctx)
  
  -- 颜色设置
  reaper.ImGui_Text(ctx, "Color Settings:")
  local old_bg_color = Config.COLORS.background
  _, Config.COLORS.background = reaper.ImGui_ColorEdit4(ctx, "Background", Config.COLORS.background, reaper.ImGui_ColorEditFlags_NoInputs())
  if Config.COLORS.background ~= old_bg_color then
    settings_changed = true
  end
  
  local old_text_color = Config.COLORS.text
  _, Config.COLORS.text = reaper.ImGui_ColorEdit4(ctx, "Text", Config.COLORS.text, reaper.ImGui_ColorEditFlags_NoInputs())
  if Config.COLORS.text ~= old_text_color then
    settings_changed = true
  end
  
  local old_btn_color = Config.COLORS.button
  _, Config.COLORS.button = reaper.ImGui_ColorEdit4(ctx, "Button", Config.COLORS.button, reaper.ImGui_ColorEditFlags_NoInputs())
  if Config.COLORS.button ~= old_btn_color then
    settings_changed = true
  end
  
  local old_border_color = Config.COLORS.border
  _, Config.COLORS.border = reaper.ImGui_ColorEdit4(ctx, "Border", Config.COLORS.border, reaper.ImGui_ColorEditFlags_NoInputs())
  if Config.COLORS.border ~= old_border_color then
    settings_changed = true
  end
  
  local old_highlight_color = Config.COLORS.highlight
  _, Config.COLORS.highlight = reaper.ImGui_ColorEdit4(ctx, "Highlight", Config.COLORS.highlight, reaper.ImGui_ColorEditFlags_NoInputs())
  if Config.COLORS.highlight ~= old_highlight_color then
    settings_changed = true
  end

  reaper.ImGui_Separator(ctx)
  
  -- 角色设置
  reaper.ImGui_Text(ctx, "Character Settings:")
  reaper.ImGui_Text(ctx, "Size: " .. tostring(Config.CHARACTER_SIZE))
  local old_char_size = Config.CHARACTER_SIZE
  _, Config.CHARACTER_SIZE = reaper.ImGui_SliderInt(ctx, "##char_size", Config.CHARACTER_SIZE, 80, 200)
  if Config.CHARACTER_SIZE ~= old_char_size then
    settings_changed = true
  end

  reaper.ImGui_Separator(ctx)
  
  -- 重置按钮
  if reaper.ImGui_Button(ctx, "Reset to Defaults") then
    reset_callback()
  end
  
  -- 如果设置发生变化，自动保存
  if settings_changed then
    save_callback()
  end
  
  reaper.ImGui_PopStyleColor(ctx)
  reaper.ImGui_EndChild(ctx)
end

-- ========= 窗口控制 =========
function Window.toggle_settings()
  OPEN_SETTINGS = not OPEN_SETTINGS
end

function Window.is_settings_open()
  return OPEN_SETTINGS
end

function Window.get_context()
  return ctx
end

return Window

