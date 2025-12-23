-- ui/components/treasure_chest.lua
-- 宝箱 UI 组件：负责绘制宝箱、处理点击、调用粒子特效

local Particles = require("ui.utils.particles")

local Chest = {}
Chest.__index = Chest

function Chest:new()
    local instance = setmetatable({}, self)
    
    -- 状态定义
    instance.visible = false      -- 是否显示
    instance.is_opened = false    -- 是否已打开
    instance.scale_anim = 0.0     -- 弹出动画插值 (0.0 -> 1.0)
    instance.shake_offset = 0.0   -- 震动偏移
    
    -- 内部系统
    instance.particles = Particles:new()
    
    -- 配置
    instance.colors = {
        body = 0xFFD700FF,        -- 金色主体
        stroke = 0x8B4513FF,      -- 棕色描边
        light = 0xFFF68F88        -- 高光
    }
    
    return instance
end

-- [API] 显示宝箱
function Chest:show()
    self.visible = true
    self.is_opened = false
    self.scale_anim = 0.0
end

-- [API] 隐藏宝箱
function Chest:hide()
    self.visible = false
end

-- [内部] 绘制宝箱图形
-- x, y: 中心坐标
-- s: 缩放系数
-- hover: 鼠标是否悬停
local function DrawGraphic(dl, x, y, s, hover, is_opened, colors)
    local r = reaper
    
    -- 基础尺寸
    local w, h = 60 * s, 45 * s
    local top_y = y - h/2
    local bot_y = y + h/2
    local left_x = x - w/2
    local right_x = x + w/2
    
    -- 悬停时稍微变亮/变大
    if hover and not is_opened then 
        -- r.ImGui_DrawList_AddCircleFilled(dl, x, y, w, 0xFFFFFF44) -- 光晕
    end

    local thick = 3.0 * s
    
    if not is_opened then
        -- === 闭合状态 ===
        -- 箱体 (梯形)
        r.ImGui_DrawList_PathClear(dl)
        r.ImGui_DrawList_PathLineTo(dl, left_x + 5*s, bot_y)
        r.ImGui_DrawList_PathLineTo(dl, left_x, top_y + 15*s)
        r.ImGui_DrawList_PathLineTo(dl, right_x, top_y + 15*s)
        r.ImGui_DrawList_PathLineTo(dl, right_x - 5*s, bot_y)
        r.ImGui_DrawList_PathFillConvex(dl, colors.body)
        
        -- 箱体描边
        r.ImGui_DrawList_PathClear(dl)
        r.ImGui_DrawList_PathLineTo(dl, left_x + 5*s, bot_y)
        r.ImGui_DrawList_PathLineTo(dl, left_x, top_y + 15*s)
        r.ImGui_DrawList_PathLineTo(dl, right_x, top_y + 15*s)
        r.ImGui_DrawList_PathLineTo(dl, right_x - 5*s, bot_y)
        r.ImGui_DrawList_PathStroke(dl, colors.stroke, 1, thick)
        
        -- 盖子 (半圆弧)
        r.ImGui_DrawList_PathClear(dl)
        r.ImGui_DrawList_PathArcTo(dl, x, top_y + 15*s, w/2, 3.14, 0) -- 上半圆
        r.ImGui_DrawList_PathFillConvex(dl, 0xFFE033FF) -- 盖子稍微亮一点
        
        r.ImGui_DrawList_PathClear(dl)
        r.ImGui_DrawList_PathArcTo(dl, x, top_y + 15*s, w/2, 3.14, 0)
        r.ImGui_DrawList_PathLineTo(dl, left_x, top_y + 15*s) -- 闭合线
        r.ImGui_DrawList_PathStroke(dl, colors.stroke, 1, thick)
        
        -- 锁扣
        r.ImGui_DrawList_AddCircleFilled(dl, x, top_y + 15*s, 6*s, 0xCC0000FF)
        r.ImGui_DrawList_AddCircle(dl, x, top_y + 15*s, 6*s, colors.stroke, 0, thick)
        
    else
        -- === 开启状态 (简单的盖子打开) ===
        -- 后背板
        r.ImGui_DrawList_AddRectFilled(dl, left_x, top_y - 10*s, right_x, top_y + 15*s, 0x550000FF)
        
        -- 箱体
        r.ImGui_DrawList_AddRectFilled(dl, left_x + 5*s, top_y + 15*s, right_x - 5*s, bot_y, colors.body)
        r.ImGui_DrawList_AddRect(dl, left_x + 5*s, top_y + 15*s, right_x - 5*s, bot_y, colors.stroke, 0, 0, thick)
        
        -- 发光内容物
        r.ImGui_DrawList_AddRectFilled(dl, left_x + 10*s, top_y + 10*s, right_x - 10*s, top_y + 25*s, 0x00FFFF88)
    end
end

-- [生命周期] 更新逻辑
function Chest:update(dt)
    if not self.visible then return end
    
    -- 弹出动画 (Spring effect)
    if self.scale_anim < 1.0 then
        self.scale_anim = self.scale_anim + (1.0 - self.scale_anim) * 0.2
    end
    
    -- 待机震动 (Idle Shake) - 吸引用户点击
    if not self.is_opened then
        self.shake_offset = math.sin(reaper.time_precise() * 10) * 2
    else
        self.shake_offset = 0
    end
    
    self.particles:update()
end

-- [生命周期] 渲染与交互
-- dl: ImGui DrawList
-- cx, cy: 放置的中心位置
-- base_scale: 全局缩放
function Chest:draw(dl, cx, cy, base_scale)
    if not self.visible then return false end
    
    local r = reaper
    
    -- 应用弹出动画缩放
    local current_scale = base_scale * self.scale_anim
    -- 应用震动 (只影响Y轴)
    local draw_y = cy + self.shake_offset
    
    -- 1. 绘制粒子 (在箱子后面画一部分光效? 不，通常在前面)
    
    -- 2. 交互检测 (Hit Test)
    -- 我们放置一个隐形按钮在宝箱位置
    local size = 70 * current_scale
    r.ImGui_SetCursorScreenPos(ctx, cx - size/2, draw_y - size/2)
    r.ImGui_InvisibleButton(ctx, "TreasureHit", size, size)
    
    local is_hovered = r.ImGui_IsItemHovered(ctx)
    local is_clicked = r.ImGui_IsItemClicked(ctx)
    
    -- 鼠标样式：悬停且未打开时显示手型
    if is_hovered and not self.is_opened then
        r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_Hand())
    end
    
    -- 3. 绘制宝箱图形
    DrawGraphic(dl, cx, draw_y, current_scale, is_hovered, self.is_opened, self.colors)
    
    -- 4. 绘制粒子 (最上层)
    self.particles:draw(dl)
    
    -- 5. 处理点击逻辑
    if is_clicked and not self.is_opened then
        self.is_opened = true
        self.scale_anim = 1.2 -- 点击瞬间放大一点
        
        -- 触发特效
        self.particles:spawn_explosion(cx, draw_y, 30, "confetti")
        
        return true -- 返回 true 表示刚刚发生了“打开”事件
    end
    
    return false
end

return Chest