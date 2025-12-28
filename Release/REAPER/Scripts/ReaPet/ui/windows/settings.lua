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
local I18n = require('utils.i18n')
local AutoStart = require('utils.auto_start')

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
  close_requested = false,
  show_welcome_requested = false,
  reset_preferences_requested = false,
  factory_reset_requested = false
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
    draw_title_bar(ctx, I18n.get("settings.title"), function() new_open = false end)
    
    if r.ImGui_BeginTabBar(ctx, "SettingsTabs") then
      
      -- === Tab 1: General (外观与显示) ===
      if r.ImGui_BeginTabItem(ctx, I18n.get("settings.tabs.general")) then
        if r.ImGui_BeginChild(ctx, "GeneralContent") then
          r.ImGui_Dummy(ctx, 0, 10)
          
          -- Language Selection
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.system.language"))
          r.ImGui_Separator(ctx)
          r.ImGui_Dummy(ctx, 0, 5)
          
          local current_lang = Config.LANGUAGE or "en"
          local supported_langs = I18n.get_supported_languages()
          local lang_display = {}
          local current_lang_idx = 0
          for i, lang in ipairs(supported_langs) do
            table.insert(lang_display, I18n.get_language_display(lang))
            if lang == current_lang then
              current_lang_idx = i - 1  -- ImGui Combo uses 0-based index
            end
          end
          
          r.ImGui_SetNextItemWidth(ctx, 250)
          local changed_lang, new_lang_idx = r.ImGui_Combo(ctx, "🌐##language_combo", current_lang_idx, table.concat(lang_display, "\0") .. "\0", #lang_display)
          if changed_lang and new_lang_idx >= 0 and new_lang_idx < #supported_langs then
            local selected_lang = supported_langs[new_lang_idx + 1]
            Config.LANGUAGE = selected_lang
            I18n.set_language(selected_lang)
            -- 标记需要保存
            if not data.needs_save then data.needs_save = {} end
            data.needs_save.config = true
          end
          r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("settings.system.change_interface_language"))
          
          r.ImGui_Dummy(ctx, 0, 15)
          
          -- Skin
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.general.appearance"))
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        local current_skin = SkinManager.get_active_skin_id()
        r.ImGui_Text(ctx, I18n.get("settings.general.current_skin") .. (current_skin or I18n.get("settings.general.none")))
        if r.ImGui_Button(ctx, I18n.get("settings.general.change_skin"), 200, 32) then
          state.skin_picker_requested = true
        end
        r.ImGui_Dummy(ctx, 0, 15)
        
        -- Modules (Switches)
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.general.modules"))
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Stats Box Toggle
        local show_global = Config.SHOW_GLOBAL_STATS
        if r.ImGui_Checkbox(ctx, I18n.get("settings.general.show_stats_box"), show_global) then
          Config.SHOW_GLOBAL_STATS = not show_global
        end
        
        -- Stats Box Scale (Independent)
        if Config.SHOW_GLOBAL_STATS then
          r.ImGui_Indent(ctx, 20)
          r.ImGui_Text(ctx, I18n.get("settings.general.stats_box_scale"))
          local old_sb_scale = Config.STATS_BOX_SCALE or 1.0
          local _, new_sb_scale = r.ImGui_SliderDouble(ctx, "##sb_scale", old_sb_scale, 0.5, 2.0, "%.2f x")
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_sb_scale = 1.0
          end
          if new_sb_scale ~= old_sb_scale then Config.STATS_BOX_SCALE = new_sb_scale end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, I18n.get("settings.general.right_click_to_reset")) end
          
          r.ImGui_Text(ctx, I18n.get("settings.general.offset_x"))
          local old_off_x = Config.STATS_BOX_OFFSET_X or 0
          local _, new_off_x = r.ImGui_SliderInt(ctx, "##sb_off_x", old_off_x, -500, 500)
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_off_x = 0
          end
          if new_off_x ~= old_off_x then Config.STATS_BOX_OFFSET_X = new_off_x end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, I18n.get("settings.general.right_click_to_reset")) end
          
          r.ImGui_Text(ctx, I18n.get("settings.general.offset_y"))
          local old_off_y = Config.STATS_BOX_OFFSET_Y or 100
          local _, new_off_y = r.ImGui_SliderInt(ctx, "##sb_off_y", old_off_y, -500, 500)
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_off_y = 100
          end
          if new_off_y ~= old_off_y then Config.STATS_BOX_OFFSET_Y = new_off_y end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, I18n.get("settings.general.right_click_to_reset")) end

          r.ImGui_Dummy(ctx, 0, 5)
          
          -- Text Offset (数字偏移)
          r.ImGui_Text(ctx, I18n.get("settings.general.text_offset_x"))
          local old_text_off_x = Config.STATS_BOX_TEXT_OFFSET_X or 0.01
          local _, new_text_off_x = r.ImGui_SliderDouble(ctx, "##sb_text_off_x", old_text_off_x, -0.5, 0.5, "%.3f")
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_text_off_x = 0.01
          end
          if new_text_off_x ~= old_text_off_x then Config.STATS_BOX_TEXT_OFFSET_X = new_text_off_x end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, I18n.get("settings.general.right_click_to_reset")) end
          
          r.ImGui_Text(ctx, I18n.get("settings.general.text_offset_y"))
          local old_text_off_y = Config.STATS_BOX_TEXT_OFFSET_Y or -0.12
          local _, new_text_off_y = r.ImGui_SliderDouble(ctx, "##sb_text_off_y", old_text_off_y, -0.5, 0.5, "%.3f")
          
          -- Right-click reset
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_text_off_y = -0.12
          end
          if new_text_off_y ~= old_text_off_y then Config.STATS_BOX_TEXT_OFFSET_Y = new_text_off_y end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, I18n.get("settings.general.right_click_to_reset")) end
          
          r.ImGui_Dummy(ctx, 0, 5)
          if r.ImGui_Button(ctx, I18n.get("settings.general.reset_stats_box_defaults")) then
             Config.STATS_BOX_SCALE = 1.0
             Config.STATS_BOX_OFFSET_X = 0
             Config.STATS_BOX_OFFSET_Y = 100
             Config.STATS_BOX_TEXT_OFFSET_X = 0.01
             Config.STATS_BOX_TEXT_OFFSET_Y = -0.12
          end
          
          r.ImGui_Unindent(ctx, 20)
        end
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Timer Toggle
        local show_pomo = Config.SHOW_POMODORO
        if r.ImGui_Checkbox(ctx, I18n.get("settings.general.show_pomodoro_timer"), show_pomo) then
          Config.SHOW_POMODORO = not show_pomo
        end
        
        -- Timer Scale (Independent)
        if Config.SHOW_POMODORO then
          r.ImGui_Indent(ctx, 20)
          r.ImGui_Text(ctx, I18n.get("settings.general.timer_scale"))
          local old_tm_scale = Config.TIMER_SCALE or 1.0
          local _, new_tm_scale = r.ImGui_SliderDouble(ctx, "##tm_scale", old_tm_scale, 0.5, 2.0, "%.2f x")
          
          if r.ImGui_IsItemHovered(ctx) and r.ImGui_IsMouseClicked(ctx, 1) then
             new_tm_scale = 1.0
          end
          if new_tm_scale ~= old_tm_scale then Config.TIMER_SCALE = new_tm_scale end
          if r.ImGui_IsItemHovered(ctx) then r.ImGui_SetTooltip(ctx, I18n.get("settings.general.right_click_to_reset")) end
          
          r.ImGui_Dummy(ctx, 0, 5)
          if r.ImGui_Button(ctx, I18n.get("settings.general.reset_timer_defaults")) then
             Config.TIMER_SCALE = 1.0
          end
          
          r.ImGui_Unindent(ctx, 20)
        end
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Treasure Box Toggle
        local show_box = Config.SHOW_TREASURE_BOX
        if r.ImGui_Checkbox(ctx, I18n.get("settings.general.enable_treasure_box"), show_box) then
          Config.SHOW_TREASURE_BOX = not show_box
        end
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("settings.general.treasure_box_hint"))
        
        r.ImGui_Dummy(ctx, 0, 10)
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 10)
        
        -- Window Docking
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.general.window_docking"))
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        local enable_docking = Config.ENABLE_DOCKING or false
        if r.ImGui_Checkbox(ctx, I18n.get("settings.general.enable_docking"), enable_docking) then
          Config.ENABLE_DOCKING = not enable_docking
          if not data.needs_save then data.needs_save = {} end
          data.needs_save.config = true
        end
        
        r.ImGui_Dummy(ctx, 0, 3)
        r.ImGui_TextWrapped(ctx, I18n.get("settings.general.docking_description"))
        r.ImGui_Dummy(ctx, 0, 3)
        r.ImGui_TextWrapped(ctx, I18n.get("settings.general.docking_instruction"))
        r.ImGui_Dummy(ctx, 0, 3)
        r.ImGui_TextWrapped(ctx, I18n.get("settings.general.docking_note"))
        
        -- 显示当前停靠状态（如果启用停靠）
        if Config.ENABLE_DOCKING then
          r.ImGui_Dummy(ctx, 0, 5)
          local status_text = I18n.get("settings.general.window_docked_status")
          if Config.WINDOW_DOCKED then
            status_text = status_text .. I18n.get("settings.general.window_docked")
          else
            status_text = status_text .. I18n.get("settings.general.window_floating")
          end
          r.ImGui_TextColored(ctx, COL.TEXT_DIM, status_text)
        end
        
        r.ImGui_EndChild(ctx)
        end
        r.ImGui_EndTabItem(ctx)
      end
      
      -- === Tab 3: Stats (数据) ===
      if r.ImGui_BeginTabItem(ctx, I18n.get("settings.tabs.stats")) then
        if r.ImGui_BeginChild(ctx, "StatsContent") then
          r.ImGui_Dummy(ctx, 0, 10)
          
          local tracker = data.tracker
        if tracker then
          local gs = tracker:get_global_stats()
          
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.stats.lifetime_stats"))
          r.ImGui_Separator(ctx)
          r.ImGui_Dummy(ctx, 0, 5)
          
          if r.ImGui_BeginTable(ctx, "StatsTable", 2) then
             r.ImGui_TableSetupColumn(ctx, I18n.get("settings.stats.label"), r.ImGui_TableColumnFlags_WidthFixed(), 120)
             r.ImGui_TableSetupColumn(ctx, I18n.get("settings.stats.value"))
             
             r.ImGui_TableNextRow(ctx); r.ImGui_TableSetColumnIndex(ctx, 0); r.ImGui_Text(ctx, I18n.get("settings.stats.total_focus"))
             r.ImGui_TableSetColumnIndex(ctx, 1); r.ImGui_Text(ctx, format_time(gs.total_focus_time or 0))
             
             r.ImGui_TableNextRow(ctx); r.ImGui_TableSetColumnIndex(ctx, 0); r.ImGui_Text(ctx, I18n.get("settings.stats.total_time"))
             r.ImGui_TableSetColumnIndex(ctx, 1); r.ImGui_Text(ctx, format_time(gs.total_time))
             
             r.ImGui_TableNextRow(ctx); r.ImGui_TableSetColumnIndex(ctx, 0); r.ImGui_Text(ctx, I18n.get("settings.stats.operations"))
             r.ImGui_TableSetColumnIndex(ctx, 1); r.ImGui_Text(ctx, tostring(gs.total_operations))
             
             r.ImGui_EndTable(ctx)
          end
          
          r.ImGui_Dummy(ctx, 0, 15)
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.stats.economy"))
          r.ImGui_Separator(ctx)
          r.ImGui_Dummy(ctx, 0, 5)
          
          r.ImGui_Text(ctx, I18n.get("settings.stats.balance") .. tostring(CoinSystem.get_balance()))
          r.ImGui_Text(ctx, I18n.get("settings.stats.today_earned") .. tostring(CoinSystem.get_daily_earned()) .. " / 600")
          
          r.ImGui_Dummy(ctx, 0, 15)
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.stats.manage_data"))
          r.ImGui_Separator(ctx)
          r.ImGui_Dummy(ctx, 0, 5)
          
          if r.ImGui_Button(ctx, I18n.get("settings.stats.reset_daily_limit"), 150, 24) then
             CoinSystem.reset_daily_limit()
          end
        end
        r.ImGui_EndChild(ctx)
        end
        r.ImGui_EndTabItem(ctx)
      end
      
      -- === Tab 4: System (系统) ===
      if r.ImGui_BeginTabItem(ctx, I18n.get("settings.tabs.system")) then
        if r.ImGui_BeginChild(ctx, "SystemContent") then
          r.ImGui_Dummy(ctx, 0, 10)
          
          r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.system.about"))
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        r.ImGui_Text(ctx, "ReaPet")
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("settings.system.version"))
        
        r.ImGui_Dummy(ctx, 0, 15)
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.system.instructions"))
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Show Welcome Instructions Button
        if r.ImGui_Button(ctx, I18n.get("settings.system.show_instructions"), 200, 32) then
          state.show_welcome_requested = true
        end
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("settings.system.view_instructions_again"))
        
        -- Auto-start on REAPER launch
        r.ImGui_Dummy(ctx, 0, 15)
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.system.auto_start"))
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        local auto_start = Config.AUTO_START_ON_LAUNCH or false
        if r.ImGui_Checkbox(ctx, I18n.get("settings.system.auto_start_on_launch"), auto_start) then
          Config.AUTO_START_ON_LAUNCH = not auto_start
          if not data.needs_save then data.needs_save = {} end
          data.needs_save.config = true
          data.needs_save.auto_start = true  -- 标记需要更新启动脚本
        end
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("settings.system.auto_start_description"))
        
        -- Startup Actions
        r.ImGui_Dummy(ctx, 0, 10)
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.system.startup_actions"))
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        if r.ImGui_Button(ctx, I18n.get("settings.system.open_startup_actions"), 200, 32) then
          -- 打开 Startup Actions
          local found = false
          local current_script_path = debug.getinfo(1, "S").source:match("@(.*[\\//])")
          
          -- 方法 1: 使用相对路径（最可靠，因为两个脚本在同一仓库）
          if current_script_path then
            -- 从 ReaPet/ui/windows/ 到 StartupActions/
            -- 需要向上三级：../../
            local relative_paths = {
              current_script_path .. "../../../StartupActions/zyc_startup_actions.lua",
              current_script_path .. "../../StartupActions/zyc_startup_actions.lua",
              current_script_path .. "../StartupActions/zyc_startup_actions.lua",
            }
            
            for _, path in ipairs(relative_paths) do
              -- 规范化路径
              path = path:gsub("/+", "/"):gsub("\\+", "\\")
              if r.file_exists(path) then
                local cmd_id = r.AddRemoveReaScript(true, 0, path, true)
                if cmd_id and cmd_id > 0 then
                  r.Main_OnCommand(cmd_id, 0)
                  found = true
                  break
                else
                  -- 如果注册失败，尝试直接运行
                  local success = pcall(dofile, path)
                  if success then
                    found = true
                    break
                  end
                end
              end
            end
          end
          
          -- 方法 2: 通过命令 ID 查找（如果脚本已注册）
          if not found and r.kbd_getTextFromCmd then
            -- 搜索包含 "Startup Actions" 或 "startup actions" 的脚本
            for i = 32000, 33000 do
              local text = r.kbd_getTextFromCmd(i, 0)
              if text and (text:find("Startup Actions") or text:find("startup actions") or text:find("Zyc Startup")) then
                r.Main_OnCommand(i, 0)
                found = true
                break
              end
            end
          end
          
          -- 方法 3: 使用绝对路径（后备方案）
          if not found then
            local resource_path = r.GetResourcePath()
            if resource_path then
              local absolute_paths = {
                resource_path .. "/Scripts/StartupActions/zyc_startup_actions.lua",
                resource_path .. "/Scripts/zyc_startup_actions.lua",
              }
              
              for _, path in ipairs(absolute_paths) do
                if r.file_exists(path) then
                  local cmd_id = r.AddRemoveReaScript(true, 0, path, true)
                  if cmd_id and cmd_id > 0 then
                    r.Main_OnCommand(cmd_id, 0)
                    found = true
                    break
                  end
                end
              end
            end
          end
          
          if not found then
            local error_msg = "Startup Actions script not found.\n\n"
            error_msg = error_msg .. "Please ensure Startup Actions is installed via ReaPack.\n\n"
            if current_script_path then
              error_msg = error_msg .. "Current path: " .. current_script_path .. "\n"
              error_msg = error_msg .. "Tried relative: ../StartupActions/zyc_startup_actions.lua"
            end
            r.ShowMessageBox(error_msg, "Not Found", 0)
          end
        end
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("settings.system.startup_actions_description"))
        
        -- Reset Settings
        r.ImGui_Dummy(ctx, 0, 15)
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, "Reset Settings")
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Reset Preferences Button (exclude coin and skin system)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0xFF8800FF)  -- 橙色按钮
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0xFFAA00FF)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), 0xCC6600FF)
        if r.ImGui_Button(ctx, "Reset Preferences", 200, 32) then
          state.reset_preferences_requested = true
        end
        r.ImGui_PopStyleColor(ctx, 3)
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, "  Reset all settings except coins and skins")
        
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Factory Reset Button (reset everything)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0xCC3333FF)  -- 红色按钮
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0xFF4444FF)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), 0xAA2222FF)
        if r.ImGui_Button(ctx, "Factory Reset", 200, 32) then
          state.factory_reset_requested = true
        end
        r.ImGui_PopStyleColor(ctx, 3)
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, "  Reset all settings including coins and skins")
        
        -- Developer section
        r.ImGui_Dummy(ctx, 0, 15)
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, "Developer")
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Developer Mode Toggle
        local dev_mode = Config.DEVELOPER_MODE
        if r.ImGui_Checkbox(ctx, "Developer Mode", dev_mode) then
          Config.DEVELOPER_MODE = not dev_mode
          if not data.needs_save then data.needs_save = {} end
          data.needs_save.config = true
        end
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, "  Enable developer features")
        
        -- Open Dev Panel Button (only if developer mode is enabled)
        if Config.DEVELOPER_MODE then
          r.ImGui_Dummy(ctx, 0, 5)
          if r.ImGui_Button(ctx, "Open Developer Panel", 200, 32) then
            state.dev_panel_requested = true
          end
        end
        
        r.ImGui_Dummy(ctx, 0, 20)
        r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("settings.system.exit"))
        r.ImGui_Separator(ctx)
        r.ImGui_Dummy(ctx, 0, 5)
        
        -- Close Program Button
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0xCC3333FF)  -- 红色按钮
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0xFF4444FF)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), 0xAA2222FF)
        if r.ImGui_Button(ctx, I18n.get("settings.system.close_companion"), 200, 36) then
          state.close_requested = true
        end
        r.ImGui_PopStyleColor(ctx, 3)
        r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("settings.system.exit_hint"))
        
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
  
  if state.show_welcome_requested then
    state.show_welcome_requested = false
    result.show_welcome = true
  end
  
  if state.reset_preferences_requested then
    state.reset_preferences_requested = false
    result.reset_preferences = true
  end
  
  if state.factory_reset_requested then
    state.factory_reset_requested = false
    result.factory_reset = true
  end
  
  -- 传递需要保存的标志
  if data and data.needs_save then
    result.needs_save = data.needs_save
    
    -- 如果启用了自动启动，更新启动脚本
    if data.needs_save.auto_start then
      result.update_auto_start = true
      result.auto_start_enabled = Config.AUTO_START_ON_LAUNCH
    end
  end
  
  if result.open_dev_panel or result.open_skin_picker or result.close_program or result.show_welcome or result.reset_preferences or result.factory_reset or result.update_auto_start or result.needs_save then
    return result
  end
  
  return new_open
end

return Settings