--[[
  REAPER Companion - Pomodoro Timer UI (Dynamic Color Sync - Gray Idle)
  修改：Idle 状态改为低调的灰白色，更符合"未开始"的语义
  核心逻辑：保留 AddTextEx 动态字体缩放、文字颜色与状态同步
--]]

local PomodoroTimer = {}

-- ========= 视觉风格配置 =========
local style = {
  -- 尺寸比例
  radius_ratio = 0.42,      -- 圆环半径
  thickness_ratio = 0.08,   -- 线条粗细
  
  -- 字体缩放系数 (优化：减小字体大小，确保在圆圈内居中)
  scale_factor_time = 0.38,   -- 时间字体系数（从 0.45 减小到 0.38，让字体更小更居中）
  scale_factor_label = 0.12,  -- 标签字体系数（从 0.14 减小到 0.12，保持比例）
  
  -- 文字位置偏移（开发者面板可调）
  text_vertical_offset = 0.0,   -- 垂直偏移（相对于圆圈尺寸的比例，正数向下）
  text_horizontal_offset = -0.083, -- 时间水平偏移（相对于圆圈尺寸的比例，正数向右）
  label_horizontal_offset = -0.027, -- 标签水平偏移（相对于圆圈尺寸的比例，正数向右）
  text_gap_factor = 0.35,       -- 时间与标签之间的间距系数
  
  -- 调色板 (0xRRGGBBAA)
  colors = {
    -- 专注 (Focus): 珊瑚粉 (Coral) - 温暖警示
    focus       = 0xFF8B75FF, 
    
    -- 休息 (Break): 森林薄荷 (Mint) - 清新放松
    break_col   = 0x26C281FF,
    
    -- 空闲 (Idle): 极简灰/灰白 (Concrete) - 低调、待机感
    -- 修改：从蓝色改为灰色，符合"未开始"的状态
    idle        = 0x95A5A6FF, 
  },
  
  -- 透明度配置（提高透明度，让元素更不透明）
  alpha = {
    track = 60,      -- 背景轨道透明度 (0-255)，约 24%（从 40 提高到 60，更不透明）
    text_sub = 220,  -- 副标签透明度（从 180 提高到 220，更不透明）
  },
  
  -- 动画速率
  anim = {
    pulse = 2.5,   -- 呼吸频率
    hover = 12.0,  -- 悬停响应
    morph = 8.0    -- 颜色切换
  }
}

-- ========= 内部状态 =========
local state = {
  pulse_val = 0.0,
  hover_f = 0.0,
  -- 颜色状态初始值 (对应 Idle 灰色)
  r = 149, g = 165, b = 166 
}

-- ========= 工具函数 =========
local function rgba(r, g, b, a)
  return (math.floor(r) << 24) | (math.floor(g) << 16) | (math.floor(b) << 8) | math.floor(a)
end

local function unpack_c(c)
  return (c >> 24) & 0xFF, (c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF
end

local function lerp(a, b, t) return a + (b - a) * t end

-- RGB 转 HSL（简化版，用于降低饱和度）
local function rgb_to_hsl(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local l = (max + min) / 2
  local h, s = 0, 0
  
  if max ~= min then
    local d = max - min
    s = l > 0.5 and d / (2 - max - min) or d / (max + min)
    if max == r then
      h = ((g - b) / d + (g < b and 6 or 0)) / 6
    elseif max == g then
      h = ((b - r) / d + 2) / 6
    else
      h = ((r - g) / d + 4) / 6
    end
  end
  return h, s, l
end

-- HSL 转 RGB
local function hsl_to_rgb(h, s, l)
  local r, g, b
  if s == 0 then
    r, g, b = l, l, l
  else
    local function hue2rgb(p, q, t)
      if t < 0 then t = t + 1 end
      if t > 1 then t = t - 1 end
      if t < 1/6 then return p + (q - p) * 6 * t end
      if t < 1/2 then return q end
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
      return p
    end
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end
  return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- 降低颜色饱和度（更柔和、更淡）
local function desaturate(r, g, b, factor)
  -- factor: 0.0 = 完全去饱和（灰色），1.0 = 保持原色
  local h, s, l = rgb_to_hsl(r, g, b)
  s = s * factor  -- 降低饱和度
  local new_r, new_g, new_b = hsl_to_rgb(h, s, l)
  return new_r, new_g, new_b
end

-- [核心绘制辅助] 兼容性文本绘制函数（跨平台优化）
local function draw_text_dynamic(dl, x, y, color, text, font_size, font_obj)
  if reaper.ImGui_DrawList_AddTextEx then
    -- 使用指定的字体对象（如果提供），否则使用默认字体
    -- font_size 控制大小，确保跨平台一致性
    local font_to_use = font_obj or nil
    reaper.ImGui_DrawList_AddTextEx(dl, font_to_use, font_size, x, y, color, text)
  else
    -- 回退：无法控制大小
    reaper.ImGui_DrawList_AddText(dl, x, y, color, text)
  end
end

-- 估算文字宽度 (用于居中)
local function estimate_text_width(text, font_size)
  return #text * font_size * 0.55
end

-- 统一的文本测量函数：优先使用 FontManager（基于 ImGui_CalcTextSize），
-- 回退到 estimate_text_width，确保跨平台时数字能更好地居中在圆圈内
local function measure_text(ctx, text, font_size)
  if not text or text == "" then
    return 0, font_size, 0
  end

  local ok, FontManager = pcall(require, 'utils.font_manager')
  if ok and FontManager and FontManager.calc_text_size then
    local w, h, baseline = FontManager.calc_text_size(ctx, text, font_size)
    return w, h, baseline or (h * 0.15)
  end

  -- 回退：简单估算
  local w = estimate_text_width(text, font_size)
  local h = font_size
  local baseline = h * 0.15
  return w, h, baseline
end

-- 获取计时器专用字体（如果 FontManager 提供），否则返回 nil 使用默认字体
local function get_timer_font()
  local ok, FontManager = pcall(require, 'utils.font_manager')
  if ok and FontManager and FontManager.get_timer then
    return FontManager.get_timer()
  end
  return nil
end

-- ========= 核心 API =========

function PomodoroTimer.init() end

function PomodoroTimer.is_hovered(mx, my, x, y, w, h)
  local cx, cy = x + w * 0.5, y + h * 0.5
  local r = math.min(w, h) * 0.5
  return ((mx - cx)^2 + (my - cy)^2) <= r^2
end

function PomodoroTimer.trigger_click() end
function PomodoroTimer.trigger_switch() end

function PomodoroTimer.update(dt, p_state, is_hovered)
  -- 1. 呼吸计算
  if p_state == "focus" then
    local time = reaper.time_precise()
    state.pulse_val = 0.90 + 0.10 * math.sin(time * style.anim.pulse)
  else
    state.pulse_val = 1.0
  end
  
  -- 2. 悬停状态插值
  local target_h = is_hovered and 1.0 or 0.0
  state.hover_f = lerp(state.hover_f, target_h, dt * style.anim.hover)
  
  -- 3. 颜色平滑过渡 (计算当前的基础 RGB)
  local target_col = style.colors.idle
  if p_state == "focus" then target_col = style.colors.focus
  elseif p_state == "break" then target_col = style.colors.break_col end
  
  local tr, tg, tb, _ = unpack_c(target_col)
  state.r = lerp(state.r, tr, dt * style.anim.morph)
  state.g = lerp(state.g, tg, dt * style.anim.morph)
  state.b = lerp(state.b, tb, dt * style.anim.morph)
end

-- 绘制函数
function PomodoroTimer.draw(ctx, dl, x, y, w, h, is_hovered, p_state, time_str, progress, is_paused)
  local cx, cy = x + w * 0.5, y + h * 0.5
  local size = math.min(w, h)
  
  -- 悬停缩放效果（idle 状态下更明显）
  local hover_scale = 1.0
  if state.hover_f > 0.01 then
    if p_state == "idle" then
      -- Idle 状态下：更明显的缩放（1.0 -> 1.08）
      hover_scale = 1.0 + 0.08 * state.hover_f
    else
      -- 其他状态下：轻微的缩放（1.0 -> 1.03）
      hover_scale = 1.0 + 0.03 * state.hover_f
    end
  end
  
  local r = size * style.radius_ratio * hover_scale
  local thickness = size * style.thickness_ratio
  
  -- == 1. 颜色计算 ==
  -- 基础颜色 RGB (从 update 中获取插值后的结果)
  local r_base, g_base, b_base = state.r, state.g, state.b
  
  -- A. 文字颜色 (Text Color) - 使用当前颜色全不透明，保持明亮
  -- 暂停时文字稍微变暗一点，以示区别
  local text_r, text_g, text_b = r_base, g_base, b_base
  if is_paused and p_state ~= "idle" then
    local dim_factor = 0.7
    text_r, text_g, text_b = r_base * dim_factor, g_base * dim_factor, b_base * dim_factor
  end
  local text_main_col = rgba(text_r, text_g, text_b, 255)
  local text_sub_col  = rgba(text_r, text_g, text_b, style.alpha.text_sub)
  
  -- B. 进度条颜色 (Progress Arc Color) - 降低饱和度，更柔和、更淡
  -- 通过降低饱和度使进度条更柔和，而不是降低亮度（避免显得脏）
  local progress_saturation = 0.5  -- 饱和度系数（0.5 = 降低50%饱和度，更柔和）
  local pulse_factor = (p_state == "focus" and not is_paused) and state.pulse_val or 1.0
  
  -- 先降低饱和度
  local progress_r, progress_g, progress_b = desaturate(r_base, g_base, b_base, progress_saturation)
  
  -- 应用呼吸效果（在降低饱和度后）
  progress_r = progress_r * pulse_factor
  progress_g = progress_g * pulse_factor
  progress_b = progress_b * pulse_factor
  
  -- 暂停时进度条也变暗
  if is_paused and p_state ~= "idle" then
    local dim_factor = 0.7
    progress_r = progress_r * dim_factor
    progress_g = progress_g * dim_factor
    progress_b = progress_b * dim_factor
  end
  local main_col = rgba(progress_r, progress_g, progress_b, 255)
  
  -- C. 轨道背景颜色 (Track Color) - 使用当前颜色但低透明度
  local track_col = rgba(r_base, g_base, b_base, style.alpha.track)
  
  -- == 2. 绘制轨道 (Track) ==
  -- 这里的颜色现在会跟随状态变化
  reaper.ImGui_DrawList_AddCircle(dl, cx, cy, r, track_col, 0, thickness)
  
  -- Idle 状态下的悬停效果：发光边框（更精细）
  if p_state == "idle" and state.hover_f > 0.01 then
    local glow_alpha = math.floor(100 * state.hover_f)
    local glow_col = rgba(r_base, g_base, b_base, glow_alpha)
    local glow_thickness = thickness * (1.0 + 0.6 * state.hover_f)  -- 减小发光宽度（从 1.5 改为 0.6）
    reaper.ImGui_DrawList_AddCircle(dl, cx, cy, r, glow_col, 0, glow_thickness)
  end
  
  -- == 3. 绘制进度条 (Arc) ==
  if p_state ~= "idle" and progress > 0.001 then
    local angle_start = -math.pi * 0.5
    local angle_end = angle_start + (progress * math.pi * 2)
    
    reaper.ImGui_DrawList_PathClear(dl)
    reaper.ImGui_DrawList_PathArcTo(dl, cx, cy, r, angle_start, angle_end, 64) 
    reaper.ImGui_DrawList_PathStroke(dl, main_col, 0, thickness)
    
    -- 圆角端点
    local cap_x = cx + math.cos(angle_end) * r
    local cap_y = cy + math.sin(angle_end) * r
    reaper.ImGui_DrawList_AddCircleFilled(dl, cap_x, cap_y, thickness * 0.5, main_col)
    
    -- 悬停高亮（非 idle 状态）
    if state.hover_f > 0.01 then
      -- 进度条端点高亮
      local highlight_alpha = math.floor(150 * state.hover_f)
      local highlight_col = main_col & 0xFFFFFF00 | highlight_alpha
      local highlight_size = thickness * (1.2 + 0.8 * state.hover_f)
      reaper.ImGui_DrawList_AddCircleFilled(dl, cap_x, cap_y, highlight_size, highlight_col)
      
      -- 进度条整体发光效果（更精细）
      local glow_alpha = math.floor(50 * state.hover_f)
      local glow_col = main_col & 0xFFFFFF00 | glow_alpha
      local glow_thickness = thickness * (1.0 + 0.3 * state.hover_f)  -- 减小发光宽度（从 0.5 改为 0.3）
      reaper.ImGui_DrawList_PathClear(dl)
      reaper.ImGui_DrawList_PathArcTo(dl, cx, cy, r, angle_start, angle_end, 64)
      reaper.ImGui_DrawList_PathStroke(dl, glow_col, 0, glow_thickness)
    end
  end
  
  -- == 4. 文字渲染 ==
  local display_time = time_str
  local display_label = ""
  
  if p_state == "idle" then
    display_time = "--:--"
    display_label = is_hovered and "START" or "IDLE"
  else
    if p_state == "focus" then display_label = "FOCUS"
    elseif p_state == "break" then display_label = "BREAK" end
    if is_paused then display_label = "PAUSED" end
  end
  
  -- 动态字号计算 (Strictly following your formula)
  local font_size_time = math.floor(size * style.scale_factor_time)
  local font_size_label = math.floor(size * style.scale_factor_label)
  
  -- 绘制时间 / 标签 (颜色使用 text_main_col / text_sub_col)
  -- Idle 状态下悬停时时间文字稍微放大
  local time_scale = (p_state == "idle" and state.hover_f > 0.01) and (1.0 + 0.05 * state.hover_f) or 1.0
  local effective_font_size_time = font_size_time * time_scale
  local tw, th = measure_text(ctx, display_time, effective_font_size_time)
  
  -- 预先计算标签字号（可能会用到）
  local label_scale = (p_state == "idle" and is_hovered) and 1.15 or 1.0
  local effective_font_size_label = font_size_label * label_scale
  local lw, lh = 0, 0
  if display_label ~= "" then
    lw, lh = measure_text(ctx, display_label, effective_font_size_label)
  end
  
  -- 让「时间 + 标签」这个整体在圆圈内部垂直居中：
  -- time 在上，label 在下，中间留一点间距
  -- 间距使用可配置的 gap 系数
  local gap_factor = style.text_gap_factor or 0.35
  local gap = (display_label ~= "" and (effective_font_size_label * gap_factor)) or 0
  local block_h = th + gap + (display_label ~= "" and lh or 0)
  -- 使用 measure_text 返回的 baseline 信息来精确居中
  local _, _, baseline_time = measure_text(ctx, display_time, effective_font_size_time)
  local baseline_offset = baseline_time or (th * 0.1)  -- 使用实际测量的基线，或默认 10%
  -- 整体垂直偏移，补偿基线 + 用户可调的偏移（相对于圆圈尺寸）
  local user_vertical_offset = (style.text_vertical_offset or 0.0) * size
  local top_y = cy - block_h * 0.5 - baseline_offset * 0.5 + user_vertical_offset
  
  -- 水平偏移（用户可调，相对于圆圈尺寸）
  local time_horizontal_offset = (style.text_horizontal_offset or 0.0) * size
  local label_horizontal_offset = (style.label_horizontal_offset or 0.0) * size
  local tx = cx - tw * 0.5 + time_horizontal_offset
  local ty = top_y  -- 时间行的顶部
  
  -- Idle 状态下悬停时文字颜色更亮
  local final_text_col = text_main_col
  if p_state == "idle" and state.hover_f > 0.01 then
    local brighten_factor = 1.0 + 0.3 * state.hover_f
    local bright_r = math.min(255, text_r * brighten_factor)
    local bright_g = math.min(255, text_g * brighten_factor)
    local bright_b = math.min(255, text_b * brighten_factor)
    final_text_col = rgba(bright_r, bright_g, bright_b, 255)
  end
  
  -- 使用 AddTextEx 实现动态字体缩放（使用 FontManager 提供的计时器字体，如果可用）
  local timer_font = get_timer_font()
  draw_text_dynamic(dl, tx, ty, final_text_col, display_time, effective_font_size_time, timer_font)
  
  -- 绘制标签 (颜色使用 text_sub_col)
  if display_label ~= "" then
    -- 标签使用独立的水平偏移
    local lx = cx - lw * 0.5 + label_horizontal_offset
    -- 标签放在时间下方，使用同一个 block 垂直居中逻辑
    local ly = ty + th + gap
    
    -- Idle 状态下悬停时标签颜色更亮
    local final_label_col = text_sub_col
    if p_state == "idle" and state.hover_f > 0.01 then
      local label_alpha = math.floor(255 * (0.7 + 0.3 * state.hover_f))
      final_label_col = rgba(text_r, text_g, text_b, label_alpha)
    end
    
    -- 使用 AddTextEx 实现动态字体缩放
    draw_text_dynamic(dl, lx, ly, final_label_col, display_label, effective_font_size_label, timer_font)
  end
end

-- 开发者面板：返回内部配置引用，便于实时调整
function PomodoroTimer.get_dev_config()
  return {
    style = style
  }
end

return PomodoroTimer