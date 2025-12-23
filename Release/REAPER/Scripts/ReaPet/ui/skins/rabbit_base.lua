--[[
  Rabbit Base PNG 皮肤（图层版）
  - 使用 assets/skins/rabbit_base 下的多张 PNG：
    - desk.png       : 桌面
    - head.png       : 头部
    - face.png       : 表情
    - hand_left.png  : 左手
    - hand_right.png : 右手
  - 每张 PNG 使用相同的正方形画布（例如 1024x1024），脚本按「整张叠加」渲染
  - 表情跟随鼠标、点击时手部动作与矢量版一致
--]]

local RabbitBase = {}
---@diagnostic disable-next-line: undefined-global
local r = reaper

-- 逻辑画布尺寸（与真实 PNG 分辨率无关，只影响缩放参考）
-- 注意：保持正方形比例（1000x1000），与 PNG 图片的实际比例一致
local base_w, base_h = 1000, 1000
local ctx_ref = nil
local root_path = nil

local layer_files = {
  table      = "rabbit_base_desk.png",
  head       = "rabbit_base_head.png",
  face       = "rabbit_base_face.png",
  rest       = "rabbit_base_rest.png",  -- 休息状态的表情
  hand_left  = "rabbit_base_hand_left.png",
  hand_right = "rabbit_base_hand_right.png",
}

-- 静态位置全部交给 PNG 自己决定；这里的 base 偏移都为 0，只在动画时再加一点偏移
local layer_offsets = {
  table      = { x = 0, y = 0 },
  head       = { x = 0, y = 0 },
  face       = { x = 0, y = 0 },
  rest       = { x = 0, y = 0 },  -- 休息状态的表情偏移（与 face 相同位置）
  hand_left  = { x = 0, y = 0 },
  hand_right = { x = 0, y = 0 },
}

local placeholder_colors = {
  table = 0xFFE3F4FF,
  body = 0xFFFDE9C6,
  head = 0xFFF9D7A3,
  face = 0xFF5B3F2C,
  rest = 0xFF5B3F2C,  -- 休息状态的表情占位颜色（与 face 相同）
  hand_left = 0xFFF8CC8A,
  hand_right = 0xFFF8CC8A,
}

local layers = {}
local legacy_full = nil

-- ========= 粒子系统配置（可在开发者面板中调整）=========
local particle_config = {
  left_offset_x = 300,    -- 左手爱心水平偏移（相对于 rabbit_cx，单位：逻辑像素）
  right_offset_x = -300,  -- 右手爱心水平偏移（相对于 rabbit_cx，单位：逻辑像素）
  offset_y = -50,         -- 爱心垂直偏移（相对于 rabbit_cy，单位：逻辑像素）
  size_multiplier = 20.0, -- 爱心大小倍数（相对于基础大小）
}

-- ========= Zzz 动画配置（可在开发者面板中调整）=========
local zzz_config = {
  base_size = 19.8,       -- Z 的基础大小（乘以 scale）
  size_growth = 38.5,     -- Z 的大小增长量（乘以 scale）
  offset_x = 104.7,       -- Z 相对于脸部的水平偏移（乘以 scale）
  offset_y = -281.4,      -- Z 相对于脸部的垂直偏移（乘以 scale）
  spacing_x = 50.3,       -- 多个 Z 之间的水平间距（乘以 scale）
  move_speed_x = 57.8,    -- Z 水平移动速度（乘以 scale）
  move_speed_y = 261.6,   -- Z 垂直移动速度（乘以 scale）
  animation_speed = 0.8,  -- 动画速度（时间倍数）
  fade_start = 0.5,       -- 淡出开始比例（0.0-1.0，降低值让淡出更晚开始，更不透明）
  min_alpha = 0.4,        -- 最小透明度比例（0.0-1.0，确保即使淡出也不会完全透明）
  line_thickness_base = 2.0,  -- 线条基础粗细（乘以 scale）
  line_thickness_reduce = 0.5, -- 线条粗细减少量（乘以 scale）
  line_thickness_auto_scale = 0.15, -- 线条粗细自动缩放比例（根据 Z 大小，0.0 = 禁用自动缩放）
  face_offset_y = 0.0,    -- 脸部相对于中心的垂直偏移（乘以 scale）
}

local state = {
  left_paw_y = 0,
  right_paw_y = 0,
  left_target = 0,
  right_target = 0,
  next_hand_is_left = true,
  face_off_x = 0,
  face_off_y = 0,
  particles = {},
  scale = 1.0,
  rabbit_cx = 0,
  rabbit_cy = 0,
  last_manual_tap_time = 0,
  last_rect = nil,
}

local function file_exists(path)
  if not path or path == "" then return false end
  if r.file_exists then
    return r.file_exists(path)
  end
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end

local function try_load_image(path)
  if not path or path == "" then return nil end
  if not file_exists(path) then return nil end
  if not r.ImGui_CreateImage then return nil end

  local img = r.ImGui_CreateImage(path)
  if img and ctx_ref and r.ImGui_Attach then
    r.ImGui_Attach(ctx_ref, img)
  end
  return img
end

local function load_layer(name, file)
  layers[name] = try_load_image(root_path .. "assets/skins/rabbit_base/" .. file)
end

local function load_legacy_full()
  legacy_full =
    try_load_image(root_path .. "assets/skins/rabbit_base/rabbit_base.png") or
    try_load_image(root_path .. "assets/skins/rabbit_base/rabbit_base.jpg")
end

local function any_layer_loaded()
  for _, img in pairs(layers) do
    if img then return true end
  end
  return false
end

local function get_time()
  return r.time_precise and r.time_precise() or os.clock()
end

-- 绘制 Zzz 动画（休息状态）
local function draw_zzz_animation(dl, rect, scale)
  -- 脸部位置：在头部中心偏上的位置（参考 bongo_cat.lua）
  local face_center_x = rect.center_x + state.face_off_x * scale
  local face_center_y = rect.center_y + zzz_config.face_offset_y * scale + state.face_off_y * scale
  
  -- 使用黑色
  local zzz_color = 0x000000FF  -- 黑色
  
  local time = get_time()
  local base_zx = face_center_x + zzz_config.offset_x * scale
  local base_zy = face_center_y + zzz_config.offset_y * scale
  
  -- 计算动画周期（3个Z，每个间隔0.8秒，总周期2.4秒）
  local cycle_duration = 2.4 / zzz_config.animation_speed
  
  for i = 0, 2 do
    local t_offset = (time * zzz_config.animation_speed + i * 0.8) % cycle_duration
    local progress = t_offset / cycle_duration
    
    local z_x = base_zx + (progress * zzz_config.move_speed_x * scale) + (i * zzz_config.spacing_x * scale)
    local z_y = base_zy - (progress * zzz_config.move_speed_y * scale)
    local z_size = (zzz_config.base_size + progress * zzz_config.size_growth) * scale
    -- 计算透明度：从 0 开始淡出，从 1.0 淡出到 min_alpha
    local alpha_ratio = 1.0 - progress * (1.0 - zzz_config.min_alpha)
    local alpha = math.floor(alpha_ratio * 255)
    local z_col = (zzz_color & 0xFFFFFF00) | alpha
    -- 线条粗细：基础值 + 根据 z_size 自动缩放（让大 Z 也有粗线条）
    -- z_size 已经乘以了 scale，所以这里需要除以 scale 来获取相对大小，然后乘以配置的比例
    local size_factor = z_size / scale  -- 获取逻辑像素大小
    local auto_thickness = 0.0
    if zzz_config.line_thickness_auto_scale > 0.0 then
      auto_thickness = math.max(0.0, size_factor * zzz_config.line_thickness_auto_scale)  -- 根据大小自动调整
    end
    local z_thick = (zzz_config.line_thickness_base - progress * zzz_config.line_thickness_reduce + auto_thickness) * scale
    
    -- 可爱字体绘制逻辑：使用贝塞尔曲线让线条稍微弯曲
    r.ImGui_DrawList_PathClear(dl)
    
    -- 上横线（稍微上拱）
    local top_left_x, top_left_y = z_x, z_y
    local top_right_x, top_right_y = z_x + z_size, z_y
    
    r.ImGui_DrawList_PathLineTo(dl, top_left_x + z_size*0.1, top_left_y + z_size*0.1)
    r.ImGui_DrawList_PathBezierQuadraticCurveTo(dl, 
        z_x + z_size*0.5, z_y - z_size*0.15, -- 控制点：向上拱
        top_right_x - z_size*0.1, top_right_y + z_size*0.1, 0)
        
    -- 斜线（连接右上到左下）
    local bot_left_x, bot_left_y = z_x, z_y + z_size
    r.ImGui_DrawList_PathLineTo(dl, bot_left_x + z_size*0.1, bot_left_y - z_size*0.1)
    
    -- 下横线（稍微下拱）
    local bot_right_x, bot_right_y = z_x + z_size, z_y + z_size
    r.ImGui_DrawList_PathBezierQuadraticCurveTo(dl, 
        z_x + z_size*0.5, z_y + z_size + z_size*0.15, -- 控制点：向下拱
        bot_right_x - z_size*0.1, bot_right_y - z_size*0.1, 0)
        
    r.ImGui_DrawList_PathStroke(dl, z_col, 0, z_thick)
  end
end

local function SpawnParticle(x, y)
  local s = state.scale
  table.insert(state.particles, {
    x = x, y = y,
    -- 增大飘动范围：横向和纵向速度都增大，让爱心飘得更远
    vx = (math.random() - 0.5) * 8 * s,  -- 从 4 增加到 8
    vy = (-6 - math.random() * 4) * s,   -- 从 -3~-5 增加到 -6~-10
    life = 1.0,
    -- 使用更鲜艳的颜色，确保在 PNG 图层上可见
    color = (math.random() > 0.5) and 0xFF69B4FF or 0xFF1493FF,
    scale = s
  })
end

local function TriggerTap()
  local s = state.scale
  -- 增大手部移动幅度：从 22 增加到 60（约 2.7 倍）
  local tap_amplitude = 60 * s
  if state.next_hand_is_left then
    state.left_target = tap_amplitude
    -- 使用配置的偏移量（会乘以 scale）
    SpawnParticle(
      state.rabbit_cx + particle_config.left_offset_x * s,
      state.rabbit_cy + particle_config.offset_y * s
    )
  else
    state.right_target = tap_amplitude
    -- 使用配置的偏移量（会乘以 scale）
    SpawnParticle(
      state.rabbit_cx + particle_config.right_offset_x * s,
      state.rabbit_cy + particle_config.offset_y * s
    )
  end
  state.next_hand_is_left = not state.next_hand_is_left
end

local function update_anim(ctx, char_state)
  local speed = 0.35
  if state.left_target > 0 then
    state.left_paw_y = state.left_target
    state.left_target = 0
  else
    state.left_paw_y = state.left_paw_y + (0 - state.left_paw_y) * speed
  end
  
  if state.right_target > 0 then
    state.right_paw_y = state.right_target
    state.right_target = 0
  else
    state.right_paw_y = state.right_paw_y + (0 - state.right_paw_y) * speed
  end

  if char_state == "break" then
    state.face_off_x = state.face_off_x * 0.9
    state.face_off_y = state.face_off_y * 0.9
    if math.abs(state.face_off_x) < 0.1 then state.face_off_x = 0 end
    if math.abs(state.face_off_y) < 0.1 then state.face_off_y = 0 end
  else
    local mx, my = r.GetMousePosition()
    if r.ImGui_PointConvertNative and ctx then
      mx, my = r.ImGui_PointConvertNative(ctx, mx, my, false)
    end
    local s = state.scale
    local face_center_x = state.rabbit_cx
    local face_center_y = state.rabbit_cy - 25 * s
    -- 调整脸部跟随幅度：系数调整到 0.4，限制范围也相应调整
    local tx = (mx - face_center_x) * 0.4
    local ty = (my - face_center_y) * 0.4
    local limit_x = 80
    local limit_y = 48
    tx = math.max(-limit_x, math.min(limit_x, tx))
    ty = math.max(-limit_y, math.min(limit_y, ty))
    state.face_off_x = tx
    state.face_off_y = ty
  end
end

local function draw_placeholder_rect(dl, min_x, min_y, max_x, max_y, col)
  r.ImGui_DrawList_AddRectFilled(dl, min_x, min_y, max_x, max_y, col)
end

local function draw_layer(dl, img, min_x, min_y, draw_w, draw_h, offset_x, offset_y)
  local start_x = min_x + (offset_x or 0)
  local start_y = min_y + (offset_y or 0)
  local end_x = start_x + draw_w
  local end_y = start_y + draw_h
  if img then
    r.ImGui_DrawList_AddImage(dl, img, start_x, start_y, end_x, end_y)
    return true
  end
  return false
end

local function draw_hand(dl, side, rect, scale, extra_y)
  local img = layers[side]
  local base = layer_offsets[side] or { x = 0, y = 0 }
  -- base 偏移使用设计坐标（单位：逻辑像素），需要乘以 scale
  local offset_x = base.x * scale
  local offset_y = base.y * scale
  -- extra_y 是动画产生的屏幕像素位移（例如 22*s），不再乘 scale，直接加上
  offset_y = offset_y + (extra_y or 0)

  local drawn = draw_layer(dl, img, rect.min_x, rect.min_y, rect.draw_w, rect.draw_h, offset_x, offset_y)
  if not drawn then
    local paw_r = 40 * scale
    local cx = rect.center_x + base.x * scale
    local cy = rect.center_y + base.y * scale + (extra_y or 0)
    r.ImGui_DrawList_AddCircleFilled(dl, cx, cy, paw_r, placeholder_colors[side] or 0xFFFACC6C)
  end
end

-- 优化的爱心绘制方法：使用参数方程绘制（参考 treasure_box.lua 的实现）
-- 这是最平滑且最数学化的方法，使用参数方程生成爱心轮廓
local function draw_heart_parametric(dl, x, y, size, color)
  -- 使用参数方程绘制爱心（参考 treasure_box.lua 的 DrawHeart 函数）
  -- 参数方程：x = 16 * sin^3(t), y = -(13*cos(t) - 5*cos(2t) - 2*cos(3t) - cos(4t))
  local pts = {}
  local steps = 16
  for i = 0, steps do
    local t = (i / steps) * math.pi * 2
    local px = 16 * (math.sin(t) ^ 3)
    local py = -(13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t))
    local scale = size * 0.08
    table.insert(pts, x + px * scale)
    table.insert(pts, y + py * scale)
  end
  r.ImGui_DrawList_PathClear(dl)
  for i = 1, #pts, 2 do
    r.ImGui_DrawList_PathLineTo(dl, pts[i], pts[i+1])
  end
  r.ImGui_DrawList_PathFillConvex(dl, color)
end

-- 备用方法：优化的两个圆 + 三角形（性能更好，但不如参数方程平滑）
local function draw_heart_simple(dl, x, y, size, color)
  local s = size
  local base_radius = s * 0.35
  
  -- 顶部两个圆（稍微重叠，更平滑）
  r.ImGui_DrawList_AddCircleFilled(dl, x - s * 0.3, y - s * 0.15, base_radius, color)
  r.ImGui_DrawList_AddCircleFilled(dl, x + s * 0.3, y - s * 0.15, base_radius, color)
  
  -- 底部倒三角形（更宽，更平滑）
  r.ImGui_DrawList_AddTriangleFilled(dl,
    x - s * 0.65, y + s * 0.1,
    x + s * 0.65, y + s * 0.1,
    x, y + s * 0.5,
    color)
end

local function draw_particles(dl)
  for i = #state.particles, 1, -1 do
    local p = state.particles[i]
    p.x = p.x + p.vx
    p.y = p.y + p.vy
    p.life = p.life - 0.03
    if p.life <= 0 then
      table.remove(state.particles, i)
    else
      local alpha = math.floor(p.life * 255)
      local col = (p.color & 0xFFFFFF00) | alpha
      -- 使用配置的大小倍数
      local s = (p.scale or 1.0) * particle_config.size_multiplier
      local x, y = p.x, p.y
      
      -- 使用参数方程方法绘制爱心（最平滑，参考 treasure_box.lua）
      -- 如果参数方程方法不可用，可以改用 draw_heart_simple
      if r.ImGui_DrawList_PathLineTo and r.ImGui_DrawList_PathFillConvex then
        draw_heart_parametric(dl, x, y, s, col)
      else
        -- 降级到简单方法（两个圆 + 三角形）
        draw_heart_simple(dl, x, y, s, col)
      end
    end
  end
end

function RabbitBase.init(ctx, script_path)
  ctx_ref = ctx
  root_path = script_path or ""
  for name, file in pairs(layer_files) do
    load_layer(name, file)
  end
  load_legacy_full()
end

function RabbitBase.update(dt, char_state, ctx)
  if char_state == "operating" then
    TriggerTap()
  end
  update_anim(ctx, char_state)
end

local function compute_rect(x, y, w, h)
  local scale = math.min(w / base_w, h / base_h)
  local draw_w = base_w * scale
  local draw_h = base_h * scale
  local min_x = x + (w - draw_w) * 0.5
  local min_y = y + (h - draw_h) * 0.5
  -- 注意：center_x 和 center_y 使用窗口坐标（x + w * 0.5, y + h * 0.65），
  -- 这样在默认窗口大小时，StatsBox 的位置和之前完全一致
  -- 当窗口变窄时，图片会居中，但 center_x/center_y 仍然基于窗口，确保 UI 元素跟随图片
  return {
    min_x = min_x,
    min_y = min_y,
    draw_w = draw_w,
    draw_h = draw_h,
    max_x = min_x + draw_w,
    max_y = min_y + draw_h,
    scale = scale,
    center_x = x + w * 0.5,  -- 窗口中心（与之前一致）
    center_y = y + h * 0.65  -- 窗口高度的 65%（与之前一致）
  }
end

local function draw_composed_layers(dl, rect, char_state, skip_overlay)
  local scale = rect.scale
  state.scale = scale
  state.rabbit_cx = rect.center_x
  state.rabbit_cy = rect.center_y

  local function layer(name, extra_x, extra_y)
    local img = layers[name]
    local base = layer_offsets[name] or { x = 0, y = 0 }
    -- 静态位置完全由 PNG 内部决定，这里只负责少量动画偏移
    local offset_x = base.x * scale + (extra_x or 0)
    local offset_y = base.y * scale + (extra_y or 0)

    local drawn = draw_layer(dl, img, rect.min_x, rect.min_y, rect.draw_w, rect.draw_h, offset_x, offset_y)
    if not drawn and placeholder_colors[name] then
      draw_placeholder_rect(
        dl,
        rect.min_x + offset_x,
        rect.min_y + offset_y,
        rect.min_x + offset_x + rect.draw_w,
        rect.min_y + offset_y + rect.draw_h,
        placeholder_colors[name]
      )
    end
  end

  -- 绘制顺序（由下到上）：
  -- 1. 头部（静止，不做 bob 动画）
  layer("head", 0, 0)
  -- 2. 脸部表情（根据状态选择：休息时使用 rest，否则使用 face）
  -- 注意：face_off_x/face_off_y 需要乘以 scale，保持视觉比例一致
  -- 休息状态时，面部会平滑回正（由 update_anim 处理），所以偏移会逐渐变为 0
  if char_state == "break" then
    layer("rest", state.face_off_x * scale, state.face_off_y * scale)
    -- 在休息状态时，绘制 Zzz 动画（在 rest 图层之上）
    draw_zzz_animation(dl, rect, scale)
  else
    layer("face", state.face_off_x * scale, state.face_off_y * scale)
  end
  -- 3. 桌面（在头和脸之上，在手之下）
  layer("table")

  -- 注意：手和粒子不在主绘制阶段绘制，而是在 draw_paws 中绘制（确保在最上层）
end

local function draw_legacy(dl, rect)
  if not legacy_full then return end
  r.ImGui_DrawList_AddImage(dl, legacy_full, rect.min_x, rect.min_y, rect.max_x, rect.max_y)
end

function RabbitBase.draw(ctx, dl, x, y, w, h, char_state, skip_overlay)
  if not root_path then return end
  local rect = compute_rect(x, y, w, h)
  state.last_rect = rect

  if any_layer_loaded() then
    draw_composed_layers(dl, rect, char_state, skip_overlay)
  elseif legacy_full then
    draw_legacy(dl, rect)
  end
end

function RabbitBase.draw_paws(ctx, dl, x, y, w, h)
  -- 在前景阶段单独绘制手和粒子（确保手和粒子在所有 PNG 图层之上）
  if not state.last_rect then return end
  if not any_layer_loaded() then return end
  local rect = state.last_rect
  if not rect or not rect.scale then return end
  local scale = rect.scale
  
  -- 先绘制手
  draw_hand(dl, "hand_left", rect, scale, state.left_paw_y)
  draw_hand(dl, "hand_right", rect, scale, state.right_paw_y)
  
  -- 最后绘制粒子（确保在最上层，不会被任何图层遮挡）
  draw_particles(dl)
end

-- 获取当前绘制区域信息（供其他模块使用，确保 UI 元素与图片保持相对位置）
function RabbitBase.get_draw_rect()
  return state.last_rect
end

function RabbitBase.get_recommended_size()
  -- 推荐窗口尺寸：与 BongoCat 保持一致（300x200）
  return 300, 200
end

function RabbitBase.trigger_action(action_type, is_manual)
  if action_type == "tap_left" or action_type == "tap_right" or action_type == "tap" then
    TriggerTap()
    if is_manual then
      state.last_manual_tap_time = get_time()
    end
  elseif action_type == "celebrate" then
    local s = state.scale
    -- 使用配置的偏移量
    SpawnParticle(state.rabbit_cx + particle_config.left_offset_x * s, state.rabbit_cy + particle_config.offset_y * s)
    SpawnParticle(state.rabbit_cx + particle_config.right_offset_x * s, state.rabbit_cy + particle_config.offset_y * s)
  end
end

-- 获取粒子系统配置（供开发者面板使用）
function RabbitBase.get_particle_config()
  return particle_config
end

-- 设置粒子系统配置（供开发者面板使用）
function RabbitBase.set_particle_config(new_config)
  if new_config then
    if new_config.left_offset_x ~= nil then particle_config.left_offset_x = new_config.left_offset_x end
    if new_config.right_offset_x ~= nil then particle_config.right_offset_x = new_config.right_offset_x end
    if new_config.offset_y ~= nil then particle_config.offset_y = new_config.offset_y end
    if new_config.size_multiplier ~= nil then particle_config.size_multiplier = new_config.size_multiplier end
  end
end

-- 获取 Zzz 动画配置（供开发者面板使用）
function RabbitBase.get_zzz_config()
  return zzz_config
end

-- 设置 Zzz 动画配置（供开发者面板使用）
function RabbitBase.set_zzz_config(new_config)
  if new_config then
    if new_config.base_size ~= nil then zzz_config.base_size = new_config.base_size end
    if new_config.size_growth ~= nil then zzz_config.size_growth = new_config.size_growth end
    if new_config.offset_x ~= nil then zzz_config.offset_x = new_config.offset_x end
    if new_config.offset_y ~= nil then zzz_config.offset_y = new_config.offset_y end
    if new_config.spacing_x ~= nil then zzz_config.spacing_x = new_config.spacing_x end
    if new_config.move_speed_x ~= nil then zzz_config.move_speed_x = new_config.move_speed_x end
    if new_config.move_speed_y ~= nil then zzz_config.move_speed_y = new_config.move_speed_y end
    if new_config.animation_speed ~= nil then zzz_config.animation_speed = new_config.animation_speed end
    if new_config.fade_start ~= nil then zzz_config.fade_start = new_config.fade_start end
    if new_config.min_alpha ~= nil then zzz_config.min_alpha = new_config.min_alpha end
    if new_config.line_thickness_base ~= nil then zzz_config.line_thickness_base = new_config.line_thickness_base end
    if new_config.line_thickness_reduce ~= nil then zzz_config.line_thickness_reduce = new_config.line_thickness_reduce end
    if new_config.line_thickness_auto_scale ~= nil then zzz_config.line_thickness_auto_scale = new_config.line_thickness_auto_scale end
    if new_config.face_offset_y ~= nil then zzz_config.face_offset_y = new_config.face_offset_y end
  end
end

function RabbitBase.get_last_manual_tap_time()
  return state.last_manual_tap_time or 0
end

return RabbitBase

