-- ui/utils/particles.lua
-- 通用粒子系统：优化版 (带冲击波、阻力、强度缩放)
local Particles = {}
Particles.__index = Particles

function Particles:new()
    local instance = setmetatable({}, self)
    instance.pool = {}
    return instance
end

-- 辅助：设置颜色透明度
local function set_alpha(col, alpha_byte)
    return (col & 0xFFFFFF00) | math.floor(math.max(0, math.min(255, alpha_byte)))
end

-- 发射粒子 (爆炸效果)
-- x, y: 中心点
-- base_count: 基础数量 (建议传 10-20)
-- color_type: "confetti" | "gold" | "love"
-- magnitude: (可选) 强度系数，默认 1.0。建议传入 (coins_earned / 10) 或类似比例
function Particles:spawn_explosion(x, y, base_count, color_type, magnitude)
    magnitude = magnitude or 1.0
    
    -- 1. 根据强度调整参数
    -- 强度越高，粒子越多，但设有上限防止卡顿
    local count = math.floor(base_count * (0.8 + magnitude * 0.4)) 
    if count > 60 then count = 60 end 

    -- 强度越高，爆发速度越快 (范围更大)
    local speed_scale = 1.0 + math.min(2.0, magnitude * 0.5) 
    
    -- 2. 生成普通粒子
    for i = 1, count do
        local angle = math.random() * 6.28
        -- 速度随机范围：基础速度 * 强度加成
        -- (使用 dt 后，速度单位变为像素/秒，所以数值比较大)
        local speed = math.random(150, 400) * speed_scale
        
        -- 粒子大小也会随强度微调
        local size_base = (magnitude > 2.0) and 4 or 3
        local size = math.random() * size_base + 2
        
        local col = 0xFFFFFFFF
        if color_type == "confetti" then
            -- 高饱和度随机色
            local r = math.random(120, 255)
            local g = math.random(120, 255)
            local b = math.random(120, 255)
            col = (r << 24) | (g << 16) | (b << 8) | 0xFF
        elseif color_type == "gold" then
            -- 金色系：混入一点点亮白和深金
            local rnd = math.random()
            if rnd > 0.8 then col = 0xFFFFE0FF -- 亮淡金
            elseif rnd < 0.2 then col = 0xDAA520FF -- 老金
            else col = 0xFFD700FF end -- 纯金
        elseif color_type == "love" then
             col = 0xFF69B4FF -- 热粉色
        end

        table.insert(self.pool, {
            type = "circle",
            x = x, y = y,
            vx = math.cos(angle) * speed,
            -- y轴稍微向上偏，制造抛洒感
            vy = math.sin(angle) * speed - (100 * speed_scale), 
            life = 1.0 + math.random() * 0.5, -- 寿命
            decay = math.random() * 0.8 + 0.5, -- 衰减速率
            color = col,
            size = size,
            gravity = 800.0, -- 重力 (像素/秒^2)
            drag = 0.95 -- 空气阻力 (每帧保留速度比例)，制造"爆发后悬停"感
        })
    end

    -- 3. 生成冲击波 (Ring) - 仅当强度足够时
    if magnitude > 0.5 then
        local ring_count = (magnitude > 3.0) and 2 or 1
        for i = 1, ring_count do
            local ring_col = 0xFFFFFF00 -- 默认白色冲击波
            if color_type == "gold" then ring_col = 0xFFD70000 end -- 金色系用金色冲击波
            
            table.insert(self.pool, {
                type = "ring",
                x = x, y = y,
                size = 10, -- 初始大小
                target_size = 100 * speed_scale * (0.8 + i*0.2), -- 扩散目标大小
                life = 0.6, -- 冲击波消失得快
                life_max = 0.6,
                color = ring_col,
                width = 5.0 -- 线条粗细
            })
        end
    end
end

-- 更新 (现在需要传入 dt)
function Particles:update(dt)
    dt = dt or 0.016 -- 防止未传 dt 报错
    
    for i = #self.pool, 1, -1 do
        local p = self.pool[i]
        
        if p.type == "circle" then
            -- 物理更新
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + p.gravity * dt
            
            -- 阻力模拟 (让粒子爆发后迅速减速，而不是无限飞远)
            -- 这是一个简单的指数衰减近似
            local drag_factor = p.drag ^ (dt * 60) 
            p.vx = p.vx * drag_factor
            p.vy = p.vy * drag_factor

            p.life = p.life - p.decay * dt
            
        elseif p.type == "ring" then
            -- 冲击波扩散
            local progress = 1.0 - (p.life / p.life_max)
            -- 使用 ease out quart 让扩散有一个"嘭"的感觉
            local ease = 1 - (1 - progress) ^ 4
            p.current_size = p.size + (p.target_size - p.size) * ease
            
            p.life = p.life - dt
        end
        
        if p.life <= 0 then
            table.remove(self.pool, i)
        end
    end
end

function Particles:draw(dl)
    local r = reaper
    for _, p in ipairs(self.pool) do
        -- 1. 绘制圆形粒子
        if p.type == "circle" then
            local alpha = math.floor(math.max(0, p.life) * 255)
            local col = set_alpha(p.color, alpha)
            
            r.ImGui_DrawList_AddCircleFilled(dl, p.x, p.y, p.size, col)
            
        -- 2. 绘制冲击波 (圆环)
        elseif p.type == "ring" then
            local alpha_ratio = (p.life / p.life_max)
            local alpha = math.floor(alpha_ratio * 200) -- 冲击波稍微透明一点
            local col = (p.color & 0xFFFFFF00) | alpha
            
            -- 线条宽度随时间变细
            local thickness = p.width * alpha_ratio
            
            r.ImGui_DrawList_AddCircle(dl, p.x, p.y, p.current_size or p.size, col, 0, thickness)
        end
    end
end

return Particles