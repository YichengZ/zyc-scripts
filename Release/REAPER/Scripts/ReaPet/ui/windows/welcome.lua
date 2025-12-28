--[[
  REAPER Companion - 欢迎窗口
  首次运行时显示教程和功能介绍
  支持多语言：英文、中文、韩文、日文
--]]

local Welcome = {}
local Config = require('config')
local I18n = require('utils.i18n')

-- 颜色定义（参考 Settings 窗口）
local COL = {
  BG = 0x2A2A2AFF,
  FRAME_BG = 0x3A3A3AFF,
  FRAME_HOVER = 0x4A4A3AFF,
  FRAME_ACTIVE = 0x4ECDC4FF,
  BTN = 0x4D9FFFFF,
  BTN_HOVER = 0x5DAFFFFF,
  BTN_ACTIVE = 0x3D8FEFFF,
  TEXT = 0xE6E6E6FF,
  TEXT_DIM = 0xCCCCCCFF,
  HEADER_TEXT = 0xFFD700FF,  -- 金色标题
  ACCENT = 0x4ECDC4FF,        -- 强调色
}

-- ========= 绘制函数 =========
function Welcome.draw(ctx, open, data)
  if not open then return false end
  
  local r = reaper
  
  -- 样式设置
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), 12.0)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 20, 20)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 8.0)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 0.5, 0.5)
  
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), COL.BG)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), COL.FRAME_BG)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), COL.BTN)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), COL.BTN_HOVER)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), COL.BTN_ACTIVE)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), COL.TEXT)
  
  -- 窗口位置：主窗口右侧（和 shop 一样的位置）
  if data.main_x and data.main_y and data.main_w then
    local welcome_w = 500
    local target_x = data.main_x + data.main_w + 10  -- 主窗口右侧，间距10
    local target_y = data.main_y
    r.ImGui_SetNextWindowPos(ctx, target_x, target_y, r.ImGui_Cond_Appearing())
  end
  
  -- 窗口尺寸（确保能装下所有内容包括按钮）
  r.ImGui_SetNextWindowSize(ctx, 500, 850, r.ImGui_Cond_FirstUseEver())
  
  local flags = r.ImGui_WindowFlags_NoTitleBar() | r.ImGui_WindowFlags_NoScrollbar()
  local visible, new_open = r.ImGui_Begin(ctx, "Welcome to ReaPet!##Window", true, flags)
  
  if visible then
    -- 语言选择器（顶部）- 使用图标和代码让用户一眼识别
    r.ImGui_SetNextItemWidth(ctx, 200)
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
    
    local changed_lang, new_lang_idx = r.ImGui_Combo(ctx, "🌐##welcome_language_combo", current_lang_idx, table.concat(lang_display, "\0") .. "\0", #lang_display)
    if changed_lang and new_lang_idx >= 0 and new_lang_idx < #supported_langs then
      local selected_lang = supported_langs[new_lang_idx + 1]
      Config.LANGUAGE = selected_lang
      I18n.set_language(selected_lang)
      -- 保存语言设置
      if data.tracker then
        local global_stats = data.tracker:get_global_stats()
        Config.save_to_data(global_stats)
        data.tracker:save_global_data()
      end
    end
    
    r.ImGui_Dummy(ctx, 0, 10)
    
    -- 标题
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), COL.HEADER_TEXT)
    if r.ImGui_SetWindowFontScale then
      r.ImGui_SetWindowFontScale(ctx, 1.5)
    end
    r.ImGui_Text(ctx, I18n.get("welcome.title"))
    if r.ImGui_SetWindowFontScale then
      r.ImGui_SetWindowFontScale(ctx, 1.0)
    end
    r.ImGui_PopStyleColor(ctx)
    
    r.ImGui_Dummy(ctx, 0, 10)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.subtitle"))
    r.ImGui_Dummy(ctx, 0, 20)
    
    -- 分隔线
    r.ImGui_Separator(ctx)
    r.ImGui_Dummy(ctx, 0, 15)
    
    -- 教程内容
    r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get("welcome.quick_guide"))
    r.ImGui_Dummy(ctx, 0, 10)
    
    -- 1. 统计数字
    r.ImGui_BulletText(ctx, I18n.get("welcome.stats_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.stats_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.stats_2"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 2. 计时器
    r.ImGui_BulletText(ctx, I18n.get("welcome.timer_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.timer_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.timer_2"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 3. 宝箱
    r.ImGui_BulletText(ctx, I18n.get("welcome.treasure_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.treasure_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.treasure_2"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 4. 金币
    r.ImGui_BulletText(ctx, I18n.get("welcome.coins_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.coins_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.coins_2"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.coins_3"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.coins_4"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 5. 商店
    r.ImGui_BulletText(ctx, I18n.get("welcome.shop_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.shop_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.shop_2"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.shop_3"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 6. 设置
    r.ImGui_BulletText(ctx, I18n.get("welcome.settings_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.settings_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.settings_2"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 7. Startup Actions
    r.ImGui_BulletText(ctx, I18n.get("welcome.startup_actions_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.startup_actions_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.startup_actions_2"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.startup_actions_3"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 10)
    
    -- Startup Actions 按钮
    local startup_btn_w = 220
    local startup_btn_h = 32
    local window_w = r.ImGui_GetWindowWidth(ctx)
    r.ImGui_SetCursorPosX(ctx, (window_w - startup_btn_w) * 0.5)
    
    if r.ImGui_Button(ctx, I18n.get("welcome.startup_actions_button"), startup_btn_w, startup_btn_h) then
      -- 打开 Startup Actions
      local resource_path = r.GetResourcePath()
      if resource_path then
        local possible_paths = {
          resource_path .. "/Scripts/StartupActions/zyc_startup_actions.lua",
          resource_path .. "/Scripts/zyc_startup_actions.lua",
        }
        
        local found_path = nil
        for _, path in ipairs(possible_paths) do
          if r.file_exists(path) then
            found_path = path
            break
          end
        end
        
        if found_path then
          local cmd_id = r.AddRemoveReaScript(true, 0, found_path, true)
          if cmd_id and cmd_id > 0 then
            r.Main_OnCommand(cmd_id, 0)
          else
            pcall(dofile, found_path)
          end
        else
          r.ShowMessageBox("Startup Actions script not found.\n\nPlease ensure Startup Actions is installed via ReaPack.", "Not Found", 0)
        end
      end
    end
    
    r.ImGui_Dummy(ctx, 0, 15)
    
    -- 分隔线
    r.ImGui_Separator(ctx)
    r.ImGui_Dummy(ctx, 0, 15)
    
    -- 首次奖励提示
    r.ImGui_TextColored(ctx, COL.ACCENT, I18n.get("welcome.bonus_title"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get("welcome.bonus_subtitle"))
    r.ImGui_Dummy(ctx, 0, 20)
    
    -- 按钮
    local btn_w = 200
    local btn_h = 40
    r.ImGui_SetCursorPosX(ctx, (window_w - btn_w) * 0.5)
    
    if r.ImGui_Button(ctx, I18n.get("welcome.button"), btn_w, btn_h) then
      new_open = false
    end
    
    r.ImGui_End(ctx)
  end
  
  r.ImGui_PopStyleColor(ctx, 6)
  r.ImGui_PopStyleVar(ctx, 4)
  
  return new_open
end

return Welcome
