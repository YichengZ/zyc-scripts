--[[
  REAPER Companion - 统计数据显示框 (Optimized)
  在猫桌子位置显示实时统计数据（操作次数/活跃时间）
  
  优化记录:
  1. [Performance] 字符串缓存：仅当数值变化时重新格式化字符串，消除每帧 GC 压力。
  2. [Performance] API 本地化：提升访问速度。
  3. [Interface] 返回 menu_center_x/y 供定位。
--]]

local StatsBox = {}
local r = reaper -- 本地化 API
local Config = require('config')

-- ========= 内部状态 =========
local state = {
  display_mode = "actions",
  box_hovered = false,
  last_update_time = 0,
  
  -- [优化] 缓存变量
  cached_actions = -1,
  cached_time = -1,
  cached_str = "",
  last_mode = ""
}

-- ========= UI 配置 =========
local config = {
  box_height = 120,
  box_padding = 30,
  
  offset_x = 0,
  offset_y = 100,
  
  corner_radius = 16.0, 
  border_width = 3.0,   
  
  bg_color = 0xFFF9F0FF,        
  bg_hover = 0xFFF0E0FF,        
  border_color = 0x8D7B68FF,    
  text_color = 0x6B5B4EFF,      
  
  hover_anim_speed = 12.0,
  hover_alpha = 0.0,
  
  base_font_size = 75,
  font_scale = 1.0,
  
  text_vertical_offset = -0.053,
  text_horizontal_offset = -0.004
}

-- ========= 工具函数 =========
local function format_time(seconds)
  if not seconds or seconds < 0 then return "00:00:00" end
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  local secs = math.floor(seconds % 60)
  return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function format_number(num)
  if not num or num < 0 then return "0" end
  local formatted = tostring(math.floor(num))
  local k
  formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
  while k ~= 0 do
    formatted, k = string.gsub(formatted, "(%d)(%d%d%d)", '%1 %2')
  end
  return formatted
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

-- ========= 更新函数 =========
function StatsBox.update(dt)
  local target_alpha = state.box_hovered and 1.0 or 0.0
  config.hover_alpha = lerp(config.hover_alpha, target_alpha, dt * config.hover_anim_speed)
end

-- ========= 绘制函数 =========
function StatsBox.draw(ctx, dl, x, y, w, h, tracker, scale, skin_rect, extra_scale, offset_x, offset_y)
  if not tracker then return nil end
  
  local project_stats = tracker:get_project_stats()
  local action_count = project_stats.actions or 0
  local active_time = project_stats.active_time or 0
  
  -- [优化] 字符串缓存逻辑
  local mode_changed = (state.display_mode ~= state.last_mode)
  local val_changed = false
  
  if state.display_mode == "actions" then
    if action_count ~= state.cached_actions then val_changed = true end
  else
    if active_time ~= state.cached_time then val_changed = true end
  end
  
  if mode_changed or val_changed then
    if state.display_mode == "actions" then
      state.cached_str = format_number(action_count)
      state.cached_actions = action_count
    else
      state.cached_str = format_time(active_time)
      state.cached_time = active_time
    end
    state.last_mode = state.display_mode
  end
  
  local display_text = state.cached_str
  
  local cat_cx, cat_cy, actual_scale
  if skin_rect and skin_rect.center_x and skin_rect.center_y then
    cat_cx = skin_rect.min_x + skin_rect.draw_w * 0.5
    cat_cy = skin_rect.min_y + skin_rect.draw_h * 0.65
    actual_scale = skin_rect.scale
  else
    cat_cx = x + w * 0.5
    cat_cy = y + h * 0.65
    actual_scale = scale
  end
  
  actual_scale = actual_scale * (extra_scale or 1.0)
  
  local table_surface_y = cat_cy + 18 * actual_scale
  local paw_max_extension = 22 * actual_scale
  local paw_bottom = table_surface_y + paw_max_extension
  local box_y = paw_bottom + 8 * actual_scale
  
  local box_height = config.box_height * actual_scale
  local box_padding = config.box_padding * actual_scale
  local corner_radius = config.corner_radius * actual_scale
  local border_width = config.border_width * actual_scale
  
  local base_font_size = config.base_font_size or 56
  local font_size = math.floor(base_font_size * actual_scale)
  
  -- 估算文本宽度 (避免 ImGui_CalcTextSize 的额外开销)
  local function estimate_text_width(text, f_size)
    return #text * f_size * 0.55
  end
  local text_width = estimate_text_width(display_text, font_size)
  local text_height = font_size
  
  local box_width = text_width + box_padding * 2
  
  local final_offset_x = offset_x or config.offset_x
  local final_offset_y = offset_y or config.offset_y
  
  local box_x = cat_cx - box_width * 0.5 + final_offset_x * actual_scale
  local box_y = box_y + final_offset_y * actual_scale
  
  local mx, my = r.ImGui_GetMousePos(ctx)
  state.box_hovered = (mx >= box_x and mx <= box_x + box_width and
                       my >= box_y and my <= box_y + box_height)
  
  local box_bg = state.box_hovered and config.bg_hover or config.bg_color
  
  local shadow_col = (config.border_color & 0xFFFFFF00) | 0x40 
  local shadow_offset = 4.0 * actual_scale

  -- Stats Box Drawing
  r.ImGui_DrawList_AddRectFilled(dl, box_x + shadow_offset, box_y + shadow_offset, box_x + box_width + shadow_offset, box_y + box_height + shadow_offset, shadow_col, corner_radius, 0)
  r.ImGui_DrawList_AddRectFilled(dl, box_x, box_y, box_x + box_width, box_y + box_height, box_bg, corner_radius, 0)
  r.ImGui_DrawList_AddRect(dl, box_x, box_y, box_x + box_width, box_y + box_height, config.border_color, corner_radius, 0, border_width)
  
  local text_horizontal_offset = (Config.STATS_BOX_TEXT_OFFSET_X or 0.0) * box_width
  local text_x = box_x + (box_width - text_width) * 0.5 + text_horizontal_offset
  local text_vertical_offset = (Config.STATS_BOX_TEXT_OFFSET_Y or 0.0) * box_height
  local baseline_offset = text_height * 0.03
  local text_y = box_y + (box_height - text_height) * 0.5 + baseline_offset + text_vertical_offset
  
  if r.ImGui_DrawList_AddTextEx then
    r.ImGui_DrawList_AddTextEx(dl, nil, font_size, text_x, text_y, config.text_color, display_text)
  else
    r.ImGui_DrawList_AddText(dl, text_x, text_y, config.text_color, display_text)
  end
  
  return {
    box_x = box_x,
    box_y = box_y,
    box_width = box_width,
    box_height = box_height,
    cat_cx = cat_cx,
    actual_scale = actual_scale,
    table_right_edge = cat_cx + 90 * actual_scale,
    box_hovered = state.box_hovered
  }
end

function StatsBox.handle_click(ctx, interaction_info)
  if not interaction_info then return false end
  
  if interaction_info.box_hovered and r.ImGui_IsMouseClicked(ctx, 0) then
    if state.display_mode == "actions" then
      state.display_mode = "time"
    else
      state.display_mode = "actions"
    end
    return "box_clicked"
  end
  
  return false
end

function StatsBox.get_display_mode() return state.display_mode end
function StatsBox.set_display_mode(mode) if mode == "actions" or mode == "time" then state.display_mode = mode end end
function StatsBox.get_dev_config() return config end

return StatsBox