--[[
  REAPER Companion - 开发者面板
  用于实时调整 UI 元素的位置和大小
--]]

local DevPanel = {}
local StatsBox = require('ui.stats_box')
local SkinManager = require('ui.skins.skin_manager')
local PomodoroTimer = require('ui.pomodoro_timer')
local FontManager = require('utils.font_manager')

local state = {
  open = false
}

-- ========= 绘制函数 =========
function DevPanel.draw(ctx, open)
  if not open then return end
  
  local r = reaper
  
  -- 设置窗口大小
  r.ImGui_SetNextWindowSize(ctx, 400, 500, r.ImGui_Cond_FirstUseEver())
  
  local visible, new_open = r.ImGui_Begin(ctx, "Developer Panel##DevPanel", true)
  
  if visible then
    r.ImGui_Text(ctx, "StatsBox Settings")
    r.ImGui_Separator(ctx)
    
    -- 获取配置引用（通过 StatsBox 的公开接口）
    local config = StatsBox.get_dev_config and StatsBox.get_dev_config() or nil
    
    if config then
      -- 尺寸调整
      if r.ImGui_CollapsingHeader(ctx, "Size Settings", r.ImGui_TreeNodeFlags_DefaultOpen()) then
        -- 确保值存在
        config.box_height = config.box_height or 120
        config.box_padding = config.box_padding or 30
        config.menu_button_size = config.menu_button_size or 120
        config.spacing_between = config.spacing_between or 16
        
        -- ImGui_SliderInt 返回 (changed, new_value)
        -- 直接更新 config 中的值，这样 StatsBox.draw() 会在下一帧使用新值
        -- 扩大可调范围：50-400
        local _, new_height = r.ImGui_SliderInt(ctx, "Box Height", config.box_height, 50, 400)
        config.box_height = new_height
        
        -- 扩大可调范围：10-100
        local _, new_padding = r.ImGui_SliderInt(ctx, "Box Padding", config.box_padding, 10, 100)
        config.box_padding = new_padding
        
        -- 菜单按钮大小（建议与 box_height 保持一致，保持视觉平衡）
        -- 扩大可调范围：50-400
        local _, new_menu_size = r.ImGui_SliderInt(ctx, "Menu Button Size", config.menu_button_size, 50, 400)
        config.menu_button_size = new_menu_size
        
        -- 扩大可调范围：0-100
        local _, new_spacing = r.ImGui_SliderInt(ctx, "Spacing Between", config.spacing_between, 0, 100)
        config.spacing_between = new_spacing

        -- 字体大小（新增）：调整 StatsBox 数字大小
        config.base_font_size = config.base_font_size or 56
        local _, new_font_size = r.ImGui_SliderInt(ctx, "Font Size (StatsBox)", config.base_font_size, 24, 120)
        config.base_font_size = new_font_size
      end
      
      -- 位置调整
      if r.ImGui_CollapsingHeader(ctx, "Position Settings", r.ImGui_TreeNodeFlags_DefaultOpen()) then
        -- 确保值存在
        config.offset_x = config.offset_x or 0
        config.offset_y = config.offset_y or 100
        config.menu_offset_x = config.menu_offset_x or 230
        
        -- 统计框位置调整
        r.ImGui_Text(ctx, "Stats Box Position:")
        -- ImGui_SliderInt 返回 (changed, new_value)
        -- 直接更新 config 中的值，这样 StatsBox.draw() 会在下一帧使用新值
        -- 扩大可调范围：-500 到 500
        local _, new_x = r.ImGui_SliderInt(ctx, "  Offset X (Stats Box)", config.offset_x, -500, 500)
        config.offset_x = new_x
        
        -- 扩大可调范围：-500 到 500（向下移动更多）
        local _, new_y = r.ImGui_SliderInt(ctx, "  Offset Y (Stats Box)", config.offset_y, -500, 500)
        config.offset_y = new_y
        
        r.ImGui_Separator(ctx)
        r.ImGui_Text(ctx, "Menu Button Position:")
        -- 菜单按钮独立的水平偏移（控制靠右的程度）
        -- 扩大可调范围：-500 到 500（正数向右，负数向左）
        local _, new_menu_x = r.ImGui_SliderInt(ctx, "  Menu Offset X (Right)", config.menu_offset_x, -500, 500)
        config.menu_offset_x = new_menu_x
      end
      
      -- 重置按钮
      r.ImGui_Separator(ctx)
      if r.ImGui_Button(ctx, "Reset to Default", 200, 30) then
        config.box_height = 120
        config.box_padding = 30
        config.menu_button_size = 120
        config.spacing_between = 16
        config.offset_x = 0
        config.offset_y = 100
        config.menu_offset_x = 230
        config.base_font_size = 75
        config.text_vertical_offset = -0.053
        config.text_horizontal_offset = -0.004
        r.ImGui_TextColored(ctx, 0xFF66CC66, "Reset")
      end
      
      -- StatsBox 文字设置
      if r.ImGui_CollapsingHeader(ctx, "StatsBox Text Settings", r.ImGui_TreeNodeFlags_DefaultOpen()) then
        -- 字体大小
        config.base_font_size = config.base_font_size or 75
        local _, new_font_size = r.ImGui_SliderInt(ctx, "Font Size", config.base_font_size, 20, 120)
        config.base_font_size = new_font_size

        -- 文字位置偏移
        config.text_vertical_offset = config.text_vertical_offset or -0.053
        local _, new_text_v_offset = r.ImGui_SliderDouble(ctx, "Text Vertical Offset", config.text_vertical_offset, -0.5, 0.5, "%.3f")
        config.text_vertical_offset = new_text_v_offset

        config.text_horizontal_offset = config.text_horizontal_offset or -0.004
        local _, new_text_h_offset = r.ImGui_SliderDouble(ctx, "Text Horizontal Offset", config.text_horizontal_offset, -0.5, 0.5, "%.3f")
        config.text_horizontal_offset = new_text_h_offset
      end
    else
      r.ImGui_TextColored(ctx, 0xFFFF6666, "Cannot access StatsBox config")
      r.ImGui_Text(ctx, "Please ensure StatsBox module is properly initialized")
    end
    -- Pomodoro Timer 文字调节
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    if r.ImGui_CollapsingHeader(ctx, "Pomodoro Timer Text", r.ImGui_TreeNodeFlags_DefaultOpen()) then
      if PomodoroTimer.get_dev_config then
        local timer_cfg = PomodoroTimer.get_dev_config()
        if timer_cfg and timer_cfg.style then
          local ts = timer_cfg.style
          -- 字号比例（时间）
          ts.scale_factor_time = ts.scale_factor_time or 0.38
          local _, new_time_scale = r.ImGui_SliderDouble(ctx, "Time Scale Factor", ts.scale_factor_time, 0.25, 0.6, "%.3f")
          ts.scale_factor_time = new_time_scale

          -- 字号比例（标签）
          ts.scale_factor_label = ts.scale_factor_label or 0.12
          local _, new_label_scale = r.ImGui_SliderDouble(ctx, "Label Scale Factor", ts.scale_factor_label, 0.05, 0.25, "%.3f")
          ts.scale_factor_label = new_label_scale

          -- 垂直偏移（整体上移/下移，单位：相对于圆圈尺寸的比例）
          ts.text_vertical_offset = ts.text_vertical_offset or 0.0
          local _, new_vertical_offset = r.ImGui_SliderDouble(ctx, "Vertical Offset", ts.text_vertical_offset, -0.3, 0.3, "%.3f")
          ts.text_vertical_offset = new_vertical_offset

          -- 时间水平偏移（整体左移/右移，单位：相对于圆圈尺寸的比例）
          ts.text_horizontal_offset = ts.text_horizontal_offset or -0.083
          local _, new_time_horizontal = r.ImGui_SliderDouble(ctx, "Time Horizontal Offset", ts.text_horizontal_offset, -0.3, 0.3, "%.3f")
          ts.text_horizontal_offset = new_time_horizontal

          -- 标签水平偏移（独立控制标签的左右位置）
          ts.label_horizontal_offset = ts.label_horizontal_offset or -0.027
          local _, new_label_horizontal = r.ImGui_SliderDouble(ctx, "Label Horizontal Offset", ts.label_horizontal_offset, -0.3, 0.3, "%.3f")
          ts.label_horizontal_offset = new_label_horizontal

          -- 间距系数（时间与标签之间的间距比例）
          ts.text_gap_factor = ts.text_gap_factor or 0.35
          local _, new_gap = r.ImGui_SliderDouble(ctx, "Gap Factor", ts.text_gap_factor, 0.0, 0.8, "%.3f")
          ts.text_gap_factor = new_gap
        else
          r.ImGui_TextColored(ctx, 0xFFFF6666, "Cannot access PomodoroTimer config")
        end
      else
        r.ImGui_TextColored(ctx, 0xFFFF6666, "PomodoroTimer dev config not available")
      end
    end

    -- 爱心粒子系统设置
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    if r.ImGui_CollapsingHeader(ctx, "Heart Particle System", r.ImGui_TreeNodeFlags_DefaultOpen()) then
      -- 获取当前激活的皮肤
      local active_skin = SkinManager.get_active_skin()
      if active_skin and active_skin.get_particle_config then
        local particle_config = active_skin.get_particle_config()
        if particle_config then
          r.ImGui_Text(ctx, "Heart Position (relative to cat center):")
          
          -- 左手爱心水平偏移
          local _, new_left_x = r.ImGui_SliderInt(ctx, "  Left Hand X Offset", particle_config.left_offset_x, -500, 500)
          particle_config.left_offset_x = new_left_x
          r.ImGui_SameLine(ctx)
          r.ImGui_Text(ctx, string.format("(current: %d)", particle_config.left_offset_x))
          
          -- 右手爱心水平偏移
          local _, new_right_x = r.ImGui_SliderInt(ctx, "  Right Hand X Offset", particle_config.right_offset_x, -500, 500)
          particle_config.right_offset_x = new_right_x
          r.ImGui_SameLine(ctx)
          r.ImGui_Text(ctx, string.format("(current: %d)", particle_config.right_offset_x))
          
          -- 垂直偏移
          local _, new_y = r.ImGui_SliderInt(ctx, "  Vertical Y Offset", particle_config.offset_y, -200, 200)
          particle_config.offset_y = new_y
          r.ImGui_SameLine(ctx)
          r.ImGui_Text(ctx, string.format("(current: %d)", particle_config.offset_y))
          
          r.ImGui_Separator(ctx)
          r.ImGui_Text(ctx, "Heart Size:")
          -- 爱心大小倍数（使用 ImGui_SliderDouble，ReaImGui 不支持 ImGui_SliderFloat）
          local _, new_size = r.ImGui_SliderDouble(ctx, "  Size Multiplier", particle_config.size_multiplier, 1.0, 30.0, "%.1f")
          particle_config.size_multiplier = new_size
          r.ImGui_SameLine(ctx)
          r.ImGui_Text(ctx, string.format("(current: %.1f)", particle_config.size_multiplier))
          
          r.ImGui_Separator(ctx)
          if r.ImGui_Button(ctx, "Reset Heart Settings", 200, 30) then
            particle_config.left_offset_x = 300
            particle_config.right_offset_x = -300
            particle_config.offset_y = -50
            particle_config.size_multiplier = 20.0
            r.ImGui_TextColored(ctx, 0xFF66CC66, "Reset")
          end
        else
          r.ImGui_TextColored(ctx, 0xFFFF6666, "Current skin does not support particle config")
        end
      else
        r.ImGui_TextColored(ctx, 0xFFFF6666, "Cannot access skin particle config")
        r.ImGui_Text(ctx, "Please ensure current skin supports particle system")
      end
    end

    -- Treasure Box 设置 (新增)
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    if r.ImGui_CollapsingHeader(ctx, "Treasure Box Settings", r.ImGui_TreeNodeFlags_DefaultOpen()) then
      local Config = require('config')
      local t_cfg = Config.TREASURE_BOX
      if t_cfg then
        -- 尺寸
        local _, new_w = r.ImGui_SliderInt(ctx, "Width", t_cfg.width, 10, 200)
        t_cfg.width = new_w
        
        local _, new_h = r.ImGui_SliderInt(ctx, "Height", t_cfg.height, 10, 200)
        t_cfg.height = new_h
        
        -- 位置偏移
        local _, new_tx = r.ImGui_SliderInt(ctx, "Offset X", t_cfg.offset_x, -500, 500)
        t_cfg.offset_x = new_tx
        
        local _, new_ty = r.ImGui_SliderInt(ctx, "Offset Y", t_cfg.offset_y, -500, 500)
        t_cfg.offset_y = new_ty
        
        -- 重置
        if r.ImGui_Button(ctx, "Reset Treasure Box", 200, 30) then
          t_cfg.width = 180
          t_cfg.height = 180
          t_cfg.offset_x = 0
          t_cfg.offset_y = 0
          r.ImGui_TextColored(ctx, 0xFF66CC66, "Reset")
        end
      end
    end

    -- Zzz 动画设置
    r.ImGui_Separator(ctx)
    r.ImGui_Spacing(ctx)
    if r.ImGui_CollapsingHeader(ctx, "Zzz Animation (Rest State)", r.ImGui_TreeNodeFlags_DefaultOpen()) then
      -- 获取当前激活的皮肤
      local active_skin = SkinManager.get_active_skin()
      if active_skin and active_skin.get_zzz_config then
        local zzz_config = active_skin.get_zzz_config()
        if zzz_config then
          r.ImGui_Text(ctx, "Zzz Size:")
          -- 基础大小（扩大范围：1.0 到 100.0）
          local _, new_base_size = r.ImGui_SliderDouble(ctx, "  Base Size", zzz_config.base_size, 1.0, 100.0, "%.1f")
          zzz_config.base_size = new_base_size
          -- 大小增长（扩大范围：0.0 到 100.0）
          local _, new_size_growth = r.ImGui_SliderDouble(ctx, "  Size Growth", zzz_config.size_growth, 0.0, 100.0, "%.1f")
          zzz_config.size_growth = new_size_growth
          
          r.ImGui_Separator(ctx)
          r.ImGui_Text(ctx, "Zzz Position (relative to face):")
          -- 水平偏移（扩大范围：-500.0 到 500.0）
          local _, new_offset_x = r.ImGui_SliderDouble(ctx, "  Offset X", zzz_config.offset_x, -500.0, 500.0, "%.1f")
          zzz_config.offset_x = new_offset_x
          -- 垂直偏移（扩大范围：-500.0 到 500.0）
          local _, new_offset_y = r.ImGui_SliderDouble(ctx, "  Offset Y", zzz_config.offset_y, -500.0, 500.0, "%.1f")
          zzz_config.offset_y = new_offset_y
          -- 脸部垂直偏移（扩大范围：-500.0 到 0.0）
          local _, new_face_offset_y = r.ImGui_SliderDouble(ctx, "  Face Offset Y", zzz_config.face_offset_y, -500.0, 0.0, "%.1f")
          zzz_config.face_offset_y = new_face_offset_y
          
          r.ImGui_Separator(ctx)
          r.ImGui_Text(ctx, "Zzz Animation:")
          -- 水平间距（扩大范围：0.0 到 150.0）
          local _, new_spacing_x = r.ImGui_SliderDouble(ctx, "  Spacing X", zzz_config.spacing_x, 0.0, 150.0, "%.1f")
          zzz_config.spacing_x = new_spacing_x
          -- 水平移动速度（扩大范围：0.0 到 500.0）
          local _, new_move_speed_x = r.ImGui_SliderDouble(ctx, "  Move Speed X", zzz_config.move_speed_x, 0.0, 500.0, "%.1f")
          zzz_config.move_speed_x = new_move_speed_x
          -- 垂直移动速度（扩大范围：0.0 到 500.0）
          local _, new_move_speed_y = r.ImGui_SliderDouble(ctx, "  Move Speed Y", zzz_config.move_speed_y, 0.0, 500.0, "%.1f")
          zzz_config.move_speed_y = new_move_speed_y
          -- 动画速度
          local _, new_animation_speed = r.ImGui_SliderDouble(ctx, "  Animation Speed", zzz_config.animation_speed, 0.1, 3.0, "%.2f")
          zzz_config.animation_speed = new_animation_speed
          
          r.ImGui_Separator(ctx)
          r.ImGui_Text(ctx, "Zzz Appearance:")
          -- 淡出开始比例
          zzz_config.fade_start = zzz_config.fade_start or 0.5
          local _, new_fade_start = r.ImGui_SliderDouble(ctx, "  Fade Start", zzz_config.fade_start, 0.0, 1.0, "%.2f")
          zzz_config.fade_start = new_fade_start
          -- 最小透明度比例
          zzz_config.min_alpha = zzz_config.min_alpha or 0.4
          local _, new_min_alpha = r.ImGui_SliderDouble(ctx, "  Min Alpha", zzz_config.min_alpha, 0.0, 1.0, "%.2f")
          zzz_config.min_alpha = new_min_alpha
          r.ImGui_SameLine(ctx)
          r.ImGui_Text(ctx, "(0.0 = fully transparent, 1.0 = fully opaque)")
          -- 线条基础粗细（扩大范围：0.5 到 50.0）
          local _, new_line_thickness_base = r.ImGui_SliderDouble(ctx, "  Line Thickness Base", zzz_config.line_thickness_base, 0.5, 50.0, "%.1f")
          zzz_config.line_thickness_base = new_line_thickness_base
          -- 线条粗细减少量（扩大范围：0.0 到 25.0）
          local _, new_line_thickness_reduce = r.ImGui_SliderDouble(ctx, "  Line Thickness Reduce", zzz_config.line_thickness_reduce, 0.0, 25.0, "%.1f")
          zzz_config.line_thickness_reduce = new_line_thickness_reduce
          -- 线条粗细自动缩放比例（根据 Z 大小自动调整，0.0 = 禁用）
          zzz_config.line_thickness_auto_scale = zzz_config.line_thickness_auto_scale or 0.15
          local _, new_auto_scale = r.ImGui_SliderDouble(ctx, "  Line Thickness Auto Scale", zzz_config.line_thickness_auto_scale, 0.0, 1.0, "%.3f")
          zzz_config.line_thickness_auto_scale = new_auto_scale
          r.ImGui_SameLine(ctx)
          r.ImGui_Text(ctx, "(0.0 = disabled)")
          
          r.ImGui_Separator(ctx)
          if r.ImGui_Button(ctx, "Reset Zzz Settings", 200, 30) then
            zzz_config.base_size = 19.8
            zzz_config.size_growth = 38.5
            zzz_config.offset_x = 104.7
            zzz_config.offset_y = -281.4
            zzz_config.spacing_x = 50.3
            zzz_config.move_speed_x = 57.8
            zzz_config.move_speed_y = 261.6
            zzz_config.animation_speed = 0.8
            zzz_config.fade_start = 0.5
            zzz_config.min_alpha = 0.4
            zzz_config.line_thickness_base = 2.0
            zzz_config.line_thickness_reduce = 0.5
            zzz_config.line_thickness_auto_scale = 0.15
            zzz_config.face_offset_y = 0.0
            r.ImGui_TextColored(ctx, 0xFF66CC66, "Reset")
          end
        else
          r.ImGui_TextColored(ctx, 0xFFFF6666, "Current skin does not support zzz config")
        end
      else
        r.ImGui_TextColored(ctx, 0xFFFF6666, "Cannot access skin zzz config")
        r.ImGui_Text(ctx, "Please ensure current skin supports zzz animation")
      end
    end
  end
  
  r.ImGui_Separator(ctx)
  
    -- ========= Coin System Debug =========
    if r.ImGui_CollapsingHeader(ctx, "Coin System Debug", r.ImGui_TreeNodeFlags_DefaultOpen()) then
      local CoinSystem = require('core.coin_system')
      local ShopSystem = require('core.shop_system')
      local Config = require('config')
      
      -- Debug: 跳过focus也显示宝箱
      local debug_treasure_on_skip = Config.DEBUG_TREASURE_ON_SKIP or false
      local _, new_debug_treasure = r.ImGui_Checkbox(ctx, "Show Treasure on Skip Focus", debug_treasure_on_skip)
      Config.DEBUG_TREASURE_ON_SKIP = new_debug_treasure
      
      r.ImGui_Separator(ctx)
      
      -- Current state
      local current_balance = CoinSystem.get_balance()
      local daily_earned = CoinSystem.get_daily_earned()
      local daily_remaining = CoinSystem.get_daily_remaining()
      
      r.ImGui_Text(ctx, "Balance: " .. tostring(current_balance) .. " coins")
      r.ImGui_Text(ctx, "Daily: " .. tostring(daily_earned) .. " / 600 coins")
      r.ImGui_Text(ctx, "Remaining: " .. tostring(daily_remaining) .. " coins")
      
      r.ImGui_Spacing(ctx)
      
      -- Cheats / Debug Controls
      if r.ImGui_Button(ctx, "Add 100 Coins", 150, 30) then
        CoinSystem.add(100)
        CoinSystem.save()
      end
      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx, "Add 500 Coins", 150, 30) then
        CoinSystem.add(500)
        CoinSystem.save()
      end
      
      if r.ImGui_Button(ctx, "Reset Daily Limit", 200, 30) then
        -- Force reset daily limit by calling reward_focus with 0 minutes
        CoinSystem.reward_focus(0)
        CoinSystem.save()
        r.ImGui_TextColored(ctx, 0xFF66CC66, "Daily limit reset!")
      end
      
      r.ImGui_Separator(ctx)
      
      -- Reset button
      if r.ImGui_Button(ctx, "Reset Coin & Shop System", 200, 30) then
        -- Reset coin system
        if CoinSystem.reset then
          CoinSystem.reset()
        else
          CoinSystem.init(CoinSystem.get_data_file and CoinSystem.get_data_file() or nil)
        end
        -- Reset shop system
        if ShopSystem.reset then
          ShopSystem.reset()
        else
          ShopSystem.init(ShopSystem.get_data_file and ShopSystem.get_data_file() or nil)
        end
        r.ImGui_TextColored(ctx, 0xFF00FF00, "Coin and Shop systems reset!")
      end
      
      r.ImGui_Spacing(ctx)
      
      -- Owned skins info
      local owned_skins = ShopSystem.get_owned_skins()
      r.ImGui_Text(ctx, "Owned Skins: " .. tostring(#owned_skins))
    end
    
    r.ImGui_Separator(ctx)
    
    -- ========= Treasure System Debug (New) =========
    if r.ImGui_CollapsingHeader(ctx, "Treasure System Debug") then
      local Treasure = require('core.treasure')
      local available = Treasure.is_available and Treasure.is_available() or false
      local plugin_count = Treasure.get_plugin_count and Treasure.get_plugin_count() or 0
      
      r.ImGui_Text(ctx, "Plugin Cache: " .. tostring(plugin_count))
      r.ImGui_Text(ctx, "Box Available: " .. (available and "Yes" or "No"))
      
      if r.ImGui_Button(ctx, "Force Rescan Plugins", 200, 30) then
         -- We need global_stats for this, try to get it from args or require? 
         -- DevPanel doesn't hold tracker. We'll skip passing stats for now or rely on internal logic
         if Treasure.refresh_plugin_cache then
            Treasure.refresh_plugin_cache(nil) -- nil stats might be ok or fail depending on impl
            r.ImGui_TextColored(ctx, 0xFF66CC66, "Scan triggered")
         end
      end
      
      if r.ImGui_Button(ctx, "Force Unlock Box", 200, 30) then
         if Treasure.show then Treasure.show() end
      end
    end
  
  r.ImGui_End(ctx)
  state.open = new_open
end

-- 获取/设置打开状态
function DevPanel.is_open()
  return state.open
end

function DevPanel.set_open(open)
  state.open = open
end

return DevPanel
