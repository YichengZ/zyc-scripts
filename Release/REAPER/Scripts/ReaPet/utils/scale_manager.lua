--[[
  REAPER Companion - 统一缩放管理模块
  职责：统一管理窗口缩放因子，提供一致的缩放转换接口
  原则：
  1. 物理系统使用逻辑单位（不缩放）
  2. 渲染系统负责将逻辑单位转换为屏幕像素
  3. 所有缩放计算集中管理，避免不一致
--]]

local ScaleManager = {}

-- ========= 内部状态 =========
local state = {
  window_scale = 1.0,      -- 当前窗口缩放因子
  base_width = 400,         -- 基准宽度
  base_height = 300,        -- 基准高度
  is_initialized = false
}

-- ========= 公共接口 =========

-- 更新缩放因子（每帧调用）
-- @param window_width 当前窗口宽度
-- @param window_height 当前窗口高度
-- @param base_w 基准宽度（可选，默认使用 state.base_width）
-- @param base_h 基准高度（可选，默认使用 state.base_height）
function ScaleManager.update(window_width, window_height, base_w, base_h)
  base_w = base_w or state.base_width
  base_h = base_h or state.base_height
  
  if base_w > 0 and base_h > 0 then
    state.window_scale = math.min(window_width / base_w, window_height / base_h)
    state.base_width = base_w
    state.base_height = base_h
    state.is_initialized = true
  end
end

-- 获取当前缩放因子
-- @return 缩放因子（1.0 = 100%）
function ScaleManager.get()
  return state.window_scale
end

-- 将逻辑单位转换为屏幕像素
-- @param logical_value 逻辑单位值
-- @return 屏幕像素值
function ScaleManager.to_screen(logical_value)
  return logical_value * state.window_scale
end

-- 将屏幕像素转换为逻辑单位
-- @param screen_value 屏幕像素值
-- @return 逻辑单位值
function ScaleManager.to_logical(screen_value)
  if state.window_scale > 0 then
    return screen_value / state.window_scale
  end
  return screen_value
end

-- 检查是否已初始化
function ScaleManager.is_initialized()
  return state.is_initialized
end

-- 获取基准尺寸
function ScaleManager.get_base_size()
  return state.base_width, state.base_height
end

return ScaleManager

