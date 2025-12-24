-- @description REAPER companion app with stats tracking, pomodoro timer, treasure box system, and multiple character skins
-- @author Yicheng Zhu (Ethan)
-- @version 1.0.1
-- @provides
--   [main=main] zyc_ReaPet.lua
--   config.lua
--   core/*.lua
--   utils/*.lua
--   ui/**/*.lua
--   assets/**/*.png

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
local TreasureBox = require('ui.treasure_box')
local PomodoroTimer = require('ui.pomodoro_timer')
local FontManager = require('utils.font_manager')
local TransformationEffect = require('ui.transformation_effect')
local CoinEffect = require('ui.utils.coin_effect')
local ScaleManager = require('utils.scale_manager')

-- 本地化常用 Reaper 函数
local r = reaper
local time_precise = r.time_precise

-- ========= 初始化 =========
Config.init(script_path)

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

local ctx = r.ImGui_CreateContext('ReaPet')
local tracker = Tracker:new()
Config.load_from_data(tracker:get_global_stats())

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

-- 预定义 Window Flags
local WINDOW_FLAGS = r.ImGui_WindowFlags_NoTitleBar() | 
                     r.ImGui_WindowFlags_NoScrollbar() |
                     r.ImGui_WindowFlags_TopMost()

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
    r.ShowConsoleMsg("SaveAllDataAtomic: DATA_FILE is nil\n")
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
  
  if pending_skin_resize then
    r.ImGui_SetNextWindowSize(ctx, base_w, base_h, r.ImGui_Cond_Always())
    pending_skin_resize = false
  else
    r.ImGui_SetNextWindowSize(ctx, base_w, base_h, r.ImGui_Cond_FirstUseEver())
  end
  
  local visible, open = r.ImGui_Begin(ctx, 'ReaPet', true, WINDOW_FLAGS)
  local floor_y_absolute = nil 

  if visible then
    local wx, wy = r.ImGui_GetWindowPos(ctx)
    local w, h = r.ImGui_GetWindowSize(ctx)
    local dl = r.ImGui_GetWindowDrawList(ctx)
    
    main_window_x, main_window_y = wx, wy
    main_window_w, main_window_h = w, h
    
    ScaleManager.update(w, h, base_w, base_h)
    local scale = ScaleManager.get()
    
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
      if result.close_program then
        -- 关闭程序：保存数据并退出循环
        SaveAllData()
        tracker:on_exit()
        open = false  -- 退出主循环
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
    DevPanel.draw(ctx, dev_panel_open) 
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