--[[
  REAPER Companion - Settings Window
  参考: docs/UI_DESIGN_STANDARDS.md
  
  功能：
  1. General: 皮肤、模块开关、独立缩放
  2. Timer: 番茄钟参数设置
  3. Stats: 数据统计与管理
  4. System: 版本信息、开发者模式
--]]

local Settings = {}
local Config = require('config')
local SkinManager = require('ui.skins.skin_manager')
local CoinSystem = require('core.coin_system')

-- 颜色定义 (参考 UI_DESIGN_STANDARDS.md)
local COL = {
  BG = 0x2A2A2AFF,
  FRAME_BG = 0x3A3A3AFF,
  FRAME_HOVER = 0x4A4A4AFF,
  FRAME_ACTIVE = 0x4ECDC4FF,
  BTN = 0x4D9FFFFF,
  BTN_HOVER = 0x5DAFFFFF,
  BTN_ACTIVE = 0x3D8FEFFF,
  TEXT = 0xE6E6E6FF,
  TEXT_DIM = 0xCCCCCCFF,
  CLOSE_BTN_HOVER = 0x3A3A3AFF,
  CLOSE_BTN_ACTIVE = 0x4A4A4AFF,
  HEADER_TEXT = 0xFFD700FF -- 金色标题
}

local state = {
  skin_picker_requested = false,
  dev_panel_requested = false,
  close_requested = false
}

-- 辅助函数：格式化时间
local function format_time(seconds)
  if not seconds or type(seconds) ~= "number" then return "00:00:00" end
  local h = math.floor(seconds / 3600)
  local m = math.floor((seconds % 3600) / 60)
  local s = seconds % 60
  return string.format("%02d:%02d:%02d", h, m, s)
end

-- 辅助函数：绘制自定义标题栏
local function draw_title_bar(ctx, title, on_close)
  local r = reaper
  
  -- 安全调用 SetWindowFontScale
  if r.ImGui_SetWindowFontScale then
    r.ImGui_SetWindowFontScale(ctx, 1.2)
  end
  r.ImGui_Text(ctx, title)
  if r.ImGui_SetWindowFontScale then
    r.ImGui_SetWindowFontScale(ctx, 1.0)
  end
  
  local w = r.ImGui_GetWindowWidth(ctx)
  local btn_size = 24
  local padding = 8
  
  r.ImGui_SameLine(ctx, w - btn_size - padding)
  
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x00000000)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), COL.CLOSE_BTN_HOVER)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), COL.CLOSE_BTN_ACTIVE)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), COL.TEXT_DIM)
  
  if r.ImGui_Button(ctx, "×", btn_size, btn_size) then
    if on_close then on_close() end
  end
  
  r.ImGui_PopStyleColor(ctx, 4)
  r.ImGui_Dummy(ctx, 0, 8) -- Spacing below title
end

-- ========= 绘制函数 =========
function Settings.draw(ctx, open, data)
  if not open then return false end
  
  local r = reaper
  
  -- 样式设置
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), 12.0)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 16, 16)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 8.0)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 0.5, 0.5)
  
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), COL.BG)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), COL.FRAME_BG)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), COL.FRAME_HOVER)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), COL.FRAME_ACTIVE)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), COL.BTN)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), COL.BTN_HOVER)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), COL.BTN_ACTIVE)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), COL.TEXT)
  
  -- 窗口位置：主窗口右侧
  if data.main_x and data.main_y and data.main_w then
    local settings_w = 400
    local padding = 10
    local target_x = data.main_x + data.main_w + padding
    local target_y = data.main_y
    r.ImGui_SetNextWindowPos(ctx, target_x, target_y, r.ImGui_Cond_Appearing())
  end

  -- 窗口尺寸
  r.ImGui_SetNextWindowSize(ctx, 400, 500, r.ImGui_Cond_FirstUseEver())
  
  local flags = r.ImGui_WindowFlags_NoTitleBar() | r.ImGui_WindowFlags_NoScrollbar()
  local visible, new_open = r.ImGui_Begin(ctx, "Settings##Window", true, flags)
  
  if visible then
    draw_title_bar(ctx, "Settings", function() new_open = false end)
    
    if r.ImGui_BeginTabBar(ctx, "SettingsTabs") then
      
      -- === Tab 1: General (外观与显示) ===
      if r.ImGui_BeginTabItem(ctx, "General") then
        if r.ImGui_BeginChild(ctx, "GeneralContent") then
          r.ImGui_Dummy(ctx, 0, 10)
          
          -- Skin
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, "Appearance")
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        local current_skin = SkinManager.get_active_skin_id()
        r.ImGui_Text(ctx, "Current Skin: " .. (current_skin or "None"))
        if r.ImGui_Button(ctx, "Change Skin", 200, 32) then
          state.skin_picker_requested = true
        end
        r.ImGui_Dummy(ctx, 0, 15)
        
        -- Modules (Switches)
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, "Modules")
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Stats Box Toggle
        local show_global = Config.SHOW_GLOBAL_STATS
        if r.ImGui_Checkbox(ctx, "Show Stats Box", show_global) then
          Config.SHOW_GLOBAL_STATS = not show_global
        end
        
        -- Stats Box Scale (Independent)
        if Config.SHOW_GLOBAL_STATS then
          r.ImGui_Indent(ctx, 20)
          r.ImGui_Text(ctx, "Stats Box Scale")
          local old_sb_scale = Config.STATS_BOX_SCALE or 1.0
          local _, new_sb_scale = r.ImGui_SliderDouble(ctx, "##sb_scale", old_sb_scale, 0.5, 2.0, "%.2f x")
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_sb_scale = 1.0
          end
          if new_sb_scale ~= old_sb_scale then Config.STATS_BOX_SCALE = new_sb_scale end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, "Right-click to reset") end
          
          r.ImGui_Text(ctx, "Offset X")
          local old_off_x = Config.STATS_BOX_OFFSET_X or 0
          local _, new_off_x = r.ImGui_SliderInt(ctx, "##sb_off_x", old_off_x, -500, 500)
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_off_x = 0
          end
          if new_off_x ~= old_off_x then Config.STATS_BOX_OFFSET_X = new_off_x end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, "Right-click to reset") end
          
          r.ImGui_Text(ctx, "Offset Y")
          local old_off_y = Config.STATS_BOX_OFFSET_Y or 100
          local _, new_off_y = r.ImGui_SliderInt(ctx, "##sb_off_y", old_off_y, -500, 500)
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_off_y = 100
          end
          if new_off_y ~= old_off_y then Config.STATS_BOX_OFFSET_Y = new_off_y end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, "Right-click to reset") end

          r.ImGui_Dummy(ctx, 0, 5)
          
          -- Text Offset (数字偏移)
          r.ImGui_Text(ctx, "Text Offset X")
          local old_text_off_x = Config.STATS_BOX_TEXT_OFFSET_X or -0.004
          local _, new_text_off_x = r.ImGui_SliderDouble(ctx, "##sb_text_off_x", old_text_off_x, -0.5, 0.5, "%.3f")
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_text_off_x = -0.004
          end
          if new_text_off_x ~= old_text_off_x then Config.STATS_BOX_TEXT_OFFSET_X = new_text_off_x end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, "Right-click to reset") end
          
          r.ImGui_Text(ctx, "Text Offset Y")
          local old_text_off_y = Config.STATS_BOX_TEXT_OFFSET_Y or -0.053
          local _, new_text_off_y = r.ImGui_SliderDouble(ctx, "##sb_text_off_y", old_text_off_y, -0.5, 0.5, "%.3f")
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_text_off_y = -0.053
          end
          if new_text_off_y ~= old_text_off_y then Config.STATS_BOX_TEXT_OFFSET_Y = new_text_off_y end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, "Right-click to reset") end
          
          r.ImGui_Dummy(ctx, 0, 5)
          if r.ImGui_Button(ctx, "Reset Stats Box Defaults") then
             Config.STATS_BOX_SCALE = 1.0
             Config.STATS_BOX_OFFSET_X = 0
             Config.STATS_BOX_OFFSET_Y = 100
             Config.STATS_BOX_TEXT_OFFSET_X = -0.004
             Config.STATS_BOX_TEXT_OFFSET_Y = -0.053
          end
          
          r.ImGui_Unindent(ctx, 20)
        end
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Timer Toggle
        local show_pomo = Config.SHOW_POMODORO
        if r.ImGui_Checkbox(ctx, "Show Pomodoro Timer", show_pomo) then
          Config.SHOW_POMODORO = not show_pomo
        end
        
        -- Timer Scale (Independent)
        if Config.SHOW_POMODORO then
          r.ImGui_Indent(ctx, 20)
          r.ImGui_Text(ctx, "Timer Scale")
          local old_tm_scale = Config.TIMER_SCALE or 1.0
          local _, new_tm_scale = r.ImGui_SliderDouble(ctx, "##tm_scale", old_tm_scale, 0.5, 2.0, "%.2f x")
          
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_tm_scale = 1.0
          end
          if new_tm_scale ~= old_tm_scale then Config.TIMER_SCALE = new_tm_scale end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, "Right-click to reset") end
          
          r.ImGui_Dummy(ctx, 0, 5)
          if r.ImGui_Button(ctx, "Reset Timer Defaults") then
             Config.TIMER_SCALE = 1.0
          end
          
          r.ImGui_Unindent(ctx, 20)
        end
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Treasure Box Toggle
        local show_box = Config.SHOW_TREASURE_BOX
        if r.ImGui_Checkbox(ctx, "Enable Treasure Box", show_box) then
          Config.SHOW_TREASURE_BOX = not show_box
        end
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, "  (Rewards appear after focus sessions)")
        
        r.ImGui_EndChild(ctx)
        end
        r.ImGui_EndTabItem(ctx)
      end
      
      -- === Tab 3: Stats (数据) ===
      if r.ImGui_BeginTabItem(ctx, "Stats") then
        if r.ImGui_BeginChild(ctx, "StatsContent") then
          r.ImGui_Dummy(ctx, 0, 10)
          
          local tracker = data.tracker
        if tracker then
          local gs = tracker:get_global_stats()
          
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, "Lifetime Stats")
          r.ImGui_Separator(ctx)
          r.ImGui_Dummy(ctx, 0, 5)
          
          if r.ImGui_BeginTable(ctx, "StatsTable", 2) then
             r.ImGui_TableSetupColumn(ctx, "Label", r.ImGui_TableColumnFlags_WidthFixed(), 120)
             r.ImGui_TableSetupColumn(ctx, "Value")
             
             r.ImGui_TableNextRow(ctx); r.ImGui_TableSetColumnIndex(ctx, 0); r.ImGui_Text(ctx, "Total Focus:")
             r.ImGui_TableSetColumnIndex(ctx, 1); r.ImGui_Text(ctx, format_time(gs.total_focus_time or 0))
             
             r.ImGui_TableNextRow(ctx); r.ImGui_TableSetColumnIndex(ctx, 0); r.ImGui_Text(ctx, "Total Time:")
             r.ImGui_TableSetColumnIndex(ctx, 1); r.ImGui_Text(ctx, format_time(gs.total_time))
             
             r.ImGui_TableNextRow(ctx); r.ImGui_TableSetColumnIndex(ctx, 0); r.ImGui_Text(ctx, "Operations:")
             r.ImGui_TableSetColumnIndex(ctx, 1); r.ImGui_Text(ctx, tostring(gs.total_operations))
             
             r.ImGui_EndTable(ctx)
          end
          
          r.ImGui_Dummy(ctx, 0, 15)
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, "Economy")
          r.ImGui_Separator(ctx)
          r.ImGui_Dummy(ctx, 0, 5)
          
          r.ImGui_Text(ctx, "Balance: " .. tostring(CoinSystem.get_balance()))
          r.ImGui_Text(ctx, "Today Earned: " .. tostring(CoinSystem.get_daily_earned()) .. " / 600")
          
          r.ImGui_Dummy(ctx, 0, 15)
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, "Manage Data")
          r.ImGui_Separator(ctx)
          r.ImGui_Dummy(ctx, 0, 5)
          
          if r.ImGui_Button(ctx, "Reset Daily Limit", 150, 24) then
             CoinSystem.reward_focus(0) -- Hack to reset daily
          end
        end
        r.ImGui_EndChild(ctx)
        end
        r.ImGui_EndTabItem(ctx)
      end
      
      -- === Tab 4: System (系统) ===
      if r.ImGui_BeginTabItem(ctx, "System") then
        if r.ImGui_BeginChild(ctx, "SystemContent") then
          r.ImGui_Dummy(ctx, 0, 10)
          
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, "About")
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        r.ImGui_Text(ctx, "ReaPet")
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, "Version 1.0.0")
        
        -- Developer Mode UI removed for release
        -- Developer features are still available via config file (data/companion_data.json)
        -- See docs/DEVELOPER_MODE_GUIDE.md for details
        
        r.ImGui_Dummy(ctx, 0, 20)
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, "Exit")
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Close Program Button
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0xCC3333FF)  -- 红色按钮
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0xFF4444FF)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), 0xAA2222FF)
        if r.ImGui_Button(ctx, "Close Companion", 200, 36) then
          state.close_requested = true
        end
        r.ImGui_PopStyleColor(ctx, 3)
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, "  Exit the REAPER Companion")
        
        r.ImGui_EndChild(ctx)
        end
        r.ImGui_EndTabItem(ctx)
      end

      r.ImGui_EndTabBar(ctx)
    end
    r.ImGui_End(ctx)
  end
  
  r.ImGui_PopStyleColor(ctx, 8)
  r.ImGui_PopStyleVar(ctx, 4)
  
  -- 处理返回请求
  local result = { open = new_open }
  
  if state.dev_panel_requested then
    state.dev_panel_requested = false
    result.open_dev_panel = true
  end
  
  if state.skin_picker_requested then
    state.skin_picker_requested = false
    result.open_skin_picker = true
  end
  
  if state.close_requested then
    state.close_requested = false
    result.close_program = true
  end
  
  if result.open_dev_panel or result.open_skin_picker or result.close_program then
    return result
  end
  
  return new_open
end

return Settings