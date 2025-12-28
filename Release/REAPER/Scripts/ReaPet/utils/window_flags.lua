--[[
  REAPER Companion - 窗口标志管理模块
  职责：根据配置动态生成窗口标志，支持停靠功能
--]]

local WindowFlags = {}

-- 获取主窗口标志
-- @return number 窗口标志值
function WindowFlags.get_main_window_flags()
  local r = reaper
  local Config = require('config')
  
  -- 基础标志：始终隐藏滚动条
  local flags = r.ImGui_WindowFlags_NoScrollbar()
  
  if Config.ENABLE_DOCKING then
    -- 启用停靠模式：
    -- 1. 显示 title bar（移除 NoTitleBar），让用户可以右键点击选择 "Dock" 或拖拽停靠
    -- 2. 不使用 TopMost，允许停靠到 REAPER 主窗口
    -- 3. 用户可以通过右键标题栏选择 "Dock" 来停靠
    -- 4. 或者直接拖拽窗口到 REAPER 主窗口的边缘区域，实现自动停靠
    -- 停靠后，窗口成为主窗口的一部分，由 REAPER 管理
    -- 注意：不添加 NoTitleBar，保留默认的 title bar
  else
    -- 未启用停靠模式：
    -- 1. 隐藏 title bar（保持当前无边框设计）
    -- 2. 使用 TopMost（保持当前行为，窗口始终置顶）
    flags = flags | r.ImGui_WindowFlags_NoTitleBar() | 
                   r.ImGui_WindowFlags_TopMost()
  end
  
  return flags
end

return WindowFlags

