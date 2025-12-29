-- @description Zyc Startup Actions Manager
-- @version 2.2.1
-- @author Yicheng Zhu (Ethan)
-- @changelog
--   + 配合 ReaPet 1.0.4.4 更新
--   + 确保所有依赖文件（运行库、语言包）正确被索引
-- @provides
--   [main] .
--   zyc_startup_actions_run.lua
--   utils/i18n.lua
--   i18n/*.lua
-- @about
--   这是一个强大的 REAPER 启动项管理器，允许你配置 REAPER 启动时自动运行的动作。
--   支持默认动作（如 ReaPet）和自定义用户动作。
local r = reaper
local script_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])')
local run_script_path = script_path .. 'zyc_startup_actions_run.lua'

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
        -- 确保目录存在（使用跨平台路径连接）
        local data_dir = join_path(resource_path, "Data", "StartupActions")
        r.RecursiveCreateDirectory(data_dir, 0)
        local new_config_path = join_path(data_dir, "zyc_startup_actions_cfg.lua")
        
        -- 数据迁移：从旧位置迁移到新位置（如果旧位置有数据且新位置没有）
        local old_config_path = script_path .. 'zyc_startup_actions_cfg.lua'
        
        -- 检查新位置是否已有数据
        local new_file = io.open(new_config_path, "r")
        local new_file_exists = new_file ~= nil
        if new_file then new_file:close() end
        
        -- 如果新位置没有数据，尝试从旧位置迁移
        if not new_file_exists then
            local old_file = io.open(old_config_path, "r")
            if old_file then
                local content = old_file:read("*a")
                old_file:close()
                if content and #content > 0 then
                    -- 迁移数据到新位置
                    local new_file = io.open(new_config_path, "w")
                    if new_file then
                        new_file:write(content)
                        new_file:close()
                        -- 迁移成功后，可以选择删除旧文件（可选）
                        -- os.remove(old_config_path)
                    end
                end
            end
        end
        
        return new_config_path
    else
        -- 后备方案：如果无法获取资源路径，使用脚本目录（不推荐）
        return script_path .. 'zyc_startup_actions_cfg.lua'
    end
end

local config_path = get_config_path()

local I18n = dofile(script_path .. 'utils/i18n.lua')

-- 加载语言设置
local function load_language_setting()
    local file = io.open(config_path, 'r')
    if file then
        local content = file:read("*a")
        file:close()
        -- 尝试从配置文件中提取语言设置
        local lang_match = content:match('language%s*=%s*["\']([^"\']+)["\']')
        if lang_match then
            return lang_match
        end
    end
    return "en"  -- 默认英文
end

local saved_lang = load_language_setting()
I18n.init(saved_lang, script_path)

local script_name = I18n.get("window.title")
local ctx = nil
local config = nil
local refresh_config = true
local window_open = true
local run_script_cmd_id = nil
local desc_cache = {}
local picking_action = false
local picker_status = nil

if not r.ImGui_CreateContext then
    r.ShowMessageBox(I18n.get("messages.must_install_reaimgui"), "Error", 0)
    return
end
if not r.JS_Window_HandleFromAddress then
    r.ShowMessageBox(I18n.get("messages.must_install_jsapi"), "Error", 0)
    return
end

-- Check SWS Extension
if not r.NF_GetGlobalStartupAction and not r.CF_GetConfigPath and not r.BR_GetMediaItemByGUID then
    local msg = "SWS Extension is not installed.\n\n"
    msg = msg .. "SWS Extension is required for Startup Actions to work properly.\n\n"
    msg = msg .. "Please install SWS Extension from:\n"
    msg = msg .. "https://www.sws-extension.org/\n\n"
    msg = msg .. "Or via ReaPack: Extensions > ReaPack > Browse Packages > Search 'SWS'"
    r.ShowMessageBox(msg, "SWS Extension Required", 0)
    return
end

local function get_action_description(cmd_id)
    if not cmd_id or cmd_id == 0 then return nil end
    if desc_cache[cmd_id] then return desc_cache[cmd_id] end

    local desc = nil
    if r.kbd_getTextFromCmd then
        desc = r.kbd_getTextFromCmd(cmd_id, 0)
        if desc then
            desc = desc:match("^[^:]+: (.+)%.[^.]+$") or desc:match("^[^:]+: (.+)$") or desc
        end
    end
    
    if not desc and r.GetActionText then
        local ret, text = r.GetActionText(cmd_id, "", 4096)
        if ret then desc = text end
    end
    
    desc_cache[cmd_id] = desc or ("Command ID: " .. tostring(cmd_id))
    return desc_cache[cmd_id]
end

local function load_config()
    desc_cache = {} 
    _G.config = nil
    
    local success, err = pcall(function()
        dofile(config_path)
    end)
    
    if success and _G.config then
        config = _G.config
        config.user_actions = config.user_actions or {}
        config.default_actions = config.default_actions or {}
        config.has_asked_about_startup = config.has_asked_about_startup or false
        
        -- 加载语言设置
        if config.language then
            I18n.set_language(config.language)
        end
        
        return config
    end
    
    config = { 
        user_actions = {}, 
        default_actions = {}, 
        version = "2.2.0",
        has_asked_about_startup = false
    }
    _G.config = config
    return config
end

local function add_user_action(action_id)
    if not action_id or action_id == "" then
        return false, I18n.get("messages.invalid_action_id")
    end
    
    if not config then load_config() end
    if not config then
        return false, I18n.get("messages.config_load_failed")
    end
    if not config.user_actions then config.user_actions = {} end
    
    for _, v in ipairs(config.user_actions) do
        if v == action_id then
            return false, I18n.get("messages.action_already_exists")
        end
    end
    
    config.user_actions[#config.user_actions + 1] = action_id
    config.user_actions[action_id] = true
    
    local ok, err = pcall(save_config)
    if not ok then
        return false, I18n.get("messages.save_config_failed") .. tostring(err)
    end
    
    refresh_config = true
    return true
end

local function open_action_list_window()
    if r.JS_Window_ListAllTop and r.JS_Window_GetTitle then
        local list = select(2, r.JS_Window_ListAllTop())
        if not list or list == "" then
            list = r.JS_Window_ListAllTop()
        end
        if type(list) == "string" then
            for hwnd_str in list:gmatch("%d+") do
                local address = tonumber(hwnd_str)
                local hwnd = r.JS_Window_HandleFromAddress(address)
                
                if hwnd then
                    local title = r.JS_Window_GetTitle(hwnd)
                    if title then
                        local lower = title:lower()
                        if lower:find("action") or title:find("动作") then
                            r.JS_Window_SetFocus(hwnd)
                            return
                        end
                    end
                end
            end
        end
    end
    if r.Main_OnCommand then
        r.Main_OnCommand(40605, 0)
    end
end

local function is_listview(hwnd)
    if not hwnd then return false end
    if not r.JS_ListView_GetItemCount or not r.JS_ListView_GetColumnCount then return false end
    
    local ok1, count = pcall(r.JS_ListView_GetItemCount, hwnd)
    if not ok1 or not count or count <= 0 then return false end
    
    local ok2, cols = pcall(r.JS_ListView_GetColumnCount, hwnd)
    return ok2 and cols and cols >= 1
end

local function find_listview_in_window(hwnd)
    if not hwnd then return nil end
    if not r.JS_Window_GetWindow then return nil end
    
    local child = r.JS_Window_GetWindow(hwnd, "GW_CHILD")
    while child do
        if is_listview(child) then return child end
        local found = find_listview_in_window(child)
        if found then return found end
        child = r.JS_Window_GetWindow(child, "GW_HWNDNEXT")
    end
    return nil
end

local function resolve_action_id(cmd_text)
    if not cmd_text or cmd_text == "" then return nil end
    if cmd_text:match("^_") then
        return cmd_text
    end
    local num = tonumber(cmd_text)
    if num and num > 0 then
        return tostring(num)
    end
    if cmd_text:match("^RS") then
        return "_" .. cmd_text
    end
    return cmd_text
end

local function get_action_list_selection()
    if not r.JS_Window_GetFocus or not r.JS_Window_GetParent or not r.JS_ListView_GetNextSelected then
        return nil, I18n.get("messages.must_install_jsapi")
    end
    
    local focus = r.JS_Window_GetFocus()
    local top = focus
    local last = nil
    
    while top and top ~= last do
        last = top
        local parent = r.JS_Window_GetParent(top)
        if not parent then break end
        top = parent
    end
    
    local listview = nil
    if is_listview(focus) then
        listview = focus
    elseif top then
        local title = r.JS_Window_GetTitle(top) or ""
        local lower = title:lower()
        if not lower:find("action") and not title:find("动作") then
             return nil, I18n.get("messages.action_list_not_found")
        end
        listview = find_listview_in_window(top)
    end
    
    if not listview then
        return nil, I18n.get("messages.action_list_not_found")
    end
    
    local sel = r.JS_ListView_GetNextSelected(listview, -1)
    if not sel or sel < 0 then
        return nil, I18n.get("messages.no_selection")
    end
    
    local cols = r.JS_ListView_GetColumnCount(listview) or 0
    local cmd_text = ""
    local desc = ""
    
    if cols > 0 then cmd_text = r.JS_ListView_GetItemText(listview, sel, 0) end
    if cols > 1 then desc = r.JS_ListView_GetItemText(listview, sel, 1) end
    
    if (not cmd_text or cmd_text == "") and cols > 1 then
        for c = 1, cols - 1 do
            local t = r.JS_ListView_GetItemText(listview, sel, c)
            if t and t ~= "" then
                if t:match("^_") or t:match("^%d+$") or t:match("^RS") then
                    cmd_text = t
                    break
                end
                if desc == "" then desc = t end
            end
        end
    end
    
    if cmd_text == "" then
        return nil, I18n.get("messages.cannot_read_command_id")
    end
    
    return cmd_text, desc
end

local function pick_action_from_action_list()
    local cmd_text, err = get_action_list_selection()
    if not cmd_text then return nil, err end
    
    local action_id = resolve_action_id(cmd_text)
    if not action_id then
        return nil, I18n.get("messages.cannot_resolve_action_id") .. tostring(cmd_text)
    end
    
    local ok, save_err = add_user_action(action_id)
    if not ok then
        return nil, save_err
    end
    
    return action_id
end

local function check_and_create_runner_script()
    local file = io.open(run_script_path, 'r')
    if file then 
        file:close()
        return 
    end
    -- 获取配置路径（使用 REAPER 资源目录，跨平台兼容）
    local function join_path(...)
        local parts = {...}
        local path = table.concat(parts, "/")
        path = path:gsub("/+", "/")
        return path
    end
    
    local function get_config_path()
        local resource_path = reaper.GetResourcePath()
        if resource_path then
            return join_path(resource_path, "Data", "StartupActions", "zyc_startup_actions_cfg.lua")
        else
            -- 后备方案：使用脚本目录
            local script_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])')
            return script_path .. 'zyc_startup_actions_cfg.lua'
        end
    end
    
    local content = [[
local r = reaper
local config_path = ]] .. string.format("%q", get_config_path()) .. [[

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
                    -- 先注册脚本为 action，然后执行
                    local cmd_id = r.AddRemoveReaScript(true, 0, full_path, true)
                    if cmd_id and cmd_id > 0 then
                        r.Main_OnCommand(cmd_id, 0)
                    else
                        -- 如果注册失败，尝试直接 dofile（向后兼容）
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
]]
    local f = io.open(run_script_path, "w")
    if f then
        f:write(content)
        f:close()
    end
end

local function get_run_script_cmd_id()
    if run_script_cmd_id then return run_script_cmd_id end
    
    check_and_create_runner_script()

    local cmd_id = r.AddRemoveReaScript(true, 0, run_script_path, true)
    if cmd_id > 0 then
        run_script_cmd_id = r.ReverseNamedCommandLookup(cmd_id)
        if run_script_cmd_id and not run_script_cmd_id:match("^_RS") then
            if run_script_cmd_id:match("^RS") then
                run_script_cmd_id = "_" .. run_script_cmd_id
            end
        end
        return run_script_cmd_id
    end
    return nil
end

-- 自动注册到 SWS Global Startup Action
local function auto_register_startup_action()
    local target_cmd_id = get_run_script_cmd_id()
    if not target_cmd_id then
        return false
    end
    
    if not r.NF_GetGlobalStartupAction and not r.NF_GetGlobalStartupAction_Main then
        return false  -- SWS 未安装
    end
    
    local rv, desc, current_cmd_id
    if r.NF_GetGlobalStartupAction then
        rv, desc, current_cmd_id = r.NF_GetGlobalStartupAction()
    elseif r.NF_GetGlobalStartupAction_Main then
        rv, desc, current_cmd_id = r.NF_GetGlobalStartupAction_Main()
    end
    
    local normalize_id = function(id)
        if not id then return nil end
        local id_str = tostring(id)
        if id_str:match("^RS") then return "_" .. id_str
        elseif id_str:match("^_RS") then return id_str end
        return id_str
    end
    
    local normalized_target = normalize_id(target_cmd_id)
    local normalized_current = normalize_id(current_cmd_id)
    
    -- 如果已经注册，不需要操作
    if rv and normalized_target == normalized_current then
        return true
    end
    
    -- 如果当前有启动动作且还没询问过用户，需要提示
    if rv and normalized_target ~= normalized_current and not (config.has_asked_about_startup) then
        local message = I18n.get("messages.will_replace_startup")
        message = message .. I18n.get("messages.your_current_startup") .. (desc or I18n.get("messages.none")) .. "\n\n"
        message = message .. I18n.get("messages.click_ok_to_continue")
        
        local result = r.ShowMessageBox(message, script_name, 1)
        if result ~= 1 then
            -- 用户取消，标记已询问，但不注册
            config.has_asked_about_startup = true
            -- 需要保存这个标志，但避免递归调用 save_config
            -- 使用延迟保存，或者在下一次 save_config 时保存
            return false  -- 用户取消，不注册
        end
        
        -- 用户同意，标记已询问
        config.has_asked_about_startup = true
    end
    
    -- 注册启动动作
    local final_id = normalized_target or target_cmd_id
    if r.NF_SetGlobalStartupAction then
        r.NF_SetGlobalStartupAction(final_id)
        return true
    elseif r.NF_SetGlobalStartupAction_Main then
        r.NF_SetGlobalStartupAction_Main(final_id)
        return true
    end
    
    return false
end

local function save_config()
    local file = io.open(config_path, 'w')
    if not file then 
        return false 
    end
    
    file:write('config = {\n')
    file:write('    user_actions = {},\n')
    file:write('    default_actions = {},\n')
    file:write('    version = "2.2.0"\n')
    file:write('}\n\n')
    
    -- 保存语言设置
    local current_lang = I18n.get_current_language()
    if current_lang then
        file:write('config.language = "' .. current_lang .. '"\n\n')
    end
    
    -- 保存 has_asked_about_startup 标志
    if config.has_asked_about_startup then
        file:write('config.has_asked_about_startup = true\n\n')
    end
    
    if config.default_actions then
        for action, enabled in pairs(config.default_actions) do
            if type(action) == 'string' then
                file:write(string.format('config.default_actions["%s"] = %s\n', action, tostring(enabled)))
            end
        end
    end
    
    if config.user_actions then
        for i, action_id in ipairs(config.user_actions) do
            if type(action_id) == 'string' then
                file:write(string.format('config.user_actions[#config.user_actions + 1] = "%s"\n', action_id))
            end
        end
        for i, action_id in ipairs(config.user_actions) do
            if type(action_id) == 'string' and config.user_actions[action_id] ~= nil then
                file:write(string.format('config.user_actions["%s"] = %s\n', action_id, tostring(config.user_actions[action_id])))
            end
        end
    end
    
    file:close()
    
    -- 自动注册到 SWS Global Startup Action
    auto_register_startup_action()
    
    return true
end

-- ReaPet 版本对应的命名命令 ID（缓存）
-- 更新 ReaPet 版本时，可以更新此 ID 作为后备方案
-- 这个 ID 会通过自动查找功能自动更新，但也可以手动设置以提高性能
-- ReaPet v1.0.3: _RS2bff3c4d5742f41cc75fb9d04fa7c041c2d023d5
-- ReaPet v1.0.4: _RSa83ec3c4ca3001f4f071e3c521bbf360b94d9853
-- ReaPet v1.0.4.3: _RS2bff3c4d5742f41cc75fb9d04fa7c041c2d023d5
local REAPET_COMMAND_ID_CACHE = "_RS2bff3c4d5742f41cc75fb9d04fa7c041c2d023d5"

-- 自动查找 ReaPet 的命令 ID
local function find_reapet_command_id()
    -- 方案 1：尝试使用缓存的 ID
    if REAPET_COMMAND_ID_CACHE then
        local cmd_id = r.NamedCommandLookup(REAPET_COMMAND_ID_CACHE)
        if cmd_id and cmd_id > 0 then
            return REAPET_COMMAND_ID_CACHE
        end
    end
    
    -- 方案 2：使用相对路径（最可靠，因为两个脚本在同一仓库）
    local current_script_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])')
    if current_script_path then
        -- 从 StartupActions/ 到 ReaPet/
        -- 相对路径：../ReaPet/zyc_ReaPet.lua
        local relative_paths = {
            current_script_path .. "../ReaPet/zyc_ReaPet.lua",
            current_script_path .. "../../ReaPet/zyc_ReaPet.lua",
        }
        
        for _, path in ipairs(relative_paths) do
            -- 规范化路径
            path = path:gsub("/+", "/"):gsub("\\+", "\\")
            if r.file_exists(path) then
                -- 注册脚本以获取命令 ID
                local cmd_id = r.AddRemoveReaScript(true, 0, path, true)
                if cmd_id and cmd_id > 0 then
                    -- 获取命名命令 ID
                    local named_id = r.ReverseNamedCommandLookup(cmd_id)
                    if named_id then
                        -- 确保格式正确（以 _RS 开头）
                        if not named_id:match("^_RS") then
                            if named_id:match("^RS") then
                                named_id = "_" .. named_id
                            else
                                named_id = "_RS" .. named_id
                            end
                        end
                        return named_id
                    end
                end
            end
        end
    end
    
    -- 方案 3：通过绝对路径查找（后备方案）
    local resource_path = r.GetResourcePath()
    if resource_path then
        local absolute_paths = {
            resource_path .. "/Scripts/ReaPet/zyc_ReaPet.lua",
            resource_path .. "/Scripts/zyc_ReaPet.lua",
        }
        
        for _, path in ipairs(absolute_paths) do
            if r.file_exists(path) then
                -- 注册脚本以获取命令 ID
                local cmd_id = r.AddRemoveReaScript(true, 0, path, true)
                if cmd_id and cmd_id > 0 then
                    -- 获取命名命令 ID
                    local named_id = r.ReverseNamedCommandLookup(cmd_id)
                    if named_id then
                        -- 确保格式正确（以 _RS 开头）
                        if not named_id:match("^_RS") then
                            if named_id:match("^RS") then
                                named_id = "_" .. named_id
                            else
                                named_id = "_RS" .. named_id
                            end
                        end
                        return named_id
                    end
                end
            end
        end
    end
    
    return nil
end

local function get_default_startup_commands()
    local commands = {}
    
    -- 方案 1：自动查找 ReaPet 的命令 ID（优先）
    local reapet_id = find_reapet_command_id()
    if reapet_id then
        table.insert(commands, reapet_id)
        return commands
    end
    
    -- 方案 2：如果找不到 ID，使用相对路径方式（兼容性）
    local current_script_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])')
    local found_path = nil
    local found_relative = nil
    
    -- 优先使用相对路径
    if current_script_path then
        local relative_paths = {
            {path = current_script_path .. "../ReaPet/zyc_ReaPet.lua", relative = "@ReaPet/zyc_ReaPet.lua"},
            {path = current_script_path .. "../../ReaPet/zyc_ReaPet.lua", relative = "@ReaPet/zyc_ReaPet.lua"},
        }
        
        for _, path_info in ipairs(relative_paths) do
            -- 规范化路径
            path_info.path = path_info.path:gsub("/+", "/"):gsub("\\+", "\\")
            if r.file_exists(path_info.path) then
                found_path = path_info.path
                found_relative = path_info.relative
                break
            end
        end
    end
    
    -- 如果相对路径找不到，使用绝对路径
    if not found_path then
        local resource_path = r.GetResourcePath()
        if resource_path then
            local absolute_paths = {
                {path = resource_path .. "/Scripts/ReaPet/zyc_ReaPet.lua", relative = "@ReaPet/zyc_ReaPet.lua"},
                {path = resource_path .. "/Scripts/zyc_ReaPet.lua", relative = "@zyc_ReaPet.lua"},
            }
            
            for _, path_info in ipairs(absolute_paths) do
                if r.file_exists(path_info.path) then
                    found_path = path_info.path
                    found_relative = path_info.relative
                    break
                end
            end
        end
    end
    
    if found_path then
        -- 尝试注册并获取 ID
        local cmd_id = r.AddRemoveReaScript(true, 0, found_path, true)
        if cmd_id and cmd_id > 0 then
            local named_id = r.ReverseNamedCommandLookup(cmd_id)
            if named_id then
                if not named_id:match("^_RS") then
                    named_id = "_" .. named_id
                end
                table.insert(commands, named_id)
            else
                table.insert(commands, found_relative)
            end
        else
            table.insert(commands, found_relative)
        end
    else
        -- 如果文件都不存在，使用默认路径（让用户知道需要安装）
        table.insert(commands, "@ReaPet/zyc_ReaPet.lua")
    end
    
    return commands
end

local function draw_default_actions()
    if not config.default_actions then config.default_actions = {} end
    
    r.ImGui_Text(ctx, I18n.get("window.default_actions"))
    r.ImGui_Separator(ctx)
    
    local commands = get_default_startup_commands()
    
    if #commands == 0 then
        r.ImGui_TextDisabled(ctx, "No default actions available")
        r.ImGui_Spacing(ctx)
        return
    end
    
    for i, command in ipairs(commands) do
        if not command then goto continue end
        
        local desc = nil
        local cmd_id = nil
        
        -- 处理 @filename.lua 格式
        if command:match("^@") then
            -- 这是脚本路径格式
            local script_path = command:sub(2)  -- 移除 @
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
                -- 尝试注册脚本获取描述
                cmd_id = r.AddRemoveReaScript(true, 0, full_path, true)
                if cmd_id and cmd_id > 0 then
                    desc = get_action_description(cmd_id)
                    if not desc or desc == "" then
                        desc = command  -- 使用路径作为描述
                    end
                else
                    desc = command  -- 使用路径作为描述
                end
            else
                desc = command  -- 使用路径作为描述
            end
        else
            -- 处理命名命令 ID
            cmd_id = r.NamedCommandLookup(command)
            if cmd_id and cmd_id > 0 then
                desc = get_action_description(cmd_id)
            end
        end
        
        if desc then
            r.ImGui_PushID(ctx, "def_" .. (command or "unknown"))
            
            local enabled = false
            if config.default_actions[command] ~= nil then
                enabled = config.default_actions[command]
            else
                local alt_command = nil
                if command == "@ReaPet/zyc_ReaPet.lua" then
                    alt_command = "@zyc_ReaPet.lua"
                elseif command == "@zyc_ReaPet.lua" then
                    alt_command = "@ReaPet/zyc_ReaPet.lua"
                end
                if alt_command and config.default_actions[alt_command] ~= nil then
                    enabled = config.default_actions[alt_command]
                    config.default_actions[command] = enabled
                    config.default_actions[alt_command] = nil
                    save_config()
                end
            end
            
            local changed, new_enabled = r.ImGui_Checkbox(ctx, desc, enabled)
            if changed then
                config.default_actions[command] = new_enabled
                save_config()
            end
            r.ImGui_PopID(ctx)
        end
        
        ::continue::
    end
    r.ImGui_Spacing(ctx)
end

local function draw_user_actions()
    if not config.user_actions then config.user_actions = {} end
    
    r.ImGui_Text(ctx, I18n.get("window.user_actions"))
    r.ImGui_SameLine(ctx)
    r.ImGui_TextDisabled(ctx, I18n.get("window.drag_to_reorder"))
    r.ImGui_Separator(ctx)
    
    local move_from = -1
    local move_to = -1

    for i, command in ipairs(config.user_actions) do
        r.ImGui_PushID(ctx, i) 
        
        local cmd_id = tonumber(command) or r.NamedCommandLookup(command)
        if cmd_id and cmd_id > 0 then
            local desc = get_action_description(cmd_id)
            
            local changed, enabled = r.ImGui_Checkbox(ctx, desc, config.user_actions[command] or false)
            if changed then
                config.user_actions[command] = enabled
                save_config()
            end
            
            if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_SourceNoPreviewTooltip()) then
                r.ImGui_SetDragDropPayload(ctx, "DND_ACTION", tostring(i))
                r.ImGui_Text(ctx, desc)
                r.ImGui_EndDragDropSource(ctx)
            end
            
            if r.ImGui_BeginDragDropTarget(ctx) then
                local payload_retval, payload_data = r.ImGui_AcceptDragDropPayload(ctx, "DND_ACTION")
                if payload_retval then
                    move_from = tonumber(payload_data)
                    move_to = i
                end
                r.ImGui_EndDragDropTarget(ctx)
            end
            
            r.ImGui_SameLine(ctx)
            local avail_x, avail_y = r.ImGui_GetContentRegionAvail(ctx)
            local cursor_x = r.ImGui_GetCursorPosX(ctx)
            r.ImGui_SetCursorPosX(ctx, cursor_x + avail_x - 40)
            if r.ImGui_Button(ctx, I18n.get("window.delete"), 40, 0) then
                config.user_actions[command] = nil
                table.remove(config.user_actions, i)
                save_config()
                refresh_config = true
            end
        else
            config.user_actions[command] = nil
            table.remove(config.user_actions, i)
            save_config()
            refresh_config = true
        end
        r.ImGui_PopID(ctx)
    end

    if move_from ~= -1 and move_to ~= -1 and move_from ~= move_to then
        local item = config.user_actions[move_from]
        table.remove(config.user_actions, move_from)
        table.insert(config.user_actions, move_to, item)
        save_config()
    end
    
    r.ImGui_Spacing(ctx)
    
    local action_prompt_id = "user_actions"
    local button_label = I18n.get("window.add_action") .. "##button_" .. action_prompt_id
    local popup_label = I18n.get("window.add_action") .. "##popup_" .. action_prompt_id
    local selected_action = nil
    local selected_name = nil
    
    if r.ImGui_Button(ctx, button_label, -1) then
        if r.PromptForAction then
            r.PromptForAction(1, 0, 0)
        end
        r.ImGui_OpenPopup(ctx, popup_label)
    end
    
    if r.ImGui_IsPopupOpen(ctx, popup_label) then
        local viewport = r.ImGui_GetWindowViewport(ctx)
        if viewport then
            local center_x, center_y = r.ImGui_Viewport_GetCenter(viewport)
            r.ImGui_SetNextWindowPos(ctx, center_x, center_y, r.ImGui_Cond_Appearing(), 0.5, 0.5)
        end
        
        if r.ImGui_BeginPopupModal(ctx, popup_label, nil, 
            r.ImGui_WindowFlags_NoMove() | r.ImGui_WindowFlags_AlwaysAutoResize()) then
            
            local ret = 0
            if r.PromptForAction then
                ret = r.PromptForAction(0, 0, 0)
            end
            
            if ret and ret > 0 then
                local named_id = r.ReverseNamedCommandLookup(ret)
                selected_action = named_id and ("_" .. named_id) or tostring(ret)
                selected_name = r.kbd_getTextFromCmd and r.kbd_getTextFromCmd(ret, 0) or nil
                r.ImGui_CloseCurrentPopup(ctx)
            end
            
            r.ImGui_Text(ctx, I18n.get("window.select_action"))
            
            if (ret == -1) or r.ImGui_Button(ctx, I18n.get("window.cancel"), -1) then
                r.ImGui_CloseCurrentPopup(ctx)
            end
            
            r.ImGui_EndPopup(ctx)
        end
    end
    
    if selected_action then
        local exists = false
        for _, v in ipairs(config.user_actions) do
            if v == selected_action then 
                exists = true
                break 
            end
        end
        
        if not exists then
            config.user_actions[#config.user_actions + 1] = selected_action
            config.user_actions[selected_action] = true
            save_config()
            refresh_config = true
        else
            r.ShowMessageBox(I18n.get("messages.action_exists"), script_name, 0)
        end
        selected_action = nil
    end
    r.ImGui_Spacing(ctx)
end

local function draw_action_picker()
    r.ImGui_TextColored(ctx, 0xFFCC00FF, I18n.get("window.select_action"))
    r.ImGui_Separator(ctx)
    r.ImGui_TextWrapped(ctx, "1. Click an action in the Action List window\n2. Come back here and click " .. I18n.get("window.use_selected"))
    r.ImGui_Spacing(ctx)
    
    if r.ImGui_Button(ctx, I18n.get("window.open_action_list"), -1) then
        open_action_list_window()
    end
    if r.ImGui_Button(ctx, I18n.get("window.use_selected"), -1) then
        local action_id, err = pick_action_from_action_list()
        if action_id then
            picking_action = false
            picker_status = nil
        else
            picker_status = err or I18n.get("messages.read_action_failed")
        end
    end
    if r.ImGui_Button(ctx, I18n.get("window.cancel"), -1) then
        picking_action = false
        picker_status = nil
    end
    
    if picker_status then
        r.ImGui_Spacing(ctx)
        r.ImGui_TextColored(ctx, 0xFF5555FF, picker_status)
    end
end

local Loop = {}
function Loop.Start()
    if refresh_config then load_config(); refresh_config = false end
end

function Loop.CreateWindow()
    if not ctx then ctx = r.ImGui_CreateContext(script_name) end
    
    local window_width = 360
    local window_height = 480
    
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), 12.0)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 16, 16)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 8.0)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 0.5, 0.5)
    
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), 0x2A2A2AFF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x3A3A3AFF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), 0x4A4A4AFF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), 0x4ECDC4FF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x4D9FFFFF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0x5DAFFFFF)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), 0x3D8FEFFF)
    
    local flags = r.ImGui_WindowFlags_NoTitleBar() | 
                 r.ImGui_WindowFlags_NoScrollbar()
    
    r.ImGui_SetNextWindowSize(ctx, window_width, window_height, r.ImGui_Cond_FirstUseEver())
    
    local visible, open = r.ImGui_Begin(ctx, script_name, true, flags)
    local close_button_clicked = false
    
    if visible then
        local window_width_actual = r.ImGui_GetWindowWidth(ctx)
        local button_size = 24
        local padding = 8
        
        r.ImGui_Text(ctx, script_name)
        
        -- 语言选择器（在标题旁边）
        r.ImGui_SameLine(ctx, window_width_actual - button_size - padding - 120)
        local current_lang = I18n.get_current_language()
        local supported_langs = I18n.get_supported_languages()
        local lang_display = {}
        local current_lang_idx = 0
        for i, lang in ipairs(supported_langs) do
            local display = I18n.get_language_name(lang) .. " (" .. lang:upper() .. ")"
            table.insert(lang_display, display)
            if lang == current_lang then
                current_lang_idx = i - 1
            end
        end
        
        r.ImGui_SetNextItemWidth(ctx, 100)
        local changed_lang, new_lang_idx = r.ImGui_Combo(ctx, "🌐##lang_combo", current_lang_idx, table.concat(lang_display, "\0") .. "\0", #lang_display)
        if changed_lang and new_lang_idx >= 0 and new_lang_idx < #supported_langs then
            local selected_lang = supported_langs[new_lang_idx + 1]
            I18n.set_language(selected_lang)
            -- 保存语言设置到配置文件
            local file = io.open(config_path, 'r')
            local content = ""
            if file then
                content = file:read("*a")
                file:close()
            end
            -- 添加或更新语言设置
            if not content:match("language%s*=") then
                content = content .. '\nconfig.language = "' .. selected_lang .. '"\n'
            else
                content = content:gsub('language%s*=%s*["\'][^"\']*["\']', 'language = "' .. selected_lang .. '"')
            end
            local f = io.open(config_path, 'w')
            if f then
                f:write(content)
                f:close()
            end
        end
        
        r.ImGui_SameLine(ctx, window_width_actual - button_size - padding)
        
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x00000000)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0x3A3A3AFF)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), 0x4A4A4AFF)
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), 0xCCCCCCFF)
        
        if r.ImGui_Button(ctx, "×", button_size, button_size) then
            close_button_clicked = true
        end
        
        r.ImGui_PopStyleColor(ctx, 4)
        r.ImGui_Spacing(ctx)
        
        if picking_action then
            draw_action_picker()
        else
            -- 显示状态（可选，简洁版本）
            local target_cmd_id = get_run_script_cmd_id()
            local is_registered = false
            
            if target_cmd_id then
                local current_startup_id = nil
                if r.NF_GetGlobalStartupAction then
                    local rv, desc, cmd_id = r.NF_GetGlobalStartupAction()
                    current_startup_id = cmd_id
                elseif r.NF_GetGlobalStartupAction_Main then
                    local rv, desc, cmd_id = r.NF_GetGlobalStartupAction_Main()
                    current_startup_id = cmd_id
                end
                
                if current_startup_id then
                    local normalize_id = function(id)
                        if not id then return nil end
                        local id_str = tostring(id)
                        if id_str:match("^RS") then return "_" .. id_str
                        elseif id_str:match("^_RS") then return id_str end
                        return id_str
                    end
                    local normalized_target = normalize_id(target_cmd_id)
                    local normalized_current = normalize_id(current_startup_id)
                    is_registered = (normalized_target == normalized_current)
                end
            end

            if is_registered then
                r.ImGui_TextColored(ctx, 0x00FF00FF, "✓ " .. I18n.get("window.status_active"))
            else
                r.ImGui_TextColored(ctx, 0xFFAA00FF, "⚠ " .. I18n.get("window.status_inactive"))
            end
            r.ImGui_TextDisabled(ctx, I18n.get("window.auto_save_hint"))

            r.ImGui_Spacing(ctx)
            r.ImGui_Separator(ctx)
            r.ImGui_Spacing(ctx)
            
            if r.ImGui_BeginChild(ctx, "list_region", 0, -r.ImGui_GetFrameHeightWithSpacing(ctx), 0) then
                draw_default_actions()
                draw_user_actions()
                r.ImGui_EndChild(ctx)
            end
        end
        r.ImGui_End(ctx)
    end
    r.ImGui_PopStyleColor(ctx, 7)
    r.ImGui_PopStyleVar(ctx, 4)
    window_open = open and not close_button_clicked
end

local loop
loop = function()
    Loop.Start()
    Loop.CreateWindow()
    if window_open then 
        r.defer(loop) 
    else 
        if ctx and r.ImGui_DestroyContext then
            r.ImGui_DestroyContext(ctx)
        end
    end
end

load_config()

-- 初始化时自动注册（如果配置已存在）
local function check_and_set_startup_action_on_init()
    -- 只在首次运行时检查，之后由用户操作触发自动注册
    -- 这里不再自动注册，避免干扰用户
end

r.defer(loop)
check_and_set_startup_action_on_init()

