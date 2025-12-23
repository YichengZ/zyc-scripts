--[[
  REAPER Companion - Debug 工具模块
  提供条件化的 debug 输出功能
--]]

local Debug = {}
local Config = require('config')

-- Debug 开关状态（从 Config 读取）
local function is_debug_enabled()
    return Config.SHOW_DEBUG_CONSOLE or false
end

-- 条件化的 console 输出
function Debug.log(message)
    if is_debug_enabled() then
        reaper.ShowConsoleMsg(message)
    end
end

-- 格式化的 debug 输出
function Debug.logf(format, ...)
    if is_debug_enabled() then
        reaper.ShowConsoleMsg(string.format(format, ...))
    end
end

-- 条件化的 print 输出（用于 Lua 的 print，也会输出到 console）
function Debug.print(...)
    if is_debug_enabled() then
        print(...)
    end
end

return Debug

