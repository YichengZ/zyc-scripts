--[[
  REAPER Companion - ImGui 辅助工具
  字体管理、窗口标志等
--]]

local ImGuiUtils = {}
local Config = require('config')

-- ========= 字体管理 =========
local dynamicFont = nil
local font_needs_refresh = false

local function create_dynamic_font()
  if Config.CUSTOM_FONT then
    return reaper.ImGui_CreateFont('sans-serif', Config.FONT_SIZE, reaper.ImGui_FontFlags_Bold())
  else
    return reaper.ImGui_CreateFont('sans-serif', Config.FONT_SIZE, reaper.ImGui_FontFlags_Bold())
  end
end

function ImGuiUtils.get_dynamic_font()
  -- 只返回字体，不进行附加操作
  -- 字体应该在初始化时或 do_font_refresh() 中附加
  return dynamicFont
end

function ImGuiUtils.init_font(ctx)
  -- 初始化字体（在程序启动时调用，ImGui 帧开始之前）
  if not dynamicFont and ctx then
    dynamicFont = create_dynamic_font()
    reaper.ImGui_Attach(ctx, dynamicFont)
  end
end

function ImGuiUtils.refresh_font()
  font_needs_refresh = true
end

function ImGuiUtils.do_font_refresh(ctx)
  -- 在 ImGui 帧开始之前调用（在 MainLoop 开始处）
  if font_needs_refresh and ctx then
    dynamicFont = create_dynamic_font()
    reaper.ImGui_Attach(ctx, dynamicFont)
    font_needs_refresh = false
  end
end

-- ========= 样式应用 =========
function ImGuiUtils.push_ui_styles(ctx)
  -- 应用字体
  reaper.ImGui_PushFont(ctx, ImGuiUtils.get_dynamic_font(ctx))
  
  -- 应用颜色
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), Config.COLORS.text)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), Config.COLORS.button)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), Config.COLORS.highlight)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), Config.COLORS.highlight)
  
  -- 应用布局
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), Config.UI_SPACING, Config.UI_SPACING)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), Config.UI_SPACING * 0.5, Config.UI_SPACING * 0.5)
end

function ImGuiUtils.pop_ui_styles(ctx)
  reaper.ImGui_PopStyleVar(ctx, 2)
  reaper.ImGui_PopStyleColor(ctx, 4)
  reaper.ImGui_PopFont(ctx)
end

-- ========= 窗口标志 =========
function ImGuiUtils.get_default_window_flags()
  return 0  -- 可以根据需要添加标志
end

return ImGuiUtils

