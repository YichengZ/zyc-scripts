local r = reaper

-- 辅助函数：跨平台路径连接
local function join_path(...)
    local parts = {...}
    local path = table.concat(parts, "/")
    path = path:gsub("/+", "/")
    return path
end

-- 获取配置路径（使用 REAPER 资源目录，避免更新时数据丢失）
-- Windows: C:\Users\...\AppData\Roaming\REAPER\Data\StartupActions\zyc_startup_actions_cfg.lua
-- macOS: /Users/.../Library/Application Support/REAPER/Data/StartupActions/zyc_startup_actions_cfg.lua
local function get_config_path()
    local resource_path = r.GetResourcePath()
    if resource_path then
        return join_path(resource_path, "Data", "StartupActions", "zyc_startup_actions_cfg.lua")
    else
        -- 后备方案：使用脚本目录（不推荐）
        local script_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])')
        return script_path .. 'zyc_startup_actions_cfg.lua'
    end
end

local config_path = get_config_path()

if not r.file_exists(config_path) then
    return
end

local success = pcall(dofile, config_path)
if not success or not config then
    return
end

if config.user_actions then
    for i, action in ipairs(config.user_actions) do
        if config.user_actions[action] then
            local action_id = tonumber(action) or r.NamedCommandLookup(action)
            if action_id and action_id > 0 then
                r.Main_OnCommand(action_id, 0)
            end
        end
    end
end

if config.default_actions then
    for action, enabled in pairs(config.default_actions) do
        if enabled then
            -- 处理 @filename.lua 格式
            if action:match("^@") then
                local script_path = action:sub(2)  -- 移除 @
                local resource_path = r.GetResourcePath()
                local full_path = nil
                
                -- 如果是相对路径，转换为绝对路径
                if not script_path:match("^/") and not script_path:match("^[A-Za-z]:") then
                    if resource_path then
                        full_path = resource_path .. "/Scripts/" .. script_path
                    end
                else
                    full_path = script_path
                end
                
                if full_path and r.file_exists(full_path) then
                    local cmd_id = r.AddRemoveReaScript(true, 0, full_path, true)
                    if cmd_id and cmd_id > 0 then
                        r.Main_OnCommand(cmd_id, 0)
                    else
                        dofile(full_path)
                    end
                end
            else
                -- 处理命名命令 ID
                local action_id = tonumber(action) or r.NamedCommandLookup(action)
                if action_id and action_id > 0 then
                    r.Main_OnCommand(action_id, 0)
                end
            end
        end
    end
end

