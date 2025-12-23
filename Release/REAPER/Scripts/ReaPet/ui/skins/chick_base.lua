--[[
  Chick Base PNG 皮肤（性能优化版）
  优化点：
  1. 心形轮廓预计算：消除每帧数百次的 math.sin/cos 三角函数运算。
  2. 内存复用：compute_rect 和 粒子绘制不再每帧创建新 Table，消除 GC 造成的周期性卡顿。
--]]

local ChickBase = {}
---@diagnostic disable-next-line: undefined-global
local r = reaper

local base_w, base_h = 1000, 1000
local ctx_ref = nil
local root_path = nil

local layer_files = {
  table      = "chick_base_desk.png",
  head       = "chick_base_head.png",
  face       = "chick_base_face.png",
  rest       = "chick_base_rest.png",
  hand_left  = "chick_base_hand_left.png",
  hand_right = "chick_base_hand_right.png",
}

local layer_offsets = {
  table      = { x = 0, y = 0 },
  head       = { x = 0, y = 0 },
  face       = { x = 0, y = 0 },
  rest       = { x = 0, y = 0 },
  hand_left  = { x = 0, y = 0 },
  hand_right = { x = 0, y = 0 },
}

local placeholder_colors = {
  table = 0xFFE3F4FF,
  body = 0xFFFFF9C6,
  head = 0xFFFFE8A3,
  face = 0xFF5B3F2C,
  rest = 0xFF5B3F2C,
  hand_left = 0xFFFFD88A,
  hand_right = 0xFFFFD88A,
}

local layers = {}
local legacy_full = nil

-- [优化] 预分配 Rect 对象，避免每帧 GC
local rect_cache = {
  min_x = 0, min_y = 0, draw_w = 0, draw_h = 0,
  max_x = 0, max_y = 0, scale = 1,
  center_x = 0, center_y = 0
}

-- [优化] 心形预计算缓存
local heart_shape_cache = {}
local function precompute_heart_shape()
  local steps = 16
  for i = 0, steps do
    local t = (i / steps) * math.pi * 2
    -- 标准化参数方程
    local x = 16 * (math.sin(t) ^ 3)
    local y = -(13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t))
    -- 归一化 (大概范围在 -16 到 16 之间，我们存原始值，绘制时缩放)
    table.insert(heart_shape_cache, {x = x, y = y})
  end
end
precompute_heart_shape() -- 加载脚本时立即计算一次

local particle_config = {
  left_offset_x = 300,
  right_offset_x = -300,
  offset_y = -50,
  size_multiplier = 20.0,
}

local zzz_config = {
  base_size = 19.8, size_growth = 38.5, offset_x = 104.7, offset_y = -281.4,
  spacing_x = 50.3, move_speed_x = 57.8, move_speed_y = 261.6, animation_speed = 0.8,
  fade_start = 0.5, min_alpha = 0.4,
  line_thickness_base = 2.0, line_thickness_reduce = 0.5, line_thickness_auto_scale = 0.15,
  face_offset_y = 0.0,
}

local state = {
  left_paw_y = 0, right_paw_y = 0,
  left_target = 0, right_target = 0,
  next_hand_is_left = true,
  face_off_x = 0, face_off_y = 0,
  particles = {},
  scale = 1.0,
  chick_cx = 0, chick_cy = 0,
  last_manual_tap_time = 0,
  last_rect = nil,
}

local function file_exists(path)
  if not path or path == "" then return false end
  if r.file_exists then return r.file_exists(path) end
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
  layers[name] = try_load_image(root_path .. "assets/skins/chick_base/" .. file)
end

local function load_legacy_full()
  legacy_full =
    try_load_image(root_path .. "assets/skins/chick_base/chick_base.png") or
    try_load_image(root_path .. "assets/skins/chick_base/chick_base.jpg")
end

local function any_layer_loaded()
  for _, img in pairs(layers) do if img then return true end end
  return false
end

local function get_time()
  return r.time_precise and r.time_precise() or os.clock()
end

-- 绘制 Zzz 动画
local function draw_zzz_animation(dl, rect, scale)
  local face_center_x = rect.center_x + state.face_off_x * scale
  local face_center_y = rect.center_y + zzz_config.face_offset_y * scale + state.face_off_y * scale
  local zzz_color = 0x000000FF
  local time = get_time()
  local base_zx = face_center_x + zzz_config.offset_x * scale
  local base_zy = face_center_y + zzz_config.offset_y * scale
  local cycle_duration = 2.4 / zzz_config.animation_speed
  
  for i = 0, 2 do
    local t_offset = (time * zzz_config.animation_speed + i * 0.8) % cycle_duration
    local progress = t_offset / cycle_duration
    
    local z_x = base_zx + (progress * zzz_config.move_speed_x * scale) + (i * zzz_config.spacing_x * scale)
    local z_y = base_zy - (progress * zzz_config.move_speed_y * scale)
    local z_size = (zzz_config.base_size + progress * zzz_config.size_growth) * scale
    local alpha_ratio = 1.0 - progress * (1.0 - zzz_config.min_alpha)
    local alpha = math.floor(alpha_ratio * 255)
    local z_col = (zzz_color & 0xFFFFFF00) | alpha
    
    local size_factor = z_size / scale
    local auto_thickness = 0.0
    if zzz_config.line_thickness_auto_scale > 0.0 then
      auto_thickness = math.max(0.0, size_factor * zzz_config.line_thickness_auto_scale)
    end
    local z_thick = (zzz_config.line_thickness_base - progress * zzz_config.line_thickness_reduce + auto_thickness) * scale
    
    r.ImGui_DrawList_PathClear(dl)
    local top_left_x, top_left_y = z_x, z_y
    local top_right_x, top_right_y = z_x + z_size, z_y
    
    r.ImGui_DrawList_PathLineTo(dl, top_left_x + z_size*0.1, top_left_y + z_size*0.1)
    r.ImGui_DrawList_PathBezierQuadraticCurveTo(dl, 
        z_x + z_size*0.5, z_y - z_size*0.15,
        top_right_x - z_size*0.1, top_right_y + z_size*0.1, 0)
        
    local bot_left_x, bot_left_y = z_x, z_y + z_size
    r.ImGui_DrawList_PathLineTo(dl, bot_left_x + z_size*0.1, bot_left_y - z_size*0.1)
    
    local bot_right_x, bot_right_y = z_x + z_size, z_y + z_size
    r.ImGui_DrawList_PathBezierQuadraticCurveTo(dl, 
        z_x + z_size*0.5, z_y + z_size + z_size*0.15,
        bot_right_x - z_size*0.1, bot_right_y - z_size*0.1, 0)
        
    r.ImGui_DrawList_PathStroke(dl, z_col, 0, z_thick)
  end
end

local function SpawnParticle(x, y)
  local s = state.scale
  table.insert(state.particles, {
    x = x, y = y,
    vx = (math.random() - 0.5) * 8 * s,
    vy = (-6 - math.random() * 4) * s,
    life = 1.0,
    color = (math.random() > 0.5) and 0xFF69B4FF or 0xFF1493FF,
    scale = s
  })
end

local function TriggerTap()
  local s = state.scale
  local tap_amplitude = 60 * s
  if state.next_hand_is_left then
    state.left_target = tap_amplitude
    SpawnParticle(
      state.chick_cx + particle_config.left_offset_x * s,
      state.chick_cy + particle_config.offset_y * s
    )
  else
    state.right_target = tap_amplitude
    SpawnParticle(
      state.chick_cx + particle_config.right_offset_x * s,
      state.chick_cy + particle_config.offset_y * s
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
    local face_center_x = state.chick_cx
    local face_center_y = state.chick_cy - 25 * s
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
  local offset_x = base.x * scale
  local offset_y = base.y * scale
  offset_y = offset_y + (extra_y or 0)

  local drawn = draw_layer(dl, img, rect.min_x, rect.min_y, rect.draw_w, rect.draw_h, offset_x, offset_y)
  if not drawn then
    local paw_r = 40 * scale
    local cx = rect.center_x + base.x * scale
    local cy = rect.center_y + base.y * scale + (extra_y or 0)
    r.ImGui_DrawList_AddCircleFilled(dl, cx, cy, paw_r, placeholder_colors[side] or 0xFFFACC6C)
  end
end

-- [优化] 极速心形绘制：使用缓存点
local function draw_heart_fast(dl, cx, cy, size, color)
  -- 缩放系数：原方程范围约[-16,16]，调整系数以匹配视觉大小
  local scale = size * 0.08 
  
  r.ImGui_DrawList_PathClear(dl)
  
  -- 遍历缓存，只做乘法和加法，没有 sin/cos，不创建新 table
  for i = 1, #heart_shape_cache do
    local pt = heart_shape_cache[i]
    local px = cx + pt.x * scale
    local py = cy + pt.y * scale
    r.ImGui_DrawList_PathLineTo(dl, px, py)
  end
  
  r.ImGui_DrawList_PathFillConvex(dl, color)
end

-- 备用绘制
local function draw_heart_simple(dl, x, y, size, color)
  local s = size
  local base_radius = s * 0.35
  r.ImGui_DrawList_AddCircleFilled(dl, x - s * 0.3, y - s * 0.15, base_radius, color)
  r.ImGui_DrawList_AddCircleFilled(dl, x + s * 0.3, y - s * 0.15, base_radius, color)
  r.ImGui_DrawList_AddTriangleFilled(dl, x - s * 0.65, y + s * 0.1, x + s * 0.65, y + s * 0.1, x, y + s * 0.5, color)
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
      local s = (p.scale or 1.0) * particle_config.size_multiplier
      local x, y = p.x, p.y
      
      -- [优化] 使用 fast 版本
      if r.ImGui_DrawList_PathLineTo and r.ImGui_DrawList_PathFillConvex then
        draw_heart_fast(dl, x, y, s, col)
      else
        draw_heart_simple(dl, x, y, s, col)
      end
    end
  end
end

function ChickBase.init(ctx, script_path)
  ctx_ref = ctx
  root_path = script_path or ""
  for name, file in pairs(layer_files) do
    load_layer(name, file)
  end
  load_legacy_full()
end

function ChickBase.update(dt, char_state, ctx)
  if char_state == "operating" then
    TriggerTap()
  end
  update_anim(ctx, char_state)
end

-- [优化] 复用 rect_cache，不创建新表
local function compute_rect(x, y, w, h)
  local scale = math.min(w / base_w, h / base_h)
  local draw_w = base_w * scale
  local draw_h = base_h * scale
  local min_x = x + (w - draw_w) * 0.5
  local min_y = y + (h - draw_h) * 0.5
  
  -- 更新缓存
  rect_cache.min_x = min_x
  rect_cache.min_y = min_y
  rect_cache.draw_w = draw_w
  rect_cache.draw_h = draw_h
  rect_cache.max_x = min_x + draw_w
  rect_cache.max_y = min_y + draw_h
  rect_cache.scale = scale
  rect_cache.center_x = x + w * 0.5
  rect_cache.center_y = y + h * 0.65
  
  return rect_cache
end

local function draw_composed_layers(dl, rect, char_state, skip_overlay)
  local scale = rect.scale
  state.scale = scale
  state.chick_cx = rect.center_x
  state.chick_cy = rect.center_y

  local function layer(name, extra_x, extra_y)
    local img = layers[name]
    local base = layer_offsets[name] or { x = 0, y = 0 }
    local offset_x = base.x * scale + (extra_x or 0)
    local offset_y = base.y * scale + (extra_y or 0)

    local drawn = draw_layer(dl, img, rect.min_x, rect.min_y, rect.draw_w, rect.draw_h, offset_x, offset_y)
    if not drawn and placeholder_colors[name] then
      draw_placeholder_rect(dl,
        rect.min_x + offset_x, rect.min_y + offset_y,
        rect.min_x + offset_x + rect.draw_w, rect.min_y + offset_y + rect.draw_h,
        placeholder_colors[name]
      )
    end
  end

  layer("head", 0, 0)
  if char_state == "break" then
    layer("rest", state.face_off_x * scale, state.face_off_y * scale)
    draw_zzz_animation(dl, rect, scale)
  else
    layer("face", state.face_off_x * scale, state.face_off_y * scale)
  end
  layer("table")
end

local function draw_legacy(dl, rect)
  if not legacy_full then return end
  r.ImGui_DrawList_AddImage(dl, legacy_full, rect.min_x, rect.min_y, rect.max_x, rect.max_y)
end

function ChickBase.draw(ctx, dl, x, y, w, h, char_state, skip_overlay)
  if not root_path then return end
  local rect = compute_rect(x, y, w, h)
  state.last_rect = rect

  if any_layer_loaded() then
    draw_composed_layers(dl, rect, char_state, skip_overlay)
  elseif legacy_full then
    draw_legacy(dl, rect)
  end
end

function ChickBase.draw_paws(ctx, dl, x, y, w, h)
  if not state.last_rect then return end
  if not any_layer_loaded() then return end
  local rect = state.last_rect
  local scale = rect.scale or 1.0
  
  draw_hand(dl, "hand_left", rect, scale, state.left_paw_y)
  draw_hand(dl, "hand_right", rect, scale, state.right_paw_y)
  draw_particles(dl)
end

function ChickBase.get_draw_rect() return state.last_rect end
function ChickBase.get_recommended_size() return 300, 200 end

function ChickBase.trigger_action(action_type, is_manual)
  if action_type == "tap_left" or action_type == "tap_right" or action_type == "tap" then
    TriggerTap()
    if is_manual then state.last_manual_tap_time = get_time() end
  elseif action_type == "celebrate" then
    local s = state.scale
    SpawnParticle(state.chick_cx + particle_config.left_offset_x * s, state.chick_cy + particle_config.offset_y * s)
    SpawnParticle(state.chick_cx + particle_config.right_offset_x * s, state.chick_cy + particle_config.offset_y * s)
  end
end

function ChickBase.get_particle_config() return particle_config end
function ChickBase.set_particle_config(new_config)
  if new_config then
    if new_config.left_offset_x ~= nil then particle_config.left_offset_x = new_config.left_offset_x end
    if new_config.right_offset_x ~= nil then particle_config.right_offset_x = new_config.right_offset_x end
    if new_config.offset_y ~= nil then particle_config.offset_y = new_config.offset_y end
    if new_config.size_multiplier ~= nil then particle_config.size_multiplier = new_config.size_multiplier end
  end
end

function ChickBase.get_zzz_config() return zzz_config end
function ChickBase.set_zzz_config(new_config)
  if new_config then
    for k,v in pairs(new_config) do zzz_config[k] = v end
  end
end

function ChickBase.get_last_manual_tap_time() return state.last_manual_tap_time or 0 end

return ChickBase

