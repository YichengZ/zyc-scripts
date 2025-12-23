--[[
  REAPER Companion - 变身特效 (Skin Unlock / Transformation)
  流程：掉落礼物盒 -> 落地弹跳 -> 剧烈抖动 -> 爆炸烟雾 -> 变身新角色
  风格：San-X 治愈系，喜庆，可爱
--]]

local TransformationEffect = {}
local ObjectPool = require('utils.object_pool')
local r = reaper

-- 状态枚举
local PHASE = {
  IDLE = 0,
  DROPPING = 1,
  BOUNCING = 2,
  SHAKING = 3,
  EXPLODING = 4
}

-- 粒子类型
local P_TYPE = {
  CIRCLE = 1,   -- 泡泡/圆点
  CONFETTI = 2, -- 彩带
  STAR = 3,     -- 星星
  HEART = 4     -- 爱心
}

-- San-X 配色方案
local PALETTE = {
  box_bg = 0xFFF59DFF,       -- 柔和的亮黄色/奶油色
  box_flat = 0xFFF176FF,     -- 纯色填充
  ribbon = 0xFF7043FF,       -- 珊瑚红
  ribbon_dark = 0xD84315FF,  -- 深红
  bow_center = 0xFF8A65FF,   -- 蝴蝶结中心
  outline = 0x5D4037FF,      -- 深棕色轮廓 (San-X 经典)
  
  -- 高亮糖果色系 (参考 TreasureBox)
  candy = { 
    0xFF94C2FF, -- Bright Pink
    0x81D4FAFF, -- High Blue
    0xB2FF59FF, -- Neon Green
    0xE0B0FFFF, -- Bright Mauve
    0xFFFF8DFF, -- Primrose
    0xFFCC80FF, -- Bright Apricot
    0xFFFFFFFF  -- White
  },
  
  -- 聚光灯颜色
  spotlight = 0xFFEE5830
}

-- 内部状态
local state = {
  is_active = false,
  phase = PHASE.IDLE,
  timer = 0,
  
  -- 物理属性
  box_x = 0,
  box_y = -100, -- 这里的 box_y 代表盒子【底部】坐标
  box_vy = 0,
  target_floor_y = 0,
  scale = 1.0,
  
  -- 视觉属性
  box_rotation = 0,
  box_squash = 1.0, -- 挤压变形 (Y轴缩放)
  shake_offset_x = 0,
  shake_offset_y = 0,
  spotlight_angle = 0, -- 聚光灯旋转角度
  
  -- 逻辑回调
  target_skin_id = nil,
  unlock_callback = nil,
  skin_switched = false,
  
  -- 粒子系统
  particles = {},
  particle_pool = nil
}

-- 配置参数
local cfg = {
  gravity = 3000.0, -- 增加重力，更有分量感
  bounce_damping = 0.4, -- 减少反弹高度
  shake_duration = 1.2,
  shake_intensity = 6.0,
  box_size = 70, 
  
  explosion_force = 600,
}

-- ========= 辅助函数 =========
local function set_alpha(col, alpha)
  return (col & 0xFFFFFF00) | math.floor(math.max(0, math.min(255, alpha)))
end

local function rotate_point(cx, cy, x, y, angle)
  if angle == 0 then return x, y end
  local s = math.sin(angle)
  local c = math.cos(angle)
  local tx = x - cx
  local ty = y - cy
  return (tx * c - ty * s) + cx, (tx * s + ty * c) + cy
end

-- 预计算星星数据 (归一化坐标)
local STAR_VERTS = {}
for i = 0, 9 do
  local angle = (i / 10) * math.pi * 2 - (math.pi / 2)
  local r = (i % 2 == 0) and 1.0 or 0.55
  table.insert(STAR_VERTS, {math.cos(angle) * r, math.sin(angle) * r})
end

-- ========= 初始化 =========
function TransformationEffect.init()
  state.is_active = false
  state.phase = PHASE.IDLE
  state.particles = {}
  
  -- 初始化粒子池
  state.particle_pool = ObjectPool.new(function() return {
    active = false,
    type = P_TYPE.CIRCLE,
    x=0, y=0, vx=0, vy=0, 
    life=0, max_life=0, 
    size=0, color=0, 
    rotation=0, rot_speed=0,
    sway_phase=0, sway_speed=0, sway_amp=0,
    w=0, h=0 
  } end, 300)
end

-- ========= 触发特效 =========
function TransformationEffect.trigger_unlock(skin_id, center_x, floor_y, scale, callback)
  state.is_active = true
  state.phase = PHASE.DROPPING
  state.timer = 0
  
  state.target_skin_id = skin_id
  state.unlock_callback = callback
  state.skin_switched = false
  
  state.scale = scale or 1.0
  state.box_x = center_x
  -- 初始高度：降低一点，减少过高的弹跳感
  state.box_y = -100 * state.scale 
  state.box_vy = 0
  -- 目标地面：直接对齐 floor_y (盒子底部)
  state.target_floor_y = floor_y
  
  state.box_rotation = 0
  state.box_squash = 1.0
  state.shake_offset_x = 0
  state.shake_offset_y = 0
  state.spotlight_angle = 0
  
  -- 清理旧粒子
  for _, p in ipairs(state.particles) do state.particle_pool:release(p) end
  state.particles = {}
end

function TransformationEffect.trigger()
  -- 兼容旧接口
  state.is_active = true
  state.phase = PHASE.EXPLODING
  state.timer = 0
  state.skin_switched = true
end

-- ========= 粒子生成 =========
local function spawn_particle(type, x, y, scale)
  local p = state.particle_pool:get()
  p.active = true
  p.type = type
  p.x = x
  p.y = y
  p.rotation = math.random() * 6.28
  p.life = 0
  p.max_life = 0.8 + math.random() * 0.6
  p.color = PALETTE.candy[math.random(#PALETTE.candy)]
  
  local angle = math.random() * 6.28
  local speed = math.random(100, 500) * scale
  p.vx = math.cos(angle) * speed
  p.vy = math.sin(angle) * speed - 100 * scale -- 稍微向上
  
  if type == P_TYPE.CIRCLE then
    p.size = (10 + math.random() * 20) * scale
    p.rot_speed = 0
    p.max_life = 1.0 + math.random() * 0.5
    
  elseif type == P_TYPE.CONFETTI then
    p.w = (8 + math.random() * 8) * scale
    p.h = (4 + math.random() * 4) * scale
    p.size = p.w 
    p.max_life = 2.0 + math.random() * 1.5 
    p.rot_speed = (math.random() - 0.5) * 15.0 
    p.vy = p.vy - 300 * scale -- 向上抛得更高
    
    -- 摇摆参数
    p.sway_phase = math.random() * 10
    p.sway_speed = math.random() * 3 + 2
    p.sway_amp = math.random() * 2.0 * scale
    
  elseif type == P_TYPE.STAR then
    p.size = (15 + math.random() * 15) * scale
    p.rot_speed = 5.0
    p.vy = p.vy - 200 * scale
    
  elseif type == P_TYPE.HEART then
    p.size = (15 + math.random() * 15) * scale
    p.rot_speed = (math.random() - 0.5) * 2.0
    p.vy = p.vy - 150 * scale
    p.sway_phase = math.random() * 10
    p.sway_speed = math.random() * 2 + 1
    p.sway_amp = math.random() * 1.5 * scale
  end
  
  table.insert(state.particles, p)
end

-- ========= 更新逻辑 =========
function TransformationEffect.update(dt)
  if not state.is_active then return false end
  
  -- 更新聚光灯
  if state.phase == PHASE.EXPLODING or state.phase == PHASE.SHAKING then
    state.spotlight_angle = state.spotlight_angle + dt * 0.5
  end
  
  -- 物理更新
  if state.phase == PHASE.DROPPING then
    state.box_vy = state.box_vy + cfg.gravity * dt
    state.box_y = state.box_y + state.box_vy * dt
    state.box_squash = 1.0 + (state.box_vy / 4000.0) -- 拉长
    
    if state.box_y >= state.target_floor_y then
      state.box_y = state.target_floor_y
      state.box_vy = -state.box_vy * cfg.bounce_damping
      state.phase = PHASE.BOUNCING
      state.box_squash = 0.6 -- 落地挤压
    end
    
  elseif state.phase == PHASE.BOUNCING then
    state.box_vy = state.box_vy + cfg.gravity * dt
    state.box_y = state.box_y + state.box_vy * dt
    
    -- 恢复形状
    state.box_squash = state.box_squash + (1.0 - state.box_squash) * dt * 10
    
    if state.box_y >= state.target_floor_y then
      state.box_y = state.target_floor_y
      if math.abs(state.box_vy) < 150 * state.scale then
        state.box_vy = 0
        state.phase = PHASE.SHAKING
        state.timer = 0
        state.box_squash = 1.0
      else
        state.box_vy = -state.box_vy * cfg.bounce_damping
      end
    end
    
  elseif state.phase == PHASE.SHAKING then
    state.timer = state.timer + dt
    
    local intensity = cfg.shake_intensity * state.scale
    local progress = state.timer / cfg.shake_duration
    intensity = intensity * (1.0 + progress * 3.0) -- 越来越剧烈
    
    -- 左右摇晃 (Rotation)
    -- 随时间加快摇摆频率和幅度
    local shake_speed = 25.0 + progress * 20.0 
    local max_angle = 0.15 + progress * 0.25 -- 最大约 23度
    state.box_rotation = math.sin(state.timer * shake_speed) * max_angle
    
    -- 轻微位移 (只向上)
    state.shake_offset_x = (math.random() - 0.5) * intensity * 0.5
    state.shake_offset_y = -math.abs(math.random() * intensity * 0.5) 
    
    -- 挤压动画：准备爆炸
    if progress > 0.8 then
       state.box_squash = 1.0 - (progress - 0.8) * 2.0 -- 压扁
    end
    
    if state.timer >= cfg.shake_duration then
      state.phase = PHASE.EXPLODING
      state.timer = 0
      
      -- 爆炸！生成大量粒子
      local scale = state.scale
      local center_y = state.box_y - cfg.box_size * scale * 0.5
      
      for i=1, 40 do spawn_particle(P_TYPE.CIRCLE, state.box_x, center_y, scale) end
      for i=1, 60 do spawn_particle(P_TYPE.CONFETTI, state.box_x, center_y, scale) end
      for i=1, 30 do spawn_particle(P_TYPE.STAR, state.box_x, center_y, scale) end
      for i=1, 20 do spawn_particle(P_TYPE.HEART, state.box_x, center_y, scale) end
    end
    
  elseif state.phase == PHASE.EXPLODING then
    state.timer = state.timer + dt
    
    -- 延迟一小会儿再切换皮肤
    if state.timer > 0.1 and state.unlock_callback and not state.skin_switched then
      state.unlock_callback()
      state.skin_switched = true
    end
    
    -- 粒子更新
    for i = #state.particles, 1, -1 do
      local p = state.particles[i]
      p.life = p.life + dt
      
      -- 物理
      p.x = p.x + p.vx * dt
      p.y = p.y + p.vy * dt
      p.rotation = p.rotation + p.rot_speed * dt
      p.vx = p.vx * 0.95 -- 阻力
      p.vy = p.vy * 0.95
      
      if p.type == P_TYPE.CONFETTI or p.type == P_TYPE.HEART then
        p.vy = p.vy + 400 * state.scale * dt -- 重力较小，飘落
        -- 摇摆
        if p.vy > 0 then
          local sway = math.sin(p.life * p.sway_speed + p.sway_phase) * p.sway_amp
          p.x = p.x + sway
          if p.type == P_TYPE.CONFETTI then
             p.rotation = p.rotation + sway * 0.1
          end
        end
      else
        p.vy = p.vy + 200 * state.scale * dt -- 其他粒子重力更小
      end
      
      if p.life >= p.max_life then
        state.particle_pool:release(p)
        table.remove(state.particles, i)
      end
    end
    
    if #state.particles == 0 and state.timer > 2.0 then
      state.is_active = false
      state.phase = PHASE.IDLE
    end
  end
  
  return true
end

-- ========= 绘制函数 =========
local function draw_spotlight(dl, cx, cy, scale, angle, alpha_factor, size_factor)
  local radius = 400 * scale * (size_factor or 1.0)
  local count = 7
  -- 聚光灯：暖黄色，基础透明度较低 (0x30 = ~48)
  local base_col = PALETTE.spotlight
  local base_alpha = base_col & 0xFF
  local final_alpha = math.floor(base_alpha * (alpha_factor or 1.0))
  local col = (base_col & 0xFFFFFF00) | final_alpha
  
  if final_alpha <= 1 then return end
  
  for i=0, count-1 do
    local a = angle + (i / count) * math.pi * 2
    local width = 0.25 -- 扇形宽度
    
    r.ImGui_DrawList_PathClear(dl)
    r.ImGui_DrawList_PathLineTo(dl, cx, cy)
    r.ImGui_DrawList_PathLineTo(dl, cx + math.cos(a - width)*radius, cy + math.sin(a - width)*radius)
    r.ImGui_DrawList_PathLineTo(dl, cx + math.cos(a + width)*radius, cy + math.sin(a + width)*radius)
    r.ImGui_DrawList_PathFillConvex(dl, col)
  end
end

local function draw_star_optimized(dl, cx, cy, size, col)
  r.ImGui_DrawList_PathClear(dl)
  local v = STAR_VERTS
  for i = 1, #STAR_VERTS do
    r.ImGui_DrawList_PathLineTo(dl, cx + v[i][1]*size, cy + v[i][2]*size)
  end
  r.ImGui_DrawList_PathFillConvex(dl, col)
end

local function draw_heart(dl, cx, cy, size, col)
  local scale = size * 0.5
  -- 贝塞尔曲线绘制心形
  local x0, y0 = cx, cy - scale * 0.4
  local x_bottom, y_bottom = cx, cy + scale * 0.9
  
  local x_l1, y_l1 = cx - scale * 1.3, cy - scale * 1.3 
  local x_l2, y_l2 = cx - scale * 1.3, cy + scale * 0.4 
  
  local x_r1, y_r1 = cx + scale * 1.3, cy - scale * 1.3 
  local x_r2, y_r2 = cx + scale * 1.3, cy + scale * 0.4 
  
  r.ImGui_DrawList_PathClear(dl)
  r.ImGui_DrawList_PathLineTo(dl, x0, y0)
  r.ImGui_DrawList_PathBezierCubicCurveTo(dl, x_l1, y_l1, x_l2, y_l2, x_bottom, y_bottom)
  r.ImGui_DrawList_PathBezierCubicCurveTo(dl, x_r2, y_r2, x_r1, y_r1, x0, y0)
  r.ImGui_DrawList_PathFillConvex(dl, col)
end

local function draw_confetti(dl, p)
  local alpha = math.floor(255 * (1 - p.life/p.max_life))
  local col = set_alpha(p.color, alpha)
  
  -- 旋转矩形
  local c, s = math.cos(p.rotation), math.sin(p.rotation)
  local hw, hh = p.w * 0.5, p.h * 0.5
  
  local x1, y1 = p.x + (-hw*c - -hh*s), p.y + (-hw*s + -hh*c)
  local x2, y2 = p.x + (hw*c - -hh*s), p.y + (hw*s + -hh*c)
  local x3, y3 = p.x + (hw*c - hh*s), p.y + (hw*s + hh*c)
  local x4, y4 = p.x + (-hw*c - hh*s), p.y + (-hw*s + hh*c)
  
  r.ImGui_DrawList_AddQuadFilled(dl, x1, y1, x2, y2, x3, y3, x4, y4, col)
end

local function draw_sanx_box(dl, cx, cy, size, squash, offset_x, offset_y, rotation)
  local w = size * 1.2
  local h = size * squash
  
  -- 盖子参数
  local lid_h = h * 0.25
  local lid_w = w * 1.1 -- 盖子比盒子宽一点
  local body_h = h - lid_h
  local rw = w * 0.15 -- 丝带宽度
  
  -- 旋转中心：底部中心
  local pivot_x = cx + offset_x
  local pivot_y = cy + offset_y + 4.0
  
  -- 变换函数
  local function t(lx, ly)
    return rotate_point(pivot_x, pivot_y, pivot_x + lx, pivot_y + ly, rotation or 0)
  end
  
  -- 如果有旋转，使用 Quad 模拟
  if rotation and math.abs(rotation) > 0.01 then
    -- 1. 盒身 (Body)
    local b_tl_y = -body_h
    local b_br_y = 0
    
    local b1x, b1y = t(-w*0.5, b_tl_y); local b2x, b2y = t(w*0.5, b_tl_y)
    local b3x, b3y = t(w*0.5, b_br_y);  local b4x, b4y = t(-w*0.5, b_br_y)
    
    r.ImGui_DrawList_AddQuadFilled(dl, b1x, b1y, b2x, b2y, b3x, b3y, b4x, b4y, PALETTE.box_flat)
    r.ImGui_DrawList_AddQuad(dl, b1x, b1y, b2x, b2y, b3x, b3y, b4x, b4y, PALETTE.outline, 3.0)
    
    -- 2. 盒身丝带
    local rb1x, rb1y = t(-rw*0.5, b_tl_y); local rb2x, rb2y = t(rw*0.5, b_tl_y)
    local rb3x, rb3y = t(rw*0.5, b_br_y);  local rb4x, rb4y = t(-rw*0.5, b_br_y)
    r.ImGui_DrawList_AddQuadFilled(dl, rb1x, rb1y, rb2x, rb2y, rb3x, rb3y, rb4x, rb4y, PALETTE.ribbon)
    
    -- 3. 盒盖 (Lid)
    local l_tl_y = -h
    local l_br_y = -body_h
    
    local l1x, l1y = t(-lid_w*0.5, l_tl_y); local l2x, l2y = t(lid_w*0.5, l_tl_y)
    local l3x, l3y = t(lid_w*0.5, l_br_y);  local l4x, l4y = t(-lid_w*0.5, l_br_y)
    
    r.ImGui_DrawList_AddQuadFilled(dl, l1x, l1y, l2x, l2y, l3x, l3y, l4x, l4y, PALETTE.box_flat)
    r.ImGui_DrawList_AddQuad(dl, l1x, l1y, l2x, l2y, l3x, l3y, l4x, l4y, PALETTE.outline, 3.0)
    
    -- 4. 盒盖丝带
    local rl1x, rl1y = t(-rw*0.5, l_tl_y); local rl2x, rl2y = t(rw*0.5, l_tl_y)
    local rl3x, rl3y = t(rw*0.5, l_br_y);  local rl4x, rl4y = t(-rw*0.5, l_br_y)
    r.ImGui_DrawList_AddQuadFilled(dl, rl1x, rl1y, rl2x, rl2y, rl3x, rl3y, rl4x, rl4y, PALETTE.ribbon)
    
    -- 5. 蝴蝶结
    local bow_size = w * 0.35
    local bc_x, bc_y = t(0, -h)
    local el_x, el_y = t(-bow_size*0.8, -h)
    local er_x, er_y = t(bow_size*0.8, -h)
    
    r.ImGui_DrawList_AddCircleFilled(dl, el_x, el_y, bow_size*0.6, PALETTE.ribbon)
    r.ImGui_DrawList_AddCircle(dl, el_x, el_y, bow_size*0.6, PALETTE.outline, 0, 2.5)
    r.ImGui_DrawList_AddCircleFilled(dl, er_x, er_y, bow_size*0.6, PALETTE.ribbon)
    r.ImGui_DrawList_AddCircle(dl, er_x, er_y, bow_size*0.6, PALETTE.outline, 0, 2.5)
    r.ImGui_DrawList_AddCircleFilled(dl, bc_x, bc_y, bow_size*0.3, PALETTE.bow_center)
    r.ImGui_DrawList_AddCircle(dl, bc_x, bc_y, bow_size*0.3, PALETTE.outline, 0, 2.5)
    return
  end
  
  -- 无旋转 (使用 Rect)
  local x = cx + offset_x
  local bottom_y = cy + offset_y + 4.0
  local top_y = bottom_y - h
  local mid_y = bottom_y - body_h
  
  -- 盒身
  r.ImGui_DrawList_AddRectFilled(dl, x - w*0.5, mid_y, x + w*0.5, bottom_y, PALETTE.box_flat, 4.0, r.ImGui_DrawFlags_RoundCornersBottom())
  r.ImGui_DrawList_AddRect(dl, x - w*0.5, mid_y, x + w*0.5, bottom_y, PALETTE.outline, 4.0, r.ImGui_DrawFlags_RoundCornersBottom(), 3.0)
  
  -- 盒身丝带
  r.ImGui_DrawList_AddRectFilled(dl, x - rw*0.5, mid_y, x + rw*0.5, bottom_y, PALETTE.ribbon)
  r.ImGui_DrawList_AddLine(dl, x - rw*0.5, mid_y, x - rw*0.5, bottom_y, PALETTE.outline, 2.0)
  r.ImGui_DrawList_AddLine(dl, x + rw*0.5, mid_y, x + rw*0.5, bottom_y, PALETTE.outline, 2.0)
  
  -- 盒盖
  r.ImGui_DrawList_AddRectFilled(dl, x - lid_w*0.5, top_y, x + lid_w*0.5, mid_y, PALETTE.box_flat, 4.0)
  r.ImGui_DrawList_AddRect(dl, x - lid_w*0.5, top_y, x + lid_w*0.5, mid_y, PALETTE.outline, 4.0, 0, 3.0)
  
  -- 盒盖丝带
  r.ImGui_DrawList_AddRectFilled(dl, x - rw*0.5, top_y, x + rw*0.5, mid_y, PALETTE.ribbon)
  r.ImGui_DrawList_AddLine(dl, x - rw*0.5, top_y, x - rw*0.5, mid_y, PALETTE.outline, 2.0)
  r.ImGui_DrawList_AddLine(dl, x + rw*0.5, top_y, x + rw*0.5, mid_y, PALETTE.outline, 2.0)
  
  -- 蝴蝶结
  local bow_y = top_y - 5
  local bow_size = w * 0.35
  r.ImGui_DrawList_AddCircleFilled(dl, x - bow_size*0.8, bow_y, bow_size*0.6, PALETTE.ribbon)
  r.ImGui_DrawList_AddCircle(dl, x - bow_size*0.8, bow_y, bow_size*0.6, PALETTE.outline, 0, 2.5)
  r.ImGui_DrawList_AddCircleFilled(dl, x + bow_size*0.8, bow_y, bow_size*0.6, PALETTE.ribbon)
  r.ImGui_DrawList_AddCircle(dl, x + bow_size*0.8, bow_y, bow_size*0.6, PALETTE.outline, 0, 2.5)
  r.ImGui_DrawList_AddCircleFilled(dl, x, bow_y, bow_size*0.3, PALETTE.bow_center)
  r.ImGui_DrawList_AddCircle(dl, x, bow_y, bow_size*0.3, PALETTE.outline, 0, 2.5)
end

function TransformationEffect.draw(ctx, dl)
  if not state.is_active then return end
  
  -- 1. 聚光灯 (背景)
  local sp_alpha = 0
  local sp_scale = 1.0
  
  if state.phase == PHASE.SHAKING then
    -- 进入动画：淡入 + 伸展
    local t = math.min(1.0, state.timer / 0.5) -- 0.5秒淡入
    sp_alpha = t
    sp_scale = math.sin(t * math.pi * 0.5) -- Ease out sine
    
  elseif state.phase == PHASE.EXPLODING then
    -- 退出动画：淡出 + 扩散
    local t = math.min(1.0, state.timer / 0.6) -- 0.6秒淡出
    sp_alpha = 1.0 - t
    sp_scale = 1.0 + t * 0.2
  end
  
  if sp_alpha > 0.01 then
    local center_y = state.target_floor_y - cfg.box_size * state.scale * 0.5
    draw_spotlight(dl, state.box_x, center_y, state.scale, state.spotlight_angle, sp_alpha, sp_scale)
  end
  
  -- 2. 盒子 (除了爆炸阶段)
  if state.phase ~= PHASE.EXPLODING and state.phase ~= PHASE.IDLE then
    draw_sanx_box(dl, 
      state.box_x, state.box_y, 
      cfg.box_size * state.scale, 
      state.box_squash,
      state.shake_offset_x, state.shake_offset_y,
      state.box_rotation -- 传入旋转
    )
  end
  
  -- 3. 粒子
  for _, p in ipairs(state.particles) do
    local alpha = math.floor(255 * (1 - p.life/p.max_life))
    
    if p.type == P_TYPE.CIRCLE then
      r.ImGui_DrawList_AddCircleFilled(dl, p.x, p.y, p.size, set_alpha(p.color, alpha))
    elseif p.type == P_TYPE.CONFETTI then
      draw_confetti(dl, p)
    elseif p.type == P_TYPE.STAR then
      draw_star_optimized(dl, p.x, p.y, p.size, set_alpha(p.color, alpha))
    elseif p.type == P_TYPE.HEART then
      draw_heart(dl, p.x, p.y, p.size, set_alpha(p.color, alpha))
    end
  end
end

function TransformationEffect.is_active() return state.is_active end

return TransformationEffect