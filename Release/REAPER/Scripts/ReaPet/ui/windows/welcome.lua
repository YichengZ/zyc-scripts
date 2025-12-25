--[[
  REAPER Companion - 欢迎窗口
  首次运行时显示教程和功能介绍
  支持多语言：英文、中文、韩文、日文
--]]

local Welcome = {}
local Config = require('config')
local I18n = require('ui.windows.welcome_i18n')

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

-- 语言状态（默认英文）
local current_lang = "en"

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
  r.ImGui_SetNextWindowSize(ctx, 500, 780, r.ImGui_Cond_FirstUseEver())
  
  local flags = r.ImGui_WindowFlags_NoTitleBar() | r.ImGui_WindowFlags_NoScrollbar()
  local visible, new_open = r.ImGui_Begin(ctx, "Welcome to ReaPet!##Window", true, flags)
  
  if visible then
    -- 语言选择标签页
    if r.ImGui_BeginTabBar(ctx, "LanguageTabs") then
      local languages = I18n.get_languages()
      for _, lang in ipairs(languages) do
        local lang_name = I18n.get_language_name(lang)
        if r.ImGui_BeginTabItem(ctx, lang_name) then
          current_lang = lang
          r.ImGui_EndTabItem(ctx)
        end
      end
      r.ImGui_EndTabBar(ctx)
    end
    
    r.ImGui_Dummy(ctx, 0, 10)
    
    -- 标题
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), COL.HEADER_TEXT)
    if r.ImGui_SetWindowFontScale then
      r.ImGui_SetWindowFontScale(ctx, 1.5)
    end
    r.ImGui_Text(ctx, I18n.get(current_lang, "title"))
    if r.ImGui_SetWindowFontScale then
      r.ImGui_SetWindowFontScale(ctx, 1.0)
    end
    r.ImGui_PopStyleColor(ctx)
    
    r.ImGui_Dummy(ctx, 0, 10)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "subtitle"))
    r.ImGui_Dummy(ctx, 0, 20)
    
    -- 分隔线
    r.ImGui_Separator(ctx)
    r.ImGui_Dummy(ctx, 0, 15)
    
    -- 教程内容
    r.ImGui_TextColored(ctx, COL.HEADER_TEXT, I18n.get(current_lang, "quick_guide"))
    r.ImGui_Dummy(ctx, 0, 10)
    
    -- 1. 统计数字
    r.ImGui_BulletText(ctx, I18n.get(current_lang, "stats_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "stats_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "stats_2"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 2. 计时器
    r.ImGui_BulletText(ctx, I18n.get(current_lang, "timer_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "timer_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "timer_2"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 3. 宝箱
    r.ImGui_BulletText(ctx, I18n.get(current_lang, "treasure_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "treasure_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "treasure_2"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 4. 金币
    r.ImGui_BulletText(ctx, I18n.get(current_lang, "coins_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "coins_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "coins_2"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "coins_3"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 5. 商店
    r.ImGui_BulletText(ctx, I18n.get(current_lang, "shop_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "shop_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "shop_2"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "shop_3"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 8)
    
    -- 6. 设置
    r.ImGui_BulletText(ctx, I18n.get(current_lang, "settings_title"))
    r.ImGui_Indent(ctx, 20)
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "settings_1"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "settings_2"))
    r.ImGui_Unindent(ctx, 20)
    r.ImGui_Dummy(ctx, 0, 15)
    
    -- 分隔线
    r.ImGui_Separator(ctx)
    r.ImGui_Dummy(ctx, 0, 15)
    
    -- 首次奖励提示
    r.ImGui_TextColored(ctx, COL.ACCENT, I18n.get(current_lang, "bonus_title"))
    r.ImGui_TextColored(ctx, COL.TEXT_DIM, I18n.get(current_lang, "bonus_subtitle"))
    r.ImGui_Dummy(ctx, 0, 20)
    
    -- 按钮
    local btn_w = 200
    local btn_h = 40
    local window_w = r.ImGui_GetWindowWidth(ctx)
    r.ImGui_SetCursorPosX(ctx, (window_w - btn_w) * 0.5)
    
    if r.ImGui_Button(ctx, I18n.get(current_lang, "button"), btn_w, btn_h) then
      new_open = false
    end
    
    r.ImGui_End(ctx)
  end
  
  r.ImGui_PopStyleColor(ctx, 6)
  r.ImGui_PopStyleVar(ctx, 4)
  
  return new_open
end

return Welcome
