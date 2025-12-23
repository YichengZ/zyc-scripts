--[[
  REAPER Companion - 宝箱 UI 模块 (Kawaii Pop FX v2.5 High-Key Candy)
  职责：专门负责宝箱 UI 的绘制和动画
  风格：Kawaii / High-Key Bright / Luminous
  
  优化 (2025-05):
  - 引入对象池 (ObjectPool) 减少 GC
--]]

local TreasureBox = {}
local Config = require('config')
local ObjectPool = require('utils.object_pool')
local r = reaper

-- ========= 配置 =========
local cfg = {
  bubble_bg   = 0xFFFFFFFF,
  bubble_line = 0xE0E0E0FF,
  
  chest_body  = 0x795548FF,
  chest_dark  = 0x5D4037FF,
  chest_lock  = 0xFFD700FF,  
  chest_lock_glow = 0xFFFF00FF,
  outline_col = 0x2A2A2AFF,
}

-- ========= 内部状态 =========
local state = {
  pulse_phase = 0,      
  is_clicked = false,   
  click_time = 0,
  
  -- 动画状态
  is_exploding = false, 
  exploding_time = 0,
  exploding_duration = 1.5, 
  
  particles = {},       
  shockwave = { progress = 0, max_r = 0, width = 0 }, 
  
  -- 动画位置缓存
  saved_x = nil, saved_y = nil, saved_w = nil, saved_h = nil,
  center_x = nil, center_y = nil,
  scale_factor = 1.0,
  
  -- 对象池
  particle_pool = nil
}

-- ========= 辅助函数 =========
local function set_alpha(col, alpha)
  return (col & 0xFFFFFF00) | math.floor(math.max(0, math.min(255, alpha)))
end

local function rotate_point(cx, cy, x, y, angle)
  local s = math.sin(angle)
  local c = math.cos(angle)
  local tx = x - cx
  local ty = y - cy
  return (tx * c - ty * s) + cx, (tx * s + ty * c) + cy
end

-- 缓动函数 (EaseOutCubic)
local function ease_out_cubic(t)
  t = t - 1
  return t * t * t + 1
end

-- ========= 1. 初始化与接口 =========
function TreasureBox.init()
  state.pulse_phase = 0
  state.particles = {}
  state.is_exploding = false
  
  -- 初始化粒子池
  state.particle_pool = ObjectPool.new(function() return {
    x=0, y=0, vx=0, vy=0, angle=0, spin=0, gravity=0, drag=0,
    life=0, decay=0, size_start=0, size=0, color=0, type="",
    sway_phase=0, sway_speed=0, sway_amp=0
  } end, 100)
end

function TreasureBox.is_opening()
  return state.is_exploding
end

function TreasureBox.get_open_progress()
  if not state.is_exploding then return 0 end
  return math.min(1.0, state.exploding_time / state.exploding_duration)
end

-- ========= 2. 动画触发 (高亮糖果配色) =========
-- @param x, y, w, h 宝箱位置和尺寸
-- @param coins_earned 获得的金币数量（可选，用于调整特效强度）
function TreasureBox.trigger_open(x, y, w, h, coins_earned)
  coins_earned = coins_earned or 0  -- 默认0，如果没有传入
  
  state.is_exploding = true
  state.exploding_time = 0
  
  -- 回收旧粒子
  for _, p in ipairs(state.particles) do state.particle_pool:release(p) end
  state.particles = {}
  
  state.saved_x = x or 0; state.saved_y = y or 0
  state.saved_w = w or 45; state.saved_h = h or 45
  state.center_x = state.saved_x + state.saved_w * 0.5
  state.center_y = state.saved_y + state.saved_h * 0.5
  
  -- 计算缩放因子（基于宝箱尺寸，默认 45x45 为基准）
  local base_size = 45
  state.scale_factor = math.min(w or base_size, h or base_size) / base_size
  
  -- 根据金币数量计算特效强度（0.5 到 2.0 之间）
  local coin_intensity = 1.0
  if coins_earned > 0 then
    if coins_earned <= 10 then
      coin_intensity = 0.6 + (coins_earned / 10) * 0.2  -- 0.6 到 0.8
    elseif coins_earned <= 30 then
      coin_intensity = 0.8 + ((coins_earned - 10) / 20) * 0.2  -- 0.8 到 1.0
    elseif coins_earned <= 60 then
      coin_intensity = 1.0 + ((coins_earned - 30) / 30) * 0.3  -- 1.0 到 1.3
    elseif coins_earned <= 100 then
      coin_intensity = 1.3 + ((coins_earned - 60) / 40) * 0.3  -- 1.3 到 1.6
    else
      coin_intensity = 1.6 + math.min(0.4, (coins_earned - 100) / 200)  -- 1.6 到 2.0
    end
  end
  
  -- 1. 初始化冲击波（应用缩放和金币强度）
  local base_max_r = 85
  local base_width = 35.0
  state.shockwave = { 
    progress = 0, 
    max_r = base_max_r * state.scale_factor * coin_intensity, 
    width = base_width * state.scale_factor * coin_intensity
  } 
  
  -- 2. 生成粒子 (高亮糖果色系 - High Brightness)
  -- 优化：降低粒子数量以保证 Windows 平台的流畅度
  local base_p_count = 50  -- 从 65 降至 50
  local p_count = math.floor(base_p_count * coin_intensity)
  p_count = math.max(20, math.min(100, p_count)) -- 上限从 150 降至 100
  
  local colors = { 
    0xFF94C2FF, -- Bright Pink
    0x81D4FAFF, -- High Blue
    0xB2FF59FF, -- Neon Green
    0xE0B0FFFF, -- Bright Mauve
    0xFFFF8DFF, -- Primrose
    0xFFCC80FF, -- Bright Apricot
    0xFFFFFFFF  -- White
  }

  for i = 1, p_count do
    local angle = (math.random() * math.pi * 2)
    local speed_base = math.random()
    local base_speed = (speed_base * speed_base) * 14 + 4
    local speed = base_speed * state.scale_factor * coin_intensity
    
    local type_rnd = math.random()
    local p_type = "circle"
    if type_rnd > 0.7 then p_type = "star"
    elseif type_rnd > 0.45 then p_type = "heart"
    elseif type_rnd > 0.25 then p_type = "confetti" end
    
    local p_gravity = 0.35 * state.scale_factor
    local p_drag = 0.92
    local p_spin = (math.random() - 0.5) * 0.5
    local base_size_val = math.random() * 6 + 4
    local p_size = base_size_val * state.scale_factor * (0.9 + coin_intensity * 0.1)
    
    if p_type == "heart" then
       p_gravity = 0.15 
       p_drag = 0.90    
       p_size = p_size * 1.4
       p_spin = p_spin * 0.3
    elseif p_type == "confetti" then
       p_gravity = 0.2  
       p_drag = 0.88    
    elseif p_type == "star" then
       p_gravity = 0.55 
       p_drag = 0.95    
       p_spin = p_spin * 1.5
    end

    local p = state.particle_pool:get()
    p.x = 0
    p.y = 0
    p.vx = math.cos(angle) * speed
    p.vy = math.sin(angle) * speed - (5 * state.scale_factor * coin_intensity)
    p.angle = math.random() * 6.28
    p.spin = p_spin
    p.gravity = p_gravity
    p.drag = p_drag
    p.life = 1.0
    p.decay = math.random() * 0.5 + 0.5
    p.size_start = p_size
    p.size = p_size
    p.color = colors[math.random(#colors)]
    p.type = p_type
    p.sway_phase = math.random() * 10
    p.sway_speed = math.random() * 3 + 2
    p.sway_amp = math.random() * 1.5 * state.scale_factor
    
    table.insert(state.particles, p)
  end
end

-- ========= 3. 动画更新 =========
function TreasureBox.update(dt)
  state.pulse_phase = state.pulse_phase + dt * 2.5
  
  if state.is_exploding then
    state.exploding_time = state.exploding_time + dt
    
    -- A. 冲击波更新
    local sw_duration = 0.35
    if state.shockwave.progress < 1.0 then
        state.shockwave.progress = math.min(1.0, state.shockwave.progress + dt / sw_duration)
    end
    
    -- B. 粒子更新
    for i = #state.particles, 1, -1 do
      local p = state.particles[i]
      
      p.x = p.x + p.vx
      p.y = p.y + p.vy
      p.vx = p.vx * p.drag
      p.vy = p.vy * p.drag
      p.vy = p.vy + p.gravity 
      p.angle = p.angle + p.spin
      
      -- 摇摆效果
      if (p.type == "confetti" or p.type == "heart") and p.vy > 0 then
          local sway = math.sin(state.exploding_time * p.sway_speed + p.sway_phase) * p.sway_amp
          p.x = p.x + sway
          p.angle = p.angle + sway * 0.1
      end

      p.life = p.life - dt * p.decay
      
      -- 动态缩放
      if p.life > 0.8 then
          p.size = p.size_start
      else
          local scale_t = math.max(0, p.life / 0.8)
          p.size = p.size_start * (scale_t ^ 2) 
      end

      if p.life <= 0 then
        state.particle_pool:release(p)
        table.remove(state.particles, i)
      end
    end
    
    if state.exploding_time >= state.exploding_duration then
      -- 强制回收剩余
      for _, p in ipairs(state.particles) do state.particle_pool:release(p) end
      state.particles = {}
      state.is_exploding = false
    end
  end
  
  if state.is_clicked then
    state.click_time = state.click_time + dt
    if state.click_time > 0.1 then state.is_clicked = false end
  end
end

-- ========= 4. 绘图逻辑 (深度优化版) =========

-- 预计算形状数据 (归一化坐标)，避免每帧计算 sin/cos 和创建 table
-- 星星数据：10个点 (外-内-外-内...)
local STAR_VERTS = {}
for i = 0, 9 do
  local angle = (i / 10) * math.pi * 2 - (math.pi / 2)
  local r = (i % 2 == 0) and 1.0 or 0.55
  table.insert(STAR_VERTS, {math.cos(angle) * r, math.sin(angle) * r})
end

-- 爱心数据：贝塞尔曲线控制点 (简化为两段曲线)
-- 左半边控制点 和 右半边控制点
-- 这里使用简化画法：由4个点控制的心形近似
local function DrawHeart(dl, cx, cy, size, col)
  -- 优化：使用贝塞尔曲线代替多段线，大幅减少 API 调用
  local scale = size * 0.5
  
  -- 心形顶部凹陷点 (中心)
  local x0, y0 = cx, cy - scale * 0.4
  -- 底部尖点
  local x_bottom, y_bottom = cx, cy + scale * 0.9
  
  -- 左侧控制点
  local x_l1, y_l1 = cx - scale * 1.3, cy - scale * 1.3 -- 左上凸起
  local x_l2, y_l2 = cx - scale * 1.3, cy + scale * 0.4 -- 左下收缩
  
  -- 右侧控制点
  local x_r1, y_r1 = cx + scale * 1.3, cy - scale * 1.3 -- 右上凸起
  local x_r2, y_r2 = cx + scale * 1.3, cy + scale * 0.4 -- 右下收缩
  
  r.ImGui_DrawList_PathClear(dl)
  r.ImGui_DrawList_PathLineTo(dl, x0, y0)
  r.ImGui_DrawList_PathBezierCubicCurveTo(dl, x_l1, y_l1, x_l2, y_l2, x_bottom, y_bottom)
  r.ImGui_DrawList_PathBezierCubicCurveTo(dl, x_r2, y_r2, x_r1, y_r1, x0, y0)
  r.ImGui_DrawList_PathFillConvex(dl, col)
end

local function DrawCuteStar(dl, cx, cy, size, col)
  -- 优化：直接读取预计算数组，无数学计算，无 table 创建
  r.ImGui_DrawList_PathClear(dl)
  
  -- 展开循环以减少 Lua 开销
  local v = STAR_VERTS
  -- 手动展开 10 个点，虽然代码长点，但比循环快
  r.ImGui_DrawList_PathLineTo(dl, cx + v[1][1]*size, cy + v[1][2]*size)
  r.ImGui_DrawList_PathLineTo(dl, cx + v[2][1]*size, cy + v[2][2]*size)
  r.ImGui_DrawList_PathLineTo(dl, cx + v[3][1]*size, cy + v[3][2]*size)
  r.ImGui_DrawList_PathLineTo(dl, cx + v[4][1]*size, cy + v[4][2]*size)
  r.ImGui_DrawList_PathLineTo(dl, cx + v[5][1]*size, cy + v[5][2]*size)
  r.ImGui_DrawList_PathLineTo(dl, cx + v[6][1]*size, cy + v[6][2]*size)
  r.ImGui_DrawList_PathLineTo(dl, cx + v[7][1]*size, cy + v[7][2]*size)
  r.ImGui_DrawList_PathLineTo(dl, cx + v[8][1]*size, cy + v[8][2]*size)
  r.ImGui_DrawList_PathLineTo(dl, cx + v[9][1]*size, cy + v[9][2]*size)
  r.ImGui_DrawList_PathLineTo(dl, cx + v[10][1]*size, cy + v[10][2]*size)
  
  r.ImGui_DrawList_PathFillConvex(dl, col)
end

local function DrawConfetti(dl, p, alpha)
  local col = set_alpha(p.color, alpha)
  local hw, hh = p.size * 0.5, p.size * 0.5 
  local x1, y1 = rotate_point(p.x, p.y, p.x - hw, p.y - hh, p.angle)
  local x2, y2 = rotate_point(p.x, p.y, p.x + hw, p.y - hh, p.angle)
  local x3, y3 = rotate_point(p.x, p.y, p.x + hw, p.y + hh, p.angle)
  local x4, y4 = rotate_point(p.x, p.y, p.x - hw, p.y + hh, p.angle)
  r.ImGui_DrawList_AddQuadFilled(dl, x1, y1, x2, y2, x3, y3, x4, y4, col)
end

local function DrawWoodenChest(dl, cx, cy, size, alpha)
  local w = size * 0.75; local h = size * 0.6
  local x = cx - w * 0.5; local y = cy - h * 0.4 
  local c_body = set_alpha(cfg.chest_body, 255 * alpha)
  local c_dark = set_alpha(cfg.chest_dark, 255 * alpha)
  local c_lock = set_alpha(cfg.chest_lock, 255 * alpha)
  local c_lock_glow = set_alpha(cfg.chest_lock_glow, 200 * alpha) 
  local c_line = set_alpha(cfg.outline_col, 255 * alpha)
  local thick = 2.0
  r.ImGui_DrawList_AddRectFilled(dl, x, y, x+w, y+h, c_body, 4.0)
  local strap_w = w * 0.15
  r.ImGui_DrawList_AddRectFilled(dl, x + w*0.2, y, x + w*0.2 + strap_w, y+h, c_dark)
  r.ImGui_DrawList_AddRectFilled(dl, x + w*0.8 - strap_w, y, x + w*0.8, y+h, c_dark)
  local lid_h = h * 0.4
  r.ImGui_DrawList_AddLine(dl, x, y + lid_h, x+w, y + lid_h, c_dark, thick)
  r.ImGui_DrawList_AddRect(dl, x, y, x+w, y+h, c_line, 4.0, 0, thick)
  local lock_s = w * 0.18
  local lx = cx - lock_s * 0.5; local ly = y + lid_h - lock_s * 0.5
  local glow_size = lock_s * 1.2
  local glow_x = cx - glow_size * 0.5; local glow_y = ly - (glow_size - lock_s) * 0.5
  r.ImGui_DrawList_AddRectFilled(dl, glow_x, glow_y, glow_x+glow_size, glow_y+glow_size, c_lock_glow, 2.0)
  r.ImGui_DrawList_AddRectFilled(dl, lx, ly, lx+lock_s, ly+lock_s, c_lock, 2.0)
  r.ImGui_DrawList_AddRect(dl, lx, ly, lx+lock_s, ly+lock_s, c_line, 2.0, 0, thick)
end

local function DrawBubbleCard(dl, x, y, w, h, alpha, is_hovered, float_y)
  local card_size = math.min(w, h)
  local cx = x + w * 0.5
  local cy = y + h * 0.5 + float_y
  local half = card_size * 0.5
  local bx, by = cx - half, cy - half
  
  local c_bg = set_alpha(cfg.bubble_bg, 255 * alpha)
  local c_line = set_alpha(cfg.bubble_line, 255 * alpha)
  local c_shadow = set_alpha(0x00000022, 100 * alpha)
  if alpha > 0.8 then
      r.ImGui_DrawList_AddRectFilled(dl, bx+2, by+4, bx+card_size+2, by+card_size+4, c_shadow, 12.0)
  end
  r.ImGui_DrawList_AddRectFilled(dl, bx, by, bx+card_size, by+card_size, c_bg, 12.0)
  local border_col = is_hovered and 0xFFFFB3FF or c_line  -- 悬停时使用亮糖果黄色边框（高亮度，低饱和度）
  border_col = set_alpha(border_col, 255 * alpha)
  local border_thick = is_hovered and 3.0 or 2.0
  r.ImGui_DrawList_AddRect(dl, bx, by, bx+card_size, by+card_size, border_col, 12.0, 0, border_thick)
  DrawWoodenChest(dl, cx, cy, card_size, alpha)
end

function TreasureBox.draw(dl, x, y, w, h, is_hovered)
  if not state.is_exploding then
    if x and y and w and h then
      local float_y = math.sin(state.pulse_phase) * 6.0  -- 增大浮动幅度（从 3.0 改为 6.0）
      local click_offset = state.is_clicked and 2.0 or 0
      DrawBubbleCard(dl, x, y + click_offset, w, h, 1.0, is_hovered, float_y)
    end
  else
    local cx = state.center_x
    local cy = state.center_y
    if not cx then return end
    
    -- A. 冲击波 (提亮后的亮粉色)
    if state.shockwave.progress < 1.0 then
      local t = state.shockwave.progress
      local eased_t = ease_out_cubic(t) 
      
      local current_r = state.shockwave.max_r * eased_t
      local current_w = state.shockwave.width * (1.0 - eased_t) 
      local current_a = 1.0 - (t ^ 3) 
      
      if current_a > 0.01 then
        -- 使用与粒子一致的 Bright Pink (0xFF94C2FF)
        local sw_col = set_alpha(0xFF94C2FF, 255 * current_a)
        r.ImGui_DrawList_AddCircle(dl, cx, cy, current_r, sw_col, 0, current_w)
        
        local sw2_r = current_r * 0.7
        if sw2_r > 2 then
           local sw2_col = set_alpha(0xFFFFFFFF, 200 * current_a)
           r.ImGui_DrawList_AddCircle(dl, cx, cy, sw2_r, sw2_col, 0, current_w * 0.6)
        end
      end
    end
    
    -- B. 粒子绘制
    for _, p in ipairs(state.particles) do
      local px = cx + p.x
      local py = cy + p.y
      local alpha = math.floor(math.min(1.0, p.life * 1.5) * 255) 
      local col = set_alpha(p.color, alpha)
      
      if p.type == "star" then
        DrawCuteStar(dl, px, py, p.size, col)
      elseif p.type == "heart" then
        DrawHeart(dl, px, py, p.size, col)
      elseif p.type == "circle" then
        r.ImGui_DrawList_AddCircleFilled(dl, px, py, p.size * 0.6, col)
      else
        DrawConfetti(dl, p, alpha)
      end
    end
  end
end

-- ========= 交互检测 =========
function TreasureBox.is_point_inside(px, py, x, y, w, h, is_hovered)
  return px >= x and px <= x + w and py >= y and py <= y + h
end

function TreasureBox.trigger_click_feedback()
  state.is_clicked = true
  state.click_time = 0
end

function TreasureBox.is_hovered(mx, my, x, y, w, h)
  return TreasureBox.is_point_inside(mx, my, x, y, w, h, false)
end

return TreasureBox
