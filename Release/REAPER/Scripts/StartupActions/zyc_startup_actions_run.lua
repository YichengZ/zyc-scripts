-- @description Zyc Startup Actions Runner (Internal)
-- @version 2.2.0
-- @author Yicheng Zhu (Ethan)
-- @about
--   Internal script that executes the configured startup actions.
--   This script is automatically registered with SWS Global Startup Action
--   and should not be run manually.
-- @provides
-- @changelog
--   + Initial release

local r = reaper
local script_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])')
local config_path = script_path .. 'zyc_startup_actions_cfg.lua'

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

