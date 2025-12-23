--[[
  REAPER Companion - Menu Button (Visual Fix & Optimized)
  
  修改记录:
  1. [Visual] 修复缩小时线条过粗的问题 (降低了 math.max 的阈值)。
  2. [Perf] API 本地化。
--]]

local MenuButton = {}
local r = reaper -- 本地化 API

-- ========= 内部状态 =========
local state = {
  hovered = false,
  hover_alpha = 0.0
}

-- ========= UI 配置 (San-X 风格) =========
local config = {
  bg_color = 0xFFF9F0FF,        
  bg_hover = 0xFFF0E0FF,        
  border_color = 0x8D7B68FF,    
  icon_color = 0x8D7B68FF,      
  
  corner_radius = 16.0,
  border_width = 3.0,
  hover_anim_speed = 12.0
}

local function lerp(a, b, t)
  return a + (b - a) * t
end

function MenuButton.update(dt)
  local target_alpha = state.hovered and 1.0 or 0.0
  state.hover_alpha = lerp(state.hover_alpha, target_alpha, dt * config.hover_anim_speed)
end

function MenuButton.draw(ctx, dl, x, y, size, scale)
  local corner_radius = config.corner_radius * scale
  local border_width = config.border_width * scale
  local shadow_offset = 4.0 * scale
  
  -- Mouse Interaction
  local mx, my = r.ImGui_GetMousePos(ctx)
  state.hovered = (mx >= x and mx <= x + size and
                   my >= y and my <= y + size)
                   
  local bg_col = state.hovered and config.bg_hover or config.bg_color
  local shadow_col = (config.border_color & 0xFFFFFF00) | 0x40
  
  -- Draw Shadow
  r.ImGui_DrawList_AddRectFilled(dl, x + shadow_offset, y + shadow_offset, x + size + shadow_offset, y + size + shadow_offset, shadow_col, corner_radius, 0)
  
  -- Draw Button Body
  r.ImGui_DrawList_AddRectFilled(dl, x, y, x + size, y + size, bg_col, corner_radius, 0)
  r.ImGui_DrawList_AddRect(dl, x, y, x + size, y + size, config.border_color, corner_radius, 0, border_width)
  
  -- Draw Menu Icon (Hamburger lines)
  local cx = x + size * 0.5
  local cy = y + size * 0.5
  
  -- [Visual Fix] 调整线条宽度和粗细逻辑
  local line_width = size * 0.55 -- 稍微再缩短一点点，显得更精致
  
  -- 关键修改：将最小粗细从 3.0 降为 1.2，比例从 0.08 降为 0.07
  -- 这样在小尺寸下线条会变细，但不会消失
  local line_thickness = math.max(1.2, size * 0.07) 
  
  local line_spacing = size * 0.22 
  
  for i = -1, 1 do
    local line_y = cy + i * line_spacing
    r.ImGui_DrawList_AddLine(dl, 
      cx - line_width * 0.5, line_y, 
      cx + line_width * 0.5, line_y, 
      config.icon_color, line_thickness)
  end
  
  return {
    hovered = state.hovered,
    center_x = cx,
    center_y = cy
  }
end

function MenuButton.handle_click(ctx, interaction)
  if interaction.hovered and r.ImGui_IsMouseClicked(ctx, 0) then
    return true
  end
  return false
end

return MenuButton