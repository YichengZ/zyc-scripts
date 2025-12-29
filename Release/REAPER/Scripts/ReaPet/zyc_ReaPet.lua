-- @description Zyc ReaPet - Productivity Companion
-- @version 1.0.4.3
-- @author Yicheng Zhu (Ethan)
-- @about
--   # Zyc ReaPet
--
--   Turn your music production into a game! Zyc ReaPet is a gamified productivity
--   companion designed specifically for REAPER users.
--
--   ### Key Features
--   * **Stats Tracking**: Monitor your daily active usage and working habits.
--   * **Pomodoro Timer**: Stay focused with a built-in work/break timer system.
--   * **Pet System**: Level up your companion by being productive.
--   * **Shop & Skins**: Earn coins to unlock new skins (Cat, Dog, Bear, etc.) and items.
--
--   Stay motivated and make your mixing sessions more fun!
-- @provides
--   config.lua
--   core/*.lua
--   utils/*.lua
--   ui/**/*.lua
--   assets/**/*.png
-- @changelog
--   + v1.0.4.3: Hidden Developer Mode UI in production release
--   + v1.0.4.2: Removed auto-start on REAPER launch feature (caused crash issues)
--   + v1.0.4.2: Updated UI terminology: "Startup Actions" / "启动项设置"
--   + v1.0.4.1: Fixed data file paths to use ResourcePath/Data/ for cross-platform compatibility
--   + v1.0.4.1: Added automatic data migration from old script directory locations
--   + v1.0.4.1: Improved path handling for Windows/macOS/Linux compatibility
--   + Initial public release
--   + Added basic pet system and shop

local script_path = debug.getinfo(1, "S").source:match("@(.*[\\//])")
package.path = script_path .. "?.lua;" .. script_path .. "?/init.lua;" .. package.path

local Config = require('config')
local Tracker = require('core.tracker')
local Pomodoro = require('core.pomodoro')
local Treasure = require('core.treasure')
local CoinSystem = require('core.coin_system')
local ShopSystem = require('core.shop_system')
local PomodoroPresets = require('core.pomodoro_presets')
local SkinManager = require('ui.skins.skin_manager')
local StatsBox = require('ui.stats_box')
local MenuButton = require('ui.menu_button')
local Settings = require('ui.windows.settings')
local DevPanel = require('ui.windows.dev_panel')
local Shop = require('ui.windows.shop')
local PomodoroSettings = require('ui.windows.pomodoro_settings')
local Welcome = require('ui.windows.welcome')
local TreasureBox = require('ui.treasure_box')
local PomodoroTimer = require('ui.pomodoro_timer')
local FontManager = require('utils.font_manager')
local TransformationEffect = require('ui.transformation_effect')
local CoinEffect = require('ui.utils.coin_effect')
local ScaleManager = require('utils.scale_manager')
local I18n = require('utils.i18n')
local WindowFlags = require('utils.window_flags')

-- 本地化常用 Reaper 函数
local r = reaper
local time_precise = r.time_precise

-- ========= 初始化 =========
Config.init(script_path)

-- ========= 初始化 i18n =========
-- 注意：需要在 Config.load_from_data 之后调用，因为语言设置从 Config 读取
local function init_i18n()
  local lang = Config.LANGUAGE or "en"
  I18n.init(lang)
end

-- ========= SWS Extension Check =========
local function check_sws_extension()
  -- 检查 SWS 扩展是否安装（通过检查 SWS API 函数）
  if not r.NF_GetGlobalStartupAction and not r.CF_GetConfigPath and not r.BR_GetMediaItemByGUID then
    local msg = "SWS Extension is not installed.\n\n"
    msg = msg .. "SWS Extension is required for some features.\n\n"
    msg = msg .. "Please install SWS Extension from:\n"
    msg = msg .. "https://www.sws-extension.org/\n\n"
    msg = msg .. "Or via ReaPack: Extensions > ReaPack > Browse Packages > Search 'SWS'"
    r.ShowMessageBox(msg, "SWS Extension Required", 0)
    return false
  end
  return true
end

-- ========= ReaImGui Version Check =========
local function check_imgui_compatibility()
  -- 标准 API 检查
  if not r.ImGui_CreateContext or not r.ImGui_CreateImage or not r.ImGui_DrawList_AddTextEx then
    r.ShowMessageBox("ReaImGui outdated.", "Error", 0)
    return false
  end
  return true
end

if not check_imgui_compatibility() then return end
if not check_sws_extension() then return end

local ctx = r.ImGui_CreateContext('ReaPet')
local tracker = Tracker:new()
Config.load_from_data(tracker:get_global_stats())
init_i18n()  -- 初始化 i18n（需要在 Config.load_from_data 之后）

-- 检测首次运行（检查是否已经显示过欢迎窗口）
local function is_first_run()
  local global_stats = tracker:get_global_stats()
  if global_stats and global_stats.ui_settings then
    local show_welcome = global_stats.ui_settings.show_welcome
    if show_welcome == false then
      return false  -- 已经显示过，不再显示
    end
  end
  return true  -- 默认显示（首次运行或未设置标志）
end

FontManager.init(ctx)
Pomodoro.init()
Treasure.init(script_path)
CoinSystem.init(Config.DATA_FILE)
ShopSystem.init(Config.DATA_FILE)
local global_stats_init = tracker:get_global_stats()
PomodoroPresets.init(global_stats_init)
SkinManager.init(ctx, script_path)
TreasureBox.init()
PomodoroTimer.init()
TransformationEffect.init()
CoinEffect.init()
local pending_skin_resize = true

-- 窗口位置记忆相关变量
local window_pos_save_timer = 0
local WINDOW_POS_SAVE_INTERVAL = 1.0  -- 1秒后保存位置
local is_first_window_restore = true  -- 首次恢复窗口位置标志

Pomodoro.set_on_focus_complete(function()
  if Treasure.show then Treasure.show() end
  SkinManager.trigger("celebrate")
end)

Pomodoro.set_on_focus_skip(function()
  if Config.DEBUG_TREASURE_ON_SKIP then
    if Treasure.show then Treasure.show() end
    SkinManager.trigger("celebrate")
  end
end)

local settings_open = false
local dev_panel_open = false
local pomo_settings_open = false
local skin_picker_open = false
local welcome_open = false  -- 将在初始化后设置
local welcome_initialized = false  -- 标记是否已经初始化过欢迎窗口
local last_p_state = "idle"
local treasure_cache_initialized = false
local main_window_x, main_window_y, main_window_w, main_window_h = 0, 0, 0, 0

local last_frame_time = time_precise()
local last_save_time = time_precise()
local SAVE_INTERVAL = 5.0 
local is_data_dirty = false 

-- Tracker 节流控制
local last_tracker_time = 0
local TRACKER_UPDATE_INTERVAL = 0.2 

-- 字符串缓存变量
local cached_time_str = "--:--"
local last_cached_seconds = -1

-- 窗口标志（现在使用动态生成，见 WindowFlags.get_main_window_flags()）
-- 保留此变量用于向后兼容，但实际使用 WindowFlags.get_main_window_flags()
local WINDOW_FLAGS = nil  -- 将在主循环中动态生成

-- 预定义上下文表 (GC 优化)
local settings_ctx = {}
local shop_ctx = {}
local pomo_settings_ctx = {}

-- ========= 原子性保存函数 =========
-- 一次性保存所有数据，避免竞态条件
local function SaveAllDataAtomic()
  local json = require('utils.json')
  local DATA_FILE = Config.DATA_FILE
  
  if not DATA_FILE then
    local Debug = require('utils.debug')
    Debug.log("SaveAllDataAtomic: DATA_FILE is nil\n")
    return
  end
  
  -- 加载现有数据（如果存在）
  local data = {}
  local file = io.open(DATA_FILE, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local ok, loaded = pcall(json.decode, content)
    if ok and type(loaded) == "table" then
      data = loaded
    end
  end
  
  -- 一次性更新所有数据
  local global_stats = tracker:get_global_stats()
  
  -- 先更新 Config 到 global_stats.ui_settings（确保窗口位置等配置被保存）
  Config.save_to_data(global_stats)
  
  -- 更新 global_stats 字段（使用白名单机制，避免覆盖coin_system和shop_system）
  -- 注意：字段列表与 core/tracker.lua 中的 GLOBAL_STATS_FIELDS 保持一致
  local global_fields = {
    "total_operations", "total_time", "active_time", "global_undo_count",
    "projects", "plugin_cache", "treasure_box", "pomo_presets",
    "ui_settings", "operations_by_action", "total_focus_sessions",
    "total_focus_time", "schemaVersion"
  }
  for _, key in ipairs(global_fields) do
    if global_stats[key] ~= nil then
      data[key] = global_stats[key]
    end
  end
  
  -- 特殊处理 schemaVersion（如果没有则设置默认值）
  if not data.schemaVersion then
    data.schemaVersion = global_stats.schemaVersion or 1
  end
  
  -- 更新 coin_system
  data.coin_system = CoinSystem.get_state()
  
  -- 更新 shop_system
  data.shop_system = ShopSystem.get_state()
  
  -- 一次性保存所有数据
  local ok, json_str = pcall(json.encode, data)
  if ok then
    local file = io.open(DATA_FILE, "w+")
    if file then
      file:write(json_str)
      file:close()
    end
  end
  
  -- 保存工程数据（RPP扩展属性）
  tracker:save_current_project_stats()
end

-- ========= 兼容性保存函数（保留旧接口）=========
local function SaveAllData()
  -- 使用原子性保存函数
  SaveAllDataAtomic()
  
  -- 更新Config中的ui_settings（内存中）
  local global_stats = tracker:get_global_stats()
  Config.save_to_data(global_stats)
end

local function IncrementOperations()
  local project_stats = tracker:get_project_stats()
  local global_stats = tracker:get_global_stats()
  global_stats.total_operations = (global_stats.total_operations or 0) + 1
  project_stats.actions = (project_stats.actions or 0) + 1
  is_data_dirty = true
  SkinManager.trigger("tap", true)
end

-- ========= 主循环 =========
local function Loop()
  local now = time_precise()
  local dt = now - last_frame_time
  last_frame_time = now
  if dt > 0.1 then dt = 0.1 end
  if dt < 0.001 then dt = 0.001 end

  -- 首次运行检查：只在第一次循环时检查
  if not welcome_initialized then
    welcome_initialized = true
    welcome_open = is_first_run()
    if welcome_open then
      -- 确保 tracker 被传递给欢迎窗口上下文
      -- 这个会在后面设置
    end
  end

  -- [Tracker 节流]
  local operation_triggered = false
  if now - last_tracker_time > TRACKER_UPDATE_INTERVAL then
    operation_triggered = tracker:update()
    last_tracker_time = now
  end

  local global_stats = tracker:get_global_stats()
  Pomodoro.update(global_stats)
  
  if not treasure_cache_initialized and Treasure.init_plugin_cache then
    Treasure.init_plugin_cache(global_stats)
    treasure_cache_initialized = true
  end

  local current_p_state = Pomodoro.get_state()
  if current_p_state ~= last_p_state then
    PomodoroTimer.trigger_switch()
    last_p_state = current_p_state
  end

  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowBorderSize(), 0)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 0, 0)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), 0x00000000)  -- 透明背景
  
  if SkinManager.consume_layout_dirty() then pending_skin_resize = true end
  local base_w, base_h = SkinManager.get_recommended_size()
  
  -- 恢复窗口位置（仅在首次）
  local has_saved_window = false
  if is_first_window_restore then
    is_first_window_restore = false
    
    -- 如果启用停靠，让 REAPER 自动管理窗口位置（包括停靠状态）
    -- 注意：即使 Config.WINDOW_DOCKED = true，也不要在初始化时跳过位置设置
    -- 因为 REAPER 会在窗口真正停靠后自动恢复停靠位置
    if Config.ENABLE_DOCKING then
      -- 启用停靠时，不设置窗口位置，让 REAPER 自动处理
      -- REAPER 会自动恢复停靠窗口的位置和状态
      has_saved_window = false
    else
      -- 未启用停靠时，恢复浮动窗口的位置
      local saved_pos = Config.MAIN_WINDOW_POS
      if saved_pos and saved_pos.x and saved_pos.y then
        -- 检查位置是否有效（在多显示器环境中，位置可能在 -10000 到 10000 之间）
        if saved_pos.x > -10000 and saved_pos.x < 10000 and 
           saved_pos.y > -10000 and saved_pos.y < 10000 then
          r.ImGui_SetNextWindowPos(ctx, saved_pos.x, saved_pos.y, r.ImGui_Cond_FirstUseEver())
          if saved_pos.w and saved_pos.h and saved_pos.w > 0 and saved_pos.h > 0 then
            r.ImGui_SetNextWindowSize(ctx, saved_pos.w, saved_pos.h, r.ImGui_Cond_FirstUseEver())
            has_saved_window = true  -- 标记已恢复保存的窗口大小
          end
        end
      end
    end
  end
  
  -- 只有在没有恢复保存的窗口大小时，才设置默认大小
  if not has_saved_window then
    if pending_skin_resize then
      r.ImGui_SetNextWindowSize(ctx, base_w, base_h, r.ImGui_Cond_Always())
      pending_skin_resize = false
    else
      r.ImGui_SetNextWindowSize(ctx, base_w, base_h, r.ImGui_Cond_FirstUseEver())
    end
  else
    -- 如果有保存的窗口大小，清除 pending_skin_resize 标志
    pending_skin_resize = false
  end
  
  -- 动态生成窗口标志（根据停靠配置）
  local window_flags = WindowFlags.get_main_window_flags()
  
  local visible, open = r.ImGui_Begin(ctx, 'ReaPet', true, window_flags)
  local floor_y_absolute = nil 

  if visible then
    local wx, wy = r.ImGui_GetWindowPos(ctx)
    local w, h = r.ImGui_GetWindowSize(ctx)
    local dl = r.ImGui_GetWindowDrawList(ctx)
    
    main_window_x, main_window_y = wx, wy
    main_window_w, main_window_h = w, h
    
    ScaleManager.update(w, h, base_w, base_h)
    local scale = ScaleManager.get()
    
    -- 检测停靠状态（仅在启用停靠时检测）
    if Config.ENABLE_DOCKING then
      -- 使用 ImGui_GetWindowDockID 检测停靠状态
      -- 如果返回非零值，说明窗口已停靠
      local dock_id = 0
      if r.ImGui_GetWindowDockID then
        dock_id = r.ImGui_GetWindowDockID(ctx) or 0
      end
      local is_docked = (dock_id ~= 0)
      
      -- 如果停靠状态改变，更新配置并检测停靠位置
      if is_docked ~= Config.WINDOW_DOCKED then
        Config.WINDOW_DOCKED = is_docked
        is_data_dirty = true
        
        -- 检测停靠位置（仅在刚停靠时检测）
        if is_docked then
          -- 简化实现：根据窗口宽高比判断停靠方向
          -- 不依赖屏幕尺寸，只根据窗口本身的尺寸比例
          local aspect_ratio = w / h
          if aspect_ratio < 0.8 then
            -- 窗口较窄（高>宽），可能是左右停靠
            -- 根据窗口X坐标判断：如果X坐标较小，可能是左侧；否则可能是右侧
            -- 简化：使用窗口X坐标的绝对值判断（左侧通常X较小，右侧X较大）
            if wx < 500 then  -- 阈值：如果窗口X坐标小于500，认为是左侧
              Config.DOCK_POSITION = "left"
            else
              Config.DOCK_POSITION = "right"
            end
          elseif aspect_ratio > 1.5 then
            -- 窗口较宽（宽>高），可能是上下停靠
            -- 根据窗口Y坐标判断：如果Y坐标较小，可能是顶部；否则可能是底部
            if wy < 500 then  -- 阈值：如果窗口Y坐标小于500，认为是顶部
              Config.DOCK_POSITION = "top"
            else
              Config.DOCK_POSITION = "bottom"
            end
          else
            -- 宽高比接近1:1，无法确定具体方向，保持 nil
            Config.DOCK_POSITION = nil
          end
          is_data_dirty = true
        else
          -- 取消停靠，清除位置记忆
          Config.DOCK_POSITION = nil
          is_data_dirty = true
        end
      end
    end
    
    -- 保存窗口位置（仅在非停靠状态下保存）
    if not Config.WINDOW_DOCKED then
      window_pos_save_timer = window_pos_save_timer + dt
      if window_pos_save_timer > WINDOW_POS_SAVE_INTERVAL then
        -- 确保缩放值有效（ScaleManager已初始化）
        if scale and scale > 0 then
          Config.MAIN_WINDOW_POS.x = wx
          Config.MAIN_WINDOW_POS.y = wy
          Config.MAIN_WINDOW_POS.w = w
          Config.MAIN_WINDOW_POS.h = h
          Config.MAIN_WINDOW_POS.scale = scale
          is_data_dirty = true  -- 标记数据需要保存
        end
        window_pos_save_timer = 0
      end
    end
    
    local mx, my = r.GetMousePosition()
    if r.ImGui_PointConvertNative then mx, my = r.ImGui_PointConvertNative(ctx, mx, my, false) end
    local is_window_hovered = r.ImGui_IsWindowHovered(ctx)
    
    local treasure_available = Treasure.is_available and Treasure.is_available() or false
    local is_treasure_opening = TreasureBox.is_opening and TreasureBox.is_opening() or false

    local char_state = 'idle'
    if current_p_state == 'focus' then char_state = 'focus'
    elseif current_p_state == 'break' then char_state = 'break' end
    
    if operation_triggered then SkinManager.trigger("tap") end
    
    SkinManager.update(dt, char_state, ctx)
    SkinManager.draw(ctx, dl, wx, wy, w, h, char_state, true)
    local skin_rect = SkinManager.get_draw_rect()
    
    local stats_interaction = nil
    if Config.SHOW_GLOBAL_STATS then
      StatsBox.update(dt)
      stats_interaction = StatsBox.draw(ctx, dl, wx, wy, w, h, tracker, scale, skin_rect, Config.STATS_BOX_SCALE, Config.STATS_BOX_OFFSET_X, Config.STATS_BOX_OFFSET_Y)
      
      if stats_interaction then
        local click_result = StatsBox.handle_click(ctx, stats_interaction)
        if click_result == "box_clicked" then
          IncrementOperations() 
        end
      end
    end
    
    SkinManager.draw_paws(ctx, dl, wx, wy, w, h)

    local menu_interaction = nil
    if skin_rect then
      local base_scale = skin_rect.scale or scale
      local cat_cx = skin_rect.min_x + skin_rect.draw_w * 0.5
      local cat_cy = skin_rect.min_y + skin_rect.draw_h * 0.65
      
      local menu_x = cat_cx + (90 + 8 + 230) * base_scale
      local menu_y = cat_cy + (18 + 22 + 8 + 100) * base_scale
      local menu_size = 120 * base_scale
      
      menu_interaction = MenuButton.draw(ctx, dl, menu_x, menu_y, menu_size, base_scale)
    end
    
    MenuButton.update(dt) 
    
    if menu_interaction and MenuButton.handle_click(ctx, menu_interaction) then
      skin_picker_open = not skin_picker_open
    end
    
    local t_cfg = Config.TREASURE_BOX
    local actual_scale = scale
    
    local base_cx, base_cy
    if skin_rect and skin_rect.min_x then
      base_cx = skin_rect.min_x + skin_rect.draw_w * 0.5
      base_cy = skin_rect.min_y + skin_rect.draw_h * 0.65
      if skin_rect.scale then actual_scale = skin_rect.scale end
    else
      base_cx = wx + w * 0.5
      base_cy = wy + h * 0.65
    end
    
    local tw = t_cfg.width * actual_scale
    local th = t_cfg.height * actual_scale
    local tx = base_cx + (t_cfg.offset_x * actual_scale) - (tw * 0.5)
    local ty = base_cy + (t_cfg.offset_y * actual_scale) - (th * 0.5)
    
    local treasure_center_x = tx + tw * 0.5
    local treasure_center_y = ty + th * 0.5

    local is_treasure_hovered = false
    local should_draw_treasure = (treasure_available or is_treasure_opening) and Config.SHOW_TREASURE_BOX
    
    if should_draw_treasure then
      TreasureBox.update(dt)
      is_treasure_opening = TreasureBox.is_opening and TreasureBox.is_opening() or false
      
      if is_treasure_opening then
        TreasureBox.draw(dl, tx, ty, tw, th, false)
      elseif treasure_available then
        is_treasure_hovered = TreasureBox.is_point_inside and 
                              TreasureBox.is_point_inside(mx, my, tx, ty, tw, th, false) or false
        
        TreasureBox.draw(dl, tx, ty, tw, th, is_treasure_hovered)
        
        if is_window_hovered and is_treasure_hovered then
          r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_Hand())
          if r.ImGui_IsMouseClicked(ctx, 0) then
            local focus_duration_minutes = Pomodoro.get_focus_duration() / 60
            local balance_before = CoinSystem.get_balance()
            local success, coins_earned, message = CoinSystem.reward_focus(focus_duration_minutes)
            
            if coins_earned > 0 then
              CoinEffect.trigger(treasure_center_x, treasure_center_y, coins_earned, balance_before, scale)
            end
            
            TreasureBox.trigger_open(tx, ty, tw, th, coins_earned)
            if Treasure.hide then Treasure.hide() end
            SkinManager.trigger("celebrate")
            is_data_dirty = true
          end
        end
      end
    end
    
    local collect_target_x, collect_target_y
    if menu_interaction and menu_interaction.center_x then
      collect_target_x = menu_interaction.center_x
      collect_target_y = menu_interaction.center_y
    else
      collect_target_x = wx + 228 * scale
      collect_target_y = wy + 171 * scale
    end
    
    if skin_rect and skin_rect.min_y then
       floor_y_absolute = skin_rect.min_y + skin_rect.draw_h
    else
       floor_y_absolute = wy + h
    end
    
    CoinEffect.update(dt, treasure_center_x, treasure_center_y, w, h, wx, wy, collect_target_x, collect_target_y, floor_y_absolute)
    CoinEffect.draw(ctx, dl)
    
    if TransformationEffect and TransformationEffect.update then
        TransformationEffect.update(dt)
    end
    
    local is_p_hovered = false
    if Config.SHOW_POMODORO then
      local p_cfg = Config.POMODORO_TIMER
      local timer_scale_mult = Config.TIMER_SCALE or 1.0
      local pw, ph = p_cfg.width * scale * timer_scale_mult, p_cfg.height * scale * timer_scale_mult
      local px = wx + w - pw - (p_cfg.margin_right * scale)
      local py = wy + (p_cfg.margin_top * scale)
      
      is_p_hovered = PomodoroTimer.is_hovered(mx, my, px, py, pw, ph)
      PomodoroTimer.update(dt, current_p_state, is_p_hovered)
      
      -- [优化] 字符串缓存
      if current_p_state ~= "idle" then
        local remaining = Pomodoro.get_remaining_time()
        local remaining_int = math.floor(remaining)
        if remaining_int ~= last_cached_seconds then
             local m = math.floor(remaining_int / 60)
             local s = remaining_int % 60
             cached_time_str = string.format("%02d:%02d", m, s)
             last_cached_seconds = remaining_int
        end
      else
        cached_time_str = "--:--"
        last_cached_seconds = -1
      end
      
      PomodoroTimer.draw(ctx, dl, px, py, pw, ph, is_p_hovered, current_p_state, cached_time_str, Pomodoro.get_progress(), Pomodoro.is_paused())
      
      if is_window_hovered and is_p_hovered then
        r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_Hand())
        if r.ImGui_IsMouseClicked(ctx, 0) then
          PomodoroTimer.trigger_click()
          IncrementOperations() 
          if current_p_state == "idle" then
            Pomodoro.start_focus()
          else
            Pomodoro.toggle_pause()
          end
        end
        if r.ImGui_IsMouseClicked(ctx, 1) then
          pomo_settings_open = not pomo_settings_open
        end
      end
    end
    
    local is_ui_active = is_p_hovered or is_treasure_hovered or (stats_interaction and stats_interaction.box_hovered) or (menu_interaction and menu_interaction.hovered)
    
    if is_window_hovered and not is_ui_active then
      if r.ImGui_IsMouseClicked(ctx, 0) then
        IncrementOperations() 
      elseif r.ImGui_IsMouseDown(ctx, 0) then
        if r.ImGui_IsMouseDragging(ctx, 0) then
          local dx, dy = r.ImGui_GetMouseDelta(ctx)
          r.ImGui_SetWindowPos(ctx, wx + dx, wy + dy)
        end
      end
    end
    
    if is_window_hovered and r.ImGui_IsMouseClicked(ctx, 1) and not is_ui_active then
       settings_open = not settings_open
    end
    
    if TransformationEffect and TransformationEffect.is_active and TransformationEffect.is_active() then
      TransformationEffect.draw(ctx, dl)
    end
  end
  
  r.ImGui_End(ctx)
  r.ImGui_PopStyleColor(ctx)
  r.ImGui_PopStyleVar(ctx, 2)
  
  if settings_open then
    -- [优化] 复用 settings_ctx 表
    settings_ctx.tracker = tracker
    settings_ctx.pomodoro = Pomodoro
    settings_ctx.treasure = Treasure
    settings_ctx.skin_manager = SkinManager
    settings_ctx.main_x = main_window_x
    settings_ctx.main_y = main_window_y
    settings_ctx.main_w = main_window_w
    settings_ctx.main_h = main_window_h
    
    local result = Settings.draw(ctx, settings_open, settings_ctx)
    if type(result) == "table" then
      if result.open ~= nil then settings_open = result.open end
      -- 只在开发者模式下允许打开 dev panel
      if result.open_dev_panel and Config.DEVELOPER_MODE then 
        dev_panel_open = true 
      end
      if result.open_skin_picker then skin_picker_open = true end
      if result.show_welcome then
        -- 从设置页面请求显示欢迎窗口
        welcome_open = true
      end
      if result.close_program then
        -- 关闭程序：保存数据并退出循环
        SaveAllData()
        tracker:on_exit()
        open = false  -- 退出主循环
      end
      
      -- 处理重置偏好设置（不包括金币和皮肤）
      if result.reset_preferences then
        -- 重置 Config 到默认值（不包括金币和皮肤系统）
        Config.reset_to_defaults()
        -- 保存配置
        local global_stats = tracker:get_global_stats()
        Config.save_to_data(global_stats)
        SaveAllDataAtomic()
        r.ShowMessageBox(I18n.get("settings.system.reset_preferences_complete"), I18n.get("settings.system.reset_complete_title"), 0)
      end
      
      -- 处理恢复出厂设置（包括所有内容）
      if result.factory_reset then
        -- 重置 Config 到默认值
        Config.reset_to_defaults()
        -- 重置金币系统
        CoinSystem.reset()
        -- 重置商店系统
        ShopSystem.reset()
        -- 重置皮肤为默认
        Config.CURRENT_SKIN_ID = "cat_base"
        -- 保存所有数据
        local global_stats = tracker:get_global_stats()
        Config.save_to_data(global_stats)
        SaveAllDataAtomic()
        r.ShowMessageBox(I18n.get("settings.system.factory_reset_complete"), I18n.get("settings.system.factory_reset_complete_title"), 0)
      end
      
      -- 检查是否需要保存配置
      if result.needs_save and result.needs_save.config then
        is_data_dirty = true
      end
      
    elseif type(result) == "boolean" then
      settings_open = result
    end
  end
  
  if skin_picker_open then
    -- [优化] 复用 shop_ctx 表
    shop_ctx.tracker = tracker
    shop_ctx.script_path = script_path
    shop_ctx.main_window_x = main_window_x
    shop_ctx.main_window_y = main_window_y
    shop_ctx.main_window_w = main_window_w
    shop_ctx.main_window_h = main_window_h
    shop_ctx.floor_y = floor_y_absolute
    
    skin_picker_open = Shop.draw(ctx, skin_picker_open, shop_ctx)
  end

  -- Dev Panel 只在开发者模式显示
  if dev_panel_open and Config.DEVELOPER_MODE then 
    local dev_panel_data = {
      welcome_open = welcome_open,
      tracker = tracker,
      save_data = function()
        -- 保存数据的函数
        SaveAllData()
        is_data_dirty = false  -- 标记已保存
      end
    }
    DevPanel.draw(ctx, dev_panel_open, dev_panel_data)
    
    -- 检查 dev panel 是否修改了 welcome_open
    if dev_panel_data.welcome_open ~= nil then
      welcome_open = dev_panel_data.welcome_open
    end
    
    -- 如果强制显示，重置标志并立即显示
    if dev_panel_data.force_show_welcome then
      local global_stats = tracker:get_global_stats()
      if not global_stats.ui_settings then
        global_stats.ui_settings = {}
      end
      global_stats.ui_settings.show_welcome = nil  -- 清除标志，允许下次启动时显示
      welcome_open = true  -- 立即显示欢迎窗口
      SaveAllData()  -- 立即保存
      is_data_dirty = false
      dev_panel_data.force_show_welcome = false
    end
  elseif dev_panel_open and not Config.DEVELOPER_MODE then
    dev_panel_open = false  -- 如果开发者模式关闭，自动关闭 dev panel
  end
  
  if pomo_settings_open then
    -- [优化] 复用 pomo_settings_ctx 表
    pomo_settings_ctx.pomodoro = Pomodoro
    pomo_settings_ctx.tracker = tracker
    pomo_settings_ctx.current_p_state = current_p_state
    pomo_settings_ctx.main_window_x = main_window_x
    pomo_settings_ctx.main_window_y = main_window_y
    pomo_settings_ctx.main_window_w = main_window_w
    pomo_settings_ctx.main_window_h = main_window_h
    
    pomo_settings_open = PomodoroSettings.draw(ctx, pomo_settings_open, pomo_settings_ctx)
  end
  
  if welcome_open then
    local welcome_ctx = {
      main_x = main_window_x,
      main_y = main_window_y,
      main_w = main_window_w,
      main_h = main_window_h,
      tracker = tracker -- 传递 tracker 以便保存状态
    }
    welcome_open = Welcome.draw(ctx, welcome_open, welcome_ctx)
    
    -- 如果用户关闭了欢迎窗口，保存标志
    if not welcome_open then
      local global_stats = tracker:get_global_stats()
      if not global_stats.ui_settings then
        global_stats.ui_settings = {}
      end
      global_stats.ui_settings.show_welcome = false
      is_data_dirty = true  -- 标记数据需要保存
      SaveAllData() -- 立即保存，确保标志被持久化
    end
  end
  
  if is_data_dirty and (now - last_save_time > SAVE_INTERVAL) then
    SaveAllData()
    last_save_time = now
    is_data_dirty = false
  end
  
  if open then
    r.defer(Loop) 
  else 
    SaveAllData()
    tracker:on_exit() 
  end
end

r.defer(Loop)
r.atexit(function() 
  SaveAllData()
  tracker:on_exit()
end)