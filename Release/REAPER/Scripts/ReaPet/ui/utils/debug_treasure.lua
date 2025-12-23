-- debug_treasure.lua
-- 独立的 UI 调试脚本，用于开发和测试“宝箱组件”
-- 不需要 main.lua 即可运行

local script_path = debug.getinfo(1, "S").source:match("@(.*[\\//])")
package.path = script_path .. "?.lua;" .. package.path

local r = reaper
local ctx = r.ImGui_CreateContext('Treasure Debugger')

-- 引入组件
local TreasureChest = require("ui.components.treasure_chest")

-- 初始化实例
local chest = TreasureChest:new()

-- 调试用的状态
local last_time = r.time_precise()
local message = "Click 'Spawn' to start."

local function Loop()
    local now = r.time_precise()
    local dt = now - last_time
    last_time = now
    
    local flags = r.ImGui_WindowFlags_None()
    local visible, open = r.ImGui_Begin(ctx, 'Treasure Chest Debug', true, flags)
    
    if visible then
        -- 1. 调试控制面板
        r.ImGui_Text(ctx, "Debug Controls:")
        
        if r.ImGui_Button(ctx, "Spawn Chest (Show)") then
            chest:show()
            message = "Chest spawned! Click it to open."
        end
        
        r.ImGui_SameLine(ctx)
        
        if r.ImGui_Button(ctx, "Reset / Hide") then
            chest:hide()
            message = "Chest hidden."
        end
        
        r.ImGui_Text(ctx, "Status: " .. message)
        r.ImGui_Separator(ctx)
        
        -- 2. 模拟绘图区域 (画布)
        -- 获取当前窗口的绘图列表
        local dl = r.ImGui_GetWindowDrawList(ctx)
        
        -- 计算画布中心
        local win_w, win_h = r.ImGui_GetWindowSize(ctx)
        local win_x, win_y = r.ImGui_GetWindowPos(ctx)
        local cx, cy = win_x + win_w/2, win_y + win_h/2 + 20
        
        -- 更新组件逻辑
        chest:update(dt)
        
        -- 绘制组件
        -- draw 返回 true 表示发生了“打开”事件
        local just_opened = chest:draw(dl, cx, cy, 1.5) -- 1.5倍放大显示
        
        if just_opened then
            message = "Opened! Creating Particles..."
            -- 这里可以添加打开时的回调逻辑，比如播放音效
        end
        
        r.ImGui_End(ctx)
    end

    if open then
        r.defer(Loop)
    end
end

r.defer(Loop)