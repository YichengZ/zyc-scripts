--[[
  REAPER Companion - 金币特效系统 (Uniform Size)
  
  修改记录:
  1. [统一大小] 所有金币大小固定为 8.0，视觉更整齐。
  2. [保留特效] 依然保留了 3D 旋转、厚度描边和高光。
  3. [性能防护] 保持对象池和最大粒子限制。
--]]

local CoinEffect = {}
local r = reaper
local ObjectPool = require('utils.object_pool')

-- ========= 配置 =========
local cfg = {
  coin_gold       = 0xFFD700FF,
  coin_edge       = 0xB8860BFF,
  coin_shimmer    = 0xFFFFF0FF,
  
  text_core       = 0xFFD700FF,
  text_core_crit  = 0xFF4500FF,
  text_outline    = 0x3E2723FF,
  text_flash      = 0xFFFFFFFF,
  
  balance_bg_col     = 0xFFFDF5FF, 
  balance_border_col = 0x000000FF, 
  balance_text_col   = 0xD2691EFF, 
  
  duration        = 8.0,        
  text_pop_time   = 0.3,
  magnet_delay    = 3.0,        
  
  gravity         = 1200.0,
  drag            = 0.98,
  bounce_factor   = 0.5,
  friction        = 0.9,
  
  initial_speed_min = 200.0,
  initial_speed_max = 550.0,
  pop_force_y     = 350.0,
  
  magnet_speed    = 6.0,
  shrink_speed    = 0.8,
  
  MAX_COINS       = 50, 
}

-- ========= 内部状态 =========
local state = {
  active = false,
  start_time = 0,
  coins = {},
  text_items = {},
  center_x = 0, center_y = 0, scale = 1.0,
  -- 文本视觉缩放（与窗口缩放解耦，避免窗口缩放过大/过小时飘字过冲）
  text_scale = 1.0,
  
  target_x = 0, target_y = 0,
  win_x = 0, win_y = 0, win_w = 0, win_h = 0, 
  
  balance_label = {
    active = false,
    current_val = 0,    
    target_val = 0,     
    scale_punch = 1.0,  
    alpha = 0.0,        
    life_after_done = 0 
  },
  
  coin_pool = nil, text_pool = nil
}

-- 极速 Alpha 混合
local function set_alpha(col, alpha_byte)
  return (col & 0xFFFFFF00) | (alpha_byte & 0xFF)
end

-- 颜色插值 (用于飘字)
local function lerp_color(col1, col2, t)
  t = math.max(0, math.min(1, t))
  local r1, g1, b1 = (col1 >> 24) & 0xFF, (col1 >> 16) & 0xFF, (col1 >> 8) & 0xFF
  local r2, g2, b2 = (col2 >> 24) & 0xFF, (col2 >> 16) & 0xFF, (col2 >> 8) & 0xFF
  local r = math.floor(r1 + (r2 - r1) * t)
  local g = math.floor(g1 + (g2 - g1) * t)
  local b = math.floor(b1 + (b2 - b1) * t)
  return (r << 24) | (g << 16) | (b << 8) | (col1 & 0xFF)
end

-- ========= 初始化 =========
function CoinEffect.init()
  state.active = false
  state.coins = {}
  state.text_items = {}
  
  state.coin_pool = ObjectPool.new(function() return {
    x=0, y=0, vx=0, vy=0, 
    rot_phase=0, rot_speed=0, 
    size=0, life=0, max_life=0,
    state = "physics",
    collect_delay = 0,
    value = 0
  } end, 80) 
  
  state.text_pool = ObjectPool.new(function() return {
    x=0, y=0, start_y=0, text="", value=0, life=0, age=0, is_crit=false 
  } end, 10)
end

-- ========= 触发逻辑 =========
function CoinEffect.trigger(center_x, center_y, coins_earned, current_total_balance, scale)
  scale = scale or 1.0
  if coins_earned <= 0 then return end
  
  state.active = true
  state.start_time = 0
  state.center_x = center_x
  state.center_y = center_y
  state.scale = scale
  -- 文本缩放：对窗口缩放做轻微压缩，避免大缩放下位移和字号过大
  -- 例如 scale=0.5/2/3 时，text_scale 分别约为 0.7 / 1.4 / 1.7（再做夹紧）
  local ts = math.sqrt(scale)
  if ts < 0.75 then ts = 0.75 end
  if ts > 1.6 then ts = 1.6 end
  state.text_scale = ts
  
  state.balance_label.active = true
  state.balance_label.current_val = current_total_balance
  state.balance_label.target_val = current_total_balance + coins_earned
  state.balance_label.alpha = 0.0 
  state.balance_label.scale_punch = 1.0
  state.balance_label.life_after_done = 1.5 
  
  local count = coins_earned
  if count > cfg.MAX_COINS then count = cfg.MAX_COINS end
  --if count < 5 then count = 5 end 
  
  local val_per_particle = coins_earned / count
  
  for i = 1, count do
    local coin = state.coin_pool:get()
    
    local angle = -math.pi/2 + (math.random() - 0.5) * 2.0
    local speed = math.random(cfg.initial_speed_min, cfg.initial_speed_max)
    
    coin.x, coin.y = 0, 0 
    coin.vx = math.cos(angle) * speed
    coin.vy = math.sin(angle) * speed - cfg.pop_force_y
    
    coin.rot_phase = math.random() * math.pi * 2
    coin.rot_speed = 5.0 + math.random() * 10.0
    
    -- [修改] 统一固定大小为 8.0，不再有随机波动
    coin.size = 8.0 
    
    coin.life = 15.0
    coin.max_life = coin.life
    coin.state = "physics"
    coin.collect_delay = cfg.magnet_delay + (math.random() * 0.8)
    coin.value = val_per_particle 
    
    table.insert(state.coins, coin)
  end
  
  local txt = state.text_pool:get()
  txt.value = coins_earned
  txt.text = "+" .. coins_earned
  txt.x = 0 
  -- 起始高度也使用文本缩放，避免窗口缩放过大时弹出过高
  txt.start_y = -35 * state.text_scale
  txt.y = txt.start_y
  txt.age = 0
  txt.life = 2.0
  txt.is_crit = (coins_earned >= 30) 
  table.insert(state.text_items, txt)
end

-- Update
function CoinEffect.update(dt, box_x, box_y, win_w, win_h, win_x, win_y, target_x, target_y, floor_y_absolute)
  if not state.active then return end
  
  state.center_x = box_x
  state.center_y = box_y
  state.win_w, state.win_h = win_w or 800, win_h or 600
  state.win_x, state.win_y = win_x or 0, win_y or 0
  state.target_x, state.target_y = target_x or 0, target_y or 0
  state.start_time = state.start_time + dt
  
  local coins_active_count = 0
  local floor_abs_y = floor_y_absolute or (state.win_y + state.win_h)
  local floor_rel_y = (floor_abs_y - state.center_y) / state.scale - 10
  
  local G_dt = cfg.gravity * dt
  local mag_speed = cfg.magnet_speed * dt
  local shrink = 1.0 - cfg.shrink_speed * dt
  local target_rel_x = (state.target_x - state.center_x) / state.scale
  local target_rel_y = (state.target_y - state.center_y) / state.scale
  
  for i = #state.coins, 1, -1 do
    local c = state.coins[i]
    coins_active_count = coins_active_count + 1
    
    if c.state == "physics" then
      c.vy = c.vy + G_dt
      c.vx = c.vx * cfg.drag
      c.x = c.x + c.vx * dt
      c.y = c.y + c.vy * dt
      
      c.rot_phase = c.rot_phase + c.rot_speed * dt
      
      if c.y > floor_rel_y then
        c.y = floor_rel_y
        c.vy = -c.vy * cfg.bounce_factor
        c.vx = c.vx * cfg.friction
        if math.abs(c.vy) < 20 then c.vy = 0 end 
      end
      
      local wall_left = (state.win_x - state.center_x) / state.scale + 10
      local wall_right = (state.win_x + state.win_w - state.center_x) / state.scale - 10
      if c.x < wall_left then c.x = wall_left; c.vx = -c.vx * 0.8 end
      if c.x > wall_right then c.x = wall_right; c.vx = -c.vx * 0.8 end
      
      if state.start_time > c.collect_delay then c.state = "collecting" end
      
    elseif c.state == "collecting" then
      local dx = target_rel_x - c.x
      local dy = target_rel_y - c.y
      
      c.x = c.x + dx * mag_speed
      c.y = c.y + dy * mag_speed
      c.size = c.size * shrink
      c.rot_phase = 0 
      
      if (dx*dx + dy*dy) < 100 or c.size < 0.5 then
        c.life = -1
        state.balance_label.current_val = state.balance_label.current_val + c.value
        state.balance_label.scale_punch = 1.3 
        state.balance_label.alpha = 1.0 
      end
    end
    
    if c.life <= 0 then
      state.coin_pool:release(c)
      table.remove(state.coins, i)
      coins_active_count = coins_active_count - 1
    end
  end
  
  if state.balance_label.active then
    state.balance_label.scale_punch = state.balance_label.scale_punch + (1.0 - state.balance_label.scale_punch) * 10.0 * dt
    
    if state.start_time < cfg.magnet_delay then
        state.balance_label.alpha = 0.0 
    elseif coins_active_count > 0 then
        state.balance_label.alpha = 1.0
    else
        state.balance_label.life_after_done = state.balance_label.life_after_done - dt
        if state.balance_label.life_after_done <= 0 then
            state.balance_label.alpha = state.balance_label.alpha - dt * 2 
            if state.balance_label.alpha <= 0 then
                state.balance_label.active = false
            end
        else
            state.balance_label.current_val = state.balance_label.target_val
        end
    end
  end
  
  for i = #state.text_items, 1, -1 do
    local t = state.text_items[i]
    t.age = t.age + dt
    t.life = t.life - dt
    
    local y_offset = 0
    -- y 方向位移只与 text_scale 挂钩，不再直接使用窗口缩放 scale
    local ts = state.text_scale
    if t.age <= cfg.text_pop_time then
       local progress = t.age / cfg.text_pop_time
       y_offset = (1 - (1 - progress)^2) * 50 * ts
    else
       y_offset = 50 * ts + (t.age - cfg.text_pop_time) * 10.0 * ts
    end
    t.y = t.start_y - y_offset
    
    if t.life <= 0 then
      state.text_pool:release(t)
      table.remove(state.text_items, i)
    end
  end
  
  if #state.coins == 0 and #state.text_items == 0 and not state.balance_label.active then
    state.active = false
  end
end

-- [辅助] 绘制椭圆金币 (无 Table 分配版)
local function draw_elliptical_coin(dl, cx, cy, radius_x, radius_y, col, border_col)
  if radius_x < 0.5 then return end
  local segments = 12
  local angle0 = 0
  local first_x = cx + math.cos(angle0) * radius_x
  local first_y = cy + math.sin(angle0) * radius_y
  local last_x, last_y = first_x, first_y
  
  for i = 1, segments do
    local theta = (i / segments) * 2 * math.pi
    local curr_x = cx + math.cos(theta) * radius_x
    local curr_y = cy + math.sin(theta) * radius_y
    r.ImGui_DrawList_AddTriangleFilled(dl, cx, cy, last_x, last_y, curr_x, curr_y, col)
    r.ImGui_DrawList_AddLine(dl, last_x, last_y, curr_x, curr_y, border_col, 1.2)
    last_x, last_y = curr_x, curr_y
  end
end

function CoinEffect.draw(ctx, dl)
  if not state.active then return end
  
  local wx, wy = state.center_x, state.center_y
  local scale = state.scale
  local text_scale = state.text_scale or state.scale
  
  for _, c in ipairs(state.coins) do
    if c.size > 0.5 then
      local width_factor = math.abs(math.cos(c.rot_phase))
      local size = c.size * scale
      local radius_y = size 
      local radius_x = size * width_factor 
      
      local cx = wx + c.x * scale
      local cy = wy + c.y * scale
      
      local alpha = 255
      local col = set_alpha(cfg.coin_gold, alpha)
      local edge_col = set_alpha(cfg.coin_edge, alpha)
      
      draw_elliptical_coin(dl, cx, cy, radius_x, radius_y, col, edge_col)
      
      if width_factor > 0.7 then
        local hl_col = set_alpha(cfg.coin_shimmer, alpha)
        r.ImGui_DrawList_AddCircleFilled(dl, cx - radius_x * 0.3, cy - radius_y * 0.3, size * 0.4, hl_col)
      end
      
      if width_factor > 0.3 then
        local line_alpha = math.floor(alpha * 0.6)
        r.ImGui_DrawList_AddLine(dl, cx, cy - radius_y * 0.5, cx, cy + radius_y * 0.5, set_alpha(cfg.coin_edge, line_alpha), 1.5 * width_factor)
      end
    end
  end
  
  -- 绘制文本
  for _, t in ipairs(state.text_items) do
    local alpha = 255
    if t.life < 0.5 then alpha = math.floor(255 * (t.life / 0.5)) end
    -- 字体大小基于 text_scale，而不是窗口缩放 scale，避免缩放过大/过小时过度放大或缩小
    local font_size = math.floor((t.is_crit and 48 or 36) * text_scale)
    local color_t = math.min(1.0, t.age / 0.3)
    local text_col = lerp_color(cfg.text_flash, t.is_crit and cfg.text_core_crit or cfg.text_core, color_t)
    text_col = set_alpha(text_col, alpha)
    local outline_col = set_alpha(cfg.text_outline, alpha)
    
    local tx = wx + t.x * text_scale
    local ty = wy + t.y * text_scale 
    local est_width = (#t.text * font_size * 0.55)
    tx = tx - est_width * 0.5
    
    if r.ImGui_DrawList_AddTextEx then
      r.ImGui_DrawList_AddTextEx(dl, nil, font_size, tx - 2, ty, outline_col, t.text)
      r.ImGui_DrawList_AddTextEx(dl, nil, font_size, tx + 2, ty, outline_col, t.text)
      r.ImGui_DrawList_AddTextEx(dl, nil, font_size, tx, ty - 2, outline_col, t.text)
      r.ImGui_DrawList_AddTextEx(dl, nil, font_size, tx, ty + 2, outline_col, t.text)
      r.ImGui_DrawList_AddTextEx(dl, nil, font_size, tx, ty, text_col, t.text)
    else
      r.ImGui_DrawList_AddText(dl, tx, ty, text_col, t.text)
    end
    
    if t.is_crit then
      local blink = math.abs(math.sin(t.age * 10))
      local star_alpha = math.floor(alpha * (0.5 + 0.5 * blink))
      r.ImGui_DrawList_AddTriangleFilled(dl, tx+est_width+12*scale, ty+font_size*0.4-10, tx+est_width, ty+font_size*0.4+10, tx+est_width+24*scale, ty+font_size*0.4+10, set_alpha(cfg.coin_shimmer, star_alpha))
    end
  end
  
  -- 余额胶囊
  if state.balance_label.active and state.balance_label.alpha > 0.01 then
    local val_int = math.floor(state.balance_label.current_val)
    local text = tostring(val_int)
    
    local font_size = math.floor(22 * scale * state.balance_label.scale_punch)
    local alpha = math.floor(state.balance_label.alpha * 255)
    
    local text_w = #text * font_size * 0.6
    local icon_size = font_size * 0.7
    
    local padding_h = 10 * scale
    local padding_v = 6 * scale
    local spacing = 5 * scale
    
    local total_w = padding_h + icon_size + spacing + text_w + padding_h
    local total_h = font_size + padding_v * 2
    
    local start_x = state.target_x - total_w * 0.5
    local start_y = state.target_y - 65 * scale 
    
    local safe_margin = 10 * scale
    local win_right = state.win_x + state.win_w
    local win_left = state.win_x
    if (start_x + total_w) > (win_right - safe_margin) then
        start_x = (win_right - safe_margin) - total_w
    end
    if start_x < (win_left + safe_margin) then
        start_x = win_left + safe_margin
    end
    
    local bg_col = set_alpha(cfg.balance_bg_col, alpha)
    local border_col = set_alpha(cfg.balance_border_col, alpha)
    local text_col = set_alpha(cfg.balance_text_col, alpha)
    
    r.ImGui_DrawList_AddRectFilled(dl, start_x, start_y, start_x + total_w, start_y + total_h, bg_col, 12.0 * scale)
    r.ImGui_DrawList_AddRect(dl, start_x, start_y, start_x + total_w, start_y + total_h, border_col, 12.0 * scale, 0, 2.0 * scale)
    
    local icon_cx = start_x + padding_h + icon_size * 0.5
    local icon_cy = start_y + total_h * 0.5
    r.ImGui_DrawList_AddCircleFilled(dl, icon_cx, icon_cy, icon_size * 0.5, set_alpha(cfg.coin_gold, alpha))
    r.ImGui_DrawList_AddCircle(dl, icon_cx, icon_cy, icon_size * 0.5, border_col, 0, 1.5 * scale)
    
    local text_x = start_x + padding_h + icon_size + spacing
    local text_y = start_y + (total_h - font_size) * 0.5 - (4.5 * scale)
    
    if r.ImGui_DrawList_AddTextEx then
      r.ImGui_DrawList_AddTextEx(dl, nil, font_size, text_x, text_y, text_col, text)
    else
      r.ImGui_DrawList_AddText(dl, text_x, text_y, text_col, text)
    end
  end
end

function CoinEffect.is_active() return state.active end

return CoinEffect