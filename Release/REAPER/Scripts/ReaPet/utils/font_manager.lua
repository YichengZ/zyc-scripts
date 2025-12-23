--[[
  REAPER Companion - 字体管理器
  统一管理字体加载，确保跨平台一致性
--]]

local FontManager = {}
local r = reaper

-- ========= 字体配置 =========
local fonts = {
  default = nil,      -- 默认字体（跨平台兼容）
  timer = nil,        -- 计时器专用字体
  stats = nil         -- 统计框专用字体
}

-- 字体路径（使用系统默认字体，尽量保证跨平台一致）
-- 注意：
-- 1. 不依赖任何外部 .ttf 文件（避免 Windows / macOS 路径差异）
-- 2. 如果当前 ReaImGui 版本不支持 ImGui_CreateFont，则完全退回到 ImGui 默认字体
local FONT_FAMILY = 'sans-serif'  -- 让 ImGui 自己挑选系统 sans-serif 字体

-- ========= 初始化字体 =========
-- @param ctx ImGui context
function FontManager.init(ctx)
  if not ctx then return end

  -- 兼容旧版 ReaImGui：如果没有 CreateFont API，则直接使用默认字体，不做任何自定义
  if not r.ImGui_CreateFont then
    return
  end
  
  -- 创建默认字体（使用系统默认，ImGui 会处理跨平台差异）
  -- 使用较大的基础字号，然后通过 AddTextEx 的 font_size 参数缩放
  -- 兼容旧版 ReaImGui：部分版本的 ImGui_CreateFont 只接受两个参数 (family, size)
  local base_size = 16
  -- 统一使用两个参数的调用方式，避免 “expected 2 arguments maximum” 报错
  fonts.default = r.ImGui_CreateFont(FONT_FAMILY, base_size)
  
  if fonts.default then
    r.ImGui_Attach(ctx, fonts.default)
  end
  
  -- 创建计时器字体（稍大一些，用于计时器显示）
  fonts.timer = r.ImGui_CreateFont(FONT_FAMILY, base_size)
  if fonts.timer then
    r.ImGui_Attach(ctx, fonts.timer)
  end
  
  -- 创建统计框字体
  fonts.stats = r.ImGui_CreateFont(FONT_FAMILY, base_size)
  if fonts.stats then
    r.ImGui_Attach(ctx, fonts.stats)
  end
end

-- ========= 获取字体 =========
function FontManager.get_default()
  return fonts.default
end

function FontManager.get_timer()
  return fonts.timer
end

function FontManager.get_stats()
  return fonts.stats
end

-- ========= 计算文本尺寸（跨平台兼容） =========
-- @param ctx ImGui context
-- @param text 文本内容
-- @param font_size 字体大小（像素）
-- @return width, height, baseline_offset
function FontManager.calc_text_size(ctx, text, font_size)
  if not ctx or not text then
    return 0, font_size or 16, 0
  end
  
  -- 使用 ImGui 的默认字体计算（更准确）
  local width, height = r.ImGui_CalcTextSize(ctx, text)
  
  -- 如果指定了 font_size，需要缩放
  if font_size and font_size ~= 16 then
    local scale = font_size / 16.0
    width = width * scale
    height = height * scale
  end
  
  -- 计算基线偏移（用于垂直居中）
  -- 基线通常在字体高度的 0.8-0.85 位置（从顶部算起）
  local baseline_offset = height * 0.15  -- 约 15% 的偏移，用于补偿基线
  
  return width, height, baseline_offset
end

-- ========= 计算垂直居中位置（考虑基线） =========
-- @param box_y 框的顶部位置
-- @param box_height 框的高度
-- @param text_height 文本高度
-- @param baseline_offset 基线偏移（可选，如果不提供会自动计算）
-- @return text_y 文本的 Y 坐标（考虑基线对齐）
function FontManager.calc_vertical_center(box_y, box_height, text_height, baseline_offset)
  baseline_offset = baseline_offset or (text_height * 0.15)
  -- 垂直居中：框中心 - 文本中心 + 基线补偿
  return box_y + (box_height - text_height) * 0.5 + baseline_offset
end

return FontManager

