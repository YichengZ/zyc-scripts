-- core/tracker.lua
-- 核心统计模块：负责数据加载、保存、以及 Reaper 状态变化的检测
-- 优化版：引入 Dirty Flag 机制，消除操作时的瞬时卡顿

local r = reaper
local json = require("utils.json") 

local Tracker = {}
Tracker.__index = Tracker

-- [配置] 文件路径与 Key
local SCRIPT_PATH = debug.getinfo(1, "S").source:match("@(.*[\\//])")

-- [辅助函数] 跨平台路径连接
local function join_path(...)
    local parts = {...}
    local path = table.concat(parts, "/")
    -- 规范化路径：统一使用 /，REAPER API 和 io.open 都能处理
    path = path:gsub("/+", "/")
    return path
end

-- 使用 REAPER 资源目录保存用户数据，避免更新时数据丢失
-- 标准位置：ResourcePath/Data/ReaPet/companion_data.json
-- Windows: C:\Users\...\AppData\Roaming\REAPER\Data\ReaPet\companion_data.json
-- macOS: /Users/.../Library/Application Support/REAPER/Data/ReaPet/companion_data.json
local function get_data_file_path()
    local resource_path = r.GetResourcePath()
    if resource_path then
        -- 确保目录存在（使用跨平台路径连接）
        local data_dir = join_path(resource_path, "Data", "ReaPet")
        r.RecursiveCreateDirectory(data_dir, 0)
        return join_path(data_dir, "companion_data.json")
    else
        -- 后备方案：如果无法获取资源路径，使用脚本目录（不推荐）
        return SCRIPT_PATH .. "../data/companion_data.json"
    end
end
local DATA_FILE = get_data_file_path()
local PROJ_KEY = "ReaperCompanion_stats"
local PROJ_ID_KEY = "project_id"
local AFK_THRESHOLD = 60 

-- [常量] Global Stats 字段白名单（用于保存和加载）
-- 注意：排除 coin_system 和 shop_system，它们由各自的模块管理
local GLOBAL_STATS_FIELDS = {
    "total_operations", "total_time", "active_time", "global_undo_count",
    "projects", "plugin_cache", "treasure_box", "pomo_presets",
    "ui_settings", "operations_by_action", "total_focus_sessions",
    "total_focus_time", "schemaVersion"
}

-- [辅助] 读写文件 (保护模式，防止崩溃)
local function load_json_file(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local ok, data = pcall(json.decode, content)
        if ok and type(data) == "table" then return data end
    end
    return nil
end

local function save_json_file(path, data)
    local file = io.open(path, "w+")
    if file then
        -- 使用 pcall 保护 encode 过程
        local ok, str = pcall(json.encode, data)
        if ok then
            file:write(str)
        end
        file:close()
    end
end

-- [构造函数]
function Tracker:new()
    local instance = setmetatable({}, self)
    
    -- 数据结构初始化
    instance.global_stats = {
        total_operations = 0,
        total_time = 0,
        active_time = 0,
        global_undo_count = 0,
        projects = {}
    }
    
    instance.project_stats = {
        actions = 0,
        total_time = 0,
        active_time = 0,
        project_undo_count = 0,
        operations_by_action = {},
        total_focus_sessions = 0,
        total_focus_time = 0
    }
    
    -- 运行时状态监测变量
    instance.current_proj = nil
    instance.last_proj_count = 0
    instance.last_undo_action = ""
    instance.last_play_state = 0
    
    instance.last_action_time = os.time()
    instance.last_timer_update = os.time()
    
    -- [优化] 脏标记与保存节流
    instance.is_proj_dirty = false     -- 项目数据是否变动
    instance.is_global_dirty = false   -- 全局数据是否变动
    instance.last_save_ts = os.time()  -- 上次保存时间戳
    instance.SAVE_THROTTLE = 2.0       -- 最小保存间隔(秒)，避免过于频繁的序列化
    
    -- [修复] 保存旧工程数据的临时变量
    instance.pending_old_project_data = nil  -- 待保存的旧工程数据
    instance.pending_old_project_id = nil   -- 待保存的旧工程ID
    
    instance:init()
    return instance
end

-- [初始化] 加载数据
function Tracker:init()
    -- 1. 加载全局数据
    local loaded_global = load_json_file(DATA_FILE)
    if loaded_global then
        -- 使用白名单机制，只加载 global_stats 相关字段
        -- 排除 coin_system 和 shop_system，避免数据混乱
        for _, key in ipairs(GLOBAL_STATS_FIELDS) do
            if loaded_global[key] ~= nil then
                self.global_stats[key] = loaded_global[key]
            end
        end
    end
    
    -- 2. 初始化当前工程状态
    self.current_proj = r.EnumProjects(-1, 0)
    self:load_current_project_stats()
    
    -- 3. 初始化监测器状态
    self.last_proj_count = (r.GetProjectStateChangeCount and r.GetProjectStateChangeCount(0)) or 0
    self.last_undo_action = (r.Undo_CanUndo2 and r.Undo_CanUndo2(0)) or ""
    self.last_play_state = r.GetPlayState() or 0
end

-- [内部] 加载当前工程统计
-- 数据优先级：RPP扩展属性 > 全局JSON备份 > 默认值
function Tracker:load_current_project_stats(is_new_project)
    local _, val = r.GetProjExtState(0, "ReaperCompanion", PROJ_KEY)
    local has_rpp_data = false
    
    -- 1. 优先从RPP扩展属性加载数据
    if val ~= "" then
        local ok, data = pcall(json.decode, val)
        if ok and type(data) == "table" then
            self.project_stats = {
                actions = data.actions or 0,
                total_time = data.total_time or 0,
                active_time = data.active_time or 0,
                operations_by_action = data.operations_by_action or {},
                project_undo_count = data.project_undo_count or 0,
                total_focus_sessions = data.total_focus_sessions or 0,
                total_focus_time = data.total_focus_time or 0
            }
            has_rpp_data = true
        else
            -- RPP数据损坏，重置
            self:_reset_project_stats()
        end
    else
        -- RPP没有数据，重置
        self:_reset_project_stats()
    end
    
    -- 2. 获取/创建工程ID
    -- 如果是新工程，强制生成新ID；否则正常获取/创建ID
    local project_id = self:get_or_create_project_id(is_new_project == true)
    
    -- 3. 如果RPP没有数据，尝试从全局JSON恢复（作为备份）
    if not has_rpp_data and not is_new_project and project_id then
        if self.global_stats.projects and self.global_stats.projects[project_id] then
            local json_proj_data = self.global_stats.projects[project_id]
            -- 验证工程是否匹配（通过路径或名称）
            local current_path = r.GetProjectPath(0, "") or ""
            local _, current_name = r.EnumProjects(-1, 0)
            current_name = current_name or ""
            
            local stored_project = json_proj_data
            local is_match = false
            
            -- 如果路径匹配，认为是同一工程
            if stored_project.path and stored_project.path ~= "" and current_path ~= "" then
                is_match = (stored_project.path == current_path)
            -- 如果路径都为空，比较名称
            elseif (not stored_project.path or stored_project.path == "") and current_path == "" then
                local stored_name = stored_project.name or ""
                is_match = (stored_name == current_name)
            end
            
            -- 只有匹配时才恢复数据
            if is_match then
                if json_proj_data.actions then self.project_stats.actions = json_proj_data.actions end
                if json_proj_data.total_time then self.project_stats.total_time = json_proj_data.total_time end
                if json_proj_data.active_time then self.project_stats.active_time = json_proj_data.active_time end
                if json_proj_data.operations_by_action then self.project_stats.operations_by_action = json_proj_data.operations_by_action end
                if json_proj_data.project_undo_count then self.project_stats.project_undo_count = json_proj_data.project_undo_count end
                
                -- 恢复后立即保存到RPP（确保数据持久化）
                self.is_proj_dirty = true
            end
        end
    end
    
    self.is_proj_dirty = false
end

function Tracker:_reset_project_stats()
    self.project_stats = { 
        actions = 0, total_time = 0, active_time = 0, 
        operations_by_action = {}, project_undo_count = 0,
        total_focus_sessions = 0, total_focus_time = 0
    }
end

-- [内部] 保存当前工程统计 (到 RPP 文件)
-- [优化] 只有 dirty 时才会被 update 循环调用，或者强制调用
function Tracker:save_current_project_stats()
    r.SetProjExtState(0, "ReaperCompanion", PROJ_KEY, json.encode(self.project_stats))
    self.is_proj_dirty = false
end

-- [内部] 保存指定工程的数据（通过工程指针）
-- 注意：REAPER API 限制，只能保存到当前活动的工程
-- 如果工程已经切换，需要通过其他方式保存
function Tracker:save_project_stats_to_rpp(project_ptr, project_stats_data)
    -- 由于 REAPER API 限制，SetProjExtState 只能保存到当前活动的工程
    -- 如果 project_ptr 不是当前工程，无法直接保存
    -- 所以这个方法实际上只能保存当前工程的数据
    local cur_proj, _ = r.EnumProjects(-1, 0)
    if cur_proj == project_ptr then
        r.SetProjExtState(0, "ReaperCompanion", PROJ_KEY, json.encode(project_stats_data))
        return true
    end
    return false
end

-- [内部] 获取工程信息
function Tracker:get_project_info()
    local _, name = r.EnumProjects(-1, 0)
    local path = r.GetProjectPath(0, "")
    -- 注意：get_project_info通常在工程切换后调用
    -- 此时ID已经通过load_current_project_stats正确设置，直接读取即可
    local _, id_val = r.GetProjExtState(0, "ReaperCompanion", PROJ_ID_KEY)
    local id = id_val
    -- 如果ID为空（理论上不应该发生，因为load_current_project_stats已经处理），则获取/创建
    if id == "" or not id then
        id = self:get_or_create_project_id(false)
    end
    
    return {
        id = id,
        name = name or "未命名工程",
        path = path or "",
        first_seen = os.time(),
        last_seen = os.time()
    }
end

-- [内部] 检测是否为新工程
function Tracker:_is_new_project()
    local _, name = r.EnumProjects(-1, 0)
    local path = r.GetProjectPath(0, "")
    -- 新建工程通常路径为空，名称为空或"未命名工程"
    -- 同时检查扩展状态是否为空（新工程通常没有扩展状态）
    local _, stats_val = r.GetProjExtState(0, "ReaperCompanion", PROJ_KEY)
    local _, id_val = r.GetProjExtState(0, "ReaperCompanion", PROJ_ID_KEY)
    return (path == "" or path == nil) and (stats_val == "" and id_val == "")
end

-- [内部] 验证工程ID是否匹配当前工程
function Tracker:_validate_project_id(project_id)
    if not project_id or not self.global_stats.projects or not self.global_stats.projects[project_id] then
        return false
    end
    
    local stored_project = self.global_stats.projects[project_id]
    local current_path = r.GetProjectPath(0, "") or ""
    local _, current_name = r.EnumProjects(-1, 0)
    current_name = current_name or ""
    
    -- 如果路径匹配，则认为是同一工程
    if stored_project.path and stored_project.path ~= "" and current_path ~= "" then
        return stored_project.path == current_path
    end
    
    -- 如果路径都为空，比较名称
    if (not stored_project.path or stored_project.path == "") and current_path == "" then
        local stored_name = stored_project.name or ""
        return stored_name == current_name
    end
    
    -- 默认不匹配（安全策略）
    return false
end

-- [内部] 生成新的工程ID（确保唯一性）
function Tracker:_generate_new_project_id()
    math.randomseed(os.time() + os.clock() * 1000)
    local new_id = tostring(math.random(100000000, 999999999))
    
    -- 检查全局JSON中是否已存在该ID（极小概率但需要处理）
    if self.global_stats.projects and self.global_stats.projects[new_id] then
        -- 如果存在，递归生成新ID（最多尝试10次）
        for i = 1, 10 do
            math.randomseed(os.time() + os.clock() * 1000 + i)
            new_id = tostring(math.random(100000000, 999999999))
            if not self.global_stats.projects[new_id] then
                break
            end
        end
    end
    
    return new_id
end

-- [内部] 获取/创建工程ID
-- 注意：不要轻易生成新ID，因为ID是工程数据的唯一标识
-- 只有在确定是新工程时才生成新ID
function Tracker:get_or_create_project_id(force_new)
    -- 如果强制生成新ID（新建工程时）
    if force_new then
        local new_id = self:_generate_new_project_id()
        r.SetProjExtState(0, "ReaperCompanion", PROJ_ID_KEY, new_id)
        return new_id
    end
    
    local _, val = r.GetProjExtState(0, "ReaperCompanion", PROJ_ID_KEY)
    if val == "" then
        -- 如果扩展状态为空，生成新ID
        val = self:_generate_new_project_id()
        r.SetProjExtState(0, "ReaperCompanion", PROJ_ID_KEY, val)
    else
        -- 如果扩展状态存在，直接使用（不验证，因为RPP数据是主要数据源）
        -- 即使ID在全局JSON中不匹配，也保留原ID，因为RPP数据是权威的
        -- 这样可以避免因为ID验证失败导致数据丢失
    end
    return val
end

-- [核心] 更新逻辑
-- 优化点：不再在操作发生时立即保存，而是标记 dirty
function Tracker:update()
    local triggered = false
    local now = os.time()
    
    -- A. 检测工程切换
    local cur_proj, _ = r.EnumProjects(-1, 0)
    if cur_proj ~= self.current_proj then
        -- [关键修复] 工程切换时的数据保存问题
        -- 问题：当检测到 cur_proj ~= self.current_proj 时，工程已经切换了
        -- 此时 r.SetProjExtState(0, ...) 会保存到新工程，而不是旧工程
        -- 
        -- 解决方案：
        -- 1. 如果旧工程有未保存的数据（pending_old_project_data），说明之前保存过，使用那个数据
        -- 2. 否则，使用当前的 project_stats（但注意：这可能是新工程的数据！）
        -- 3. 通过 pending_old_project_id 来识别旧工程
        
        -- 保存旧工程数据到全局JSON（作为备份）
        if self.current_proj and self.pending_old_project_id then
            -- 使用之前保存的旧工程数据
            local old_stats = self.pending_old_project_data
            if old_stats then
                if not self.global_stats.projects then self.global_stats.projects = {} end
                if not self.global_stats.projects[self.pending_old_project_id] then
                    self.global_stats.projects[self.pending_old_project_id] = {}
                end
                local old_proj = self.global_stats.projects[self.pending_old_project_id]
                old_proj.actions = old_stats.actions
                old_proj.total_time = old_stats.total_time
                old_proj.active_time = old_stats.active_time
                old_proj.operations_by_action = old_stats.operations_by_action
                old_proj.project_undo_count = old_stats.project_undo_count
                old_proj.last_seen = now
            end
        end
        
        -- 检测是否为新工程
        local is_new_project = self:_is_new_project()
        
        -- 切换逻辑
        self.current_proj = cur_proj
        -- load_current_project_stats 已经处理了数据加载逻辑：
        -- 1. 优先从RPP加载
        -- 2. 如果RPP为空，从JSON恢复（作为备份）
        -- 3. 如果是新工程，重置数据
        self:load_current_project_stats(is_new_project)
        
        -- 如果从JSON恢复了数据，立即保存到RPP（确保数据持久化）
        if self.is_proj_dirty then
            self:save_current_project_stats()
        end
        
        -- 更新全局记录（同步当前工程数据到全局JSON，作为备份）
        local new_project_info = self:get_project_info()
        self:_sync_project_to_global(new_project_info, now)
        
        -- 重置监测器
        self.last_proj_count = (r.GetProjectStateChangeCount and r.GetProjectStateChangeCount(0)) or 0
        self.last_undo_action = (r.Undo_CanUndo2 and r.Undo_CanUndo2(0)) or ""
        self.last_action_time = now
        self.last_timer_update = now
        
        -- 清空待保存的旧工程数据
        self.pending_old_project_data = nil
        self.pending_old_project_id = nil
    end
    
    -- B. 实时操作检测
    local now_proj_count = (r.GetProjectStateChangeCount and r.GetProjectStateChangeCount(0)) or 0
    local current_undo = (r.Undo_CanUndo2 and r.Undo_CanUndo2(0)) or ""
    local current_play = r.GetPlayState() or 0
    
    -- 1. 工程状态改变
    if now_proj_count ~= self.last_proj_count then
        self.global_stats.total_operations = (self.global_stats.total_operations or 0) + 1
        self.project_stats.actions = (self.project_stats.actions or 0) + 1
        
        self.last_proj_count = now_proj_count
        self.last_action_time = now
        self.is_proj_dirty = true    -- [优化] 仅标记
        self.is_global_dirty = true  -- [优化] 仅标记
        triggered = true
    end
    
    -- 2. Undo 栈改变
    if current_undo ~= self.last_undo_action then
        if current_undo ~= "" then
            if not self.project_stats.operations_by_action then self.project_stats.operations_by_action = {} end
            local old_count = self.project_stats.operations_by_action[current_undo] or 0
            self.project_stats.operations_by_action[current_undo] = old_count + 1
        end
        
        if current_undo:lower():find("undo") then
             self.global_stats.global_undo_count = (self.global_stats.global_undo_count or 0) + 1
             self.project_stats.project_undo_count = (self.project_stats.project_undo_count or 0) + 1
        end
        
        self.last_undo_action = current_undo
        self.last_action_time = now
        self.is_proj_dirty = true    -- [优化] 仅标记
        self.is_global_dirty = true  -- [优化] 仅标记
        triggered = true
    end
    
    -- 3. 播放状态改变
    if current_play ~= self.last_play_state then
        self.global_stats.total_operations = (self.global_stats.total_operations or 0) + 1
        self.project_stats.actions = (self.project_stats.actions or 0) + 1
        
        if not self.project_stats.operations_by_action then self.project_stats.operations_by_action = {} end
        local action_name = (current_play == 1 or current_play == 2) and "Play" or "Pause"
        local old_count = self.project_stats.operations_by_action[action_name] or 0
        self.project_stats.operations_by_action[action_name] = old_count + 1
        
        self.last_play_state = current_play
        self.last_action_time = now
        self.is_proj_dirty = true    -- [优化] 仅标记
        self.is_global_dirty = true  -- [优化] 仅标记
        triggered = true
    end
    
    -- C. 计时器更新 (每秒一次)
    if now ~= self.last_timer_update then
        self.global_stats.total_time = (self.global_stats.total_time or 0) + 1
        self.project_stats.total_time = (self.project_stats.total_time or 0) + 1
        
        if now - self.last_action_time < AFK_THRESHOLD then
            self.global_stats.active_time = (self.global_stats.active_time or 0) + 1
            self.project_stats.active_time = (self.project_stats.active_time or 0) + 1
        end
        
        -- 数据变动，标记脏
        self.is_proj_dirty = true
        self.is_global_dirty = true -- 时间变动不需要每次都存盘，下面 flush 会控制频率
        
        -- 定期同步工程信息到全局结构 (每60秒)
        if now % 60 == 0 then
            local project_info = self:get_project_info()
            self:_sync_project_to_global(project_info, now)
            self:save_global_data() -- 强制保存一次全局
        end
        
        self.last_timer_update = now
    end
    
    -- [优化] 统一的数据保存检查 (Flush)
    -- 只有当数据脏了，且距离上次保存超过阈值(2秒)，才执行保存
    if now - self.last_save_ts > self.SAVE_THROTTLE then
        if self.is_proj_dirty then
            -- 保存当前工程数据到RPP
            self:save_current_project_stats()
            
            -- [关键修复] 同时保存工程ID和数据到临时变量，用于工程切换时恢复
            -- 这样在工程切换时，即使无法保存到旧工程的RPP，也能保存到全局JSON
            local _, project_id = r.GetProjExtState(0, "ReaperCompanion", PROJ_ID_KEY)
            if project_id ~= "" then
                self.pending_old_project_id = project_id
                -- 深拷贝project_stats（避免引用问题）
                self.pending_old_project_data = {
                    actions = self.project_stats.actions,
                    total_time = self.project_stats.total_time,
                    active_time = self.project_stats.active_time,
                    operations_by_action = {},
                    project_undo_count = self.project_stats.project_undo_count,
                    total_focus_sessions = self.project_stats.total_focus_sessions,
                    total_focus_time = self.project_stats.total_focus_time
                }
                -- 深拷贝operations_by_action
                if self.project_stats.operations_by_action then
                    for k, v in pairs(self.project_stats.operations_by_action) do
                        self.pending_old_project_data.operations_by_action[k] = v
                    end
                end
            end
            
            self.is_proj_dirty = false
        end
        -- 注意：Global Data 通常由 Main.lua 控制保存，这里我们只更新内存里的 Global Stats
        -- 但如果确实需要 Tracker 负责保存全局数据，可以在这里加判断
        -- 为了性能，我们尽量减少 global data 的 IO 操作
        self.last_save_ts = now
    end
    
    return triggered
end

-- [内部辅助] 同步当前工程数据到 Global 结构中
function Tracker:_sync_project_to_global(project_info, now)
    if project_info.id then
        if not self.global_stats.projects then self.global_stats.projects = {} end
        if not self.global_stats.projects[project_info.id] then
            self.global_stats.projects[project_info.id] = project_info
        end
        local p = self.global_stats.projects[project_info.id]
        p.actions = self.project_stats.actions
        p.total_time = self.project_stats.total_time
        p.active_time = self.project_stats.active_time
        p.operations_by_action = self.project_stats.operations_by_action
        p.project_undo_count = self.project_stats.project_undo_count
        p.last_seen = now
    end
end

-- [API] 获取当前统计摘要
function Tracker:get_display_stats()
    return {
        total_ops = self.global_stats.total_operations,
        proj_ops = self.project_stats.actions,
        active_time = self.project_stats.active_time,
        undo_count = self.project_stats.project_undo_count
    }
end

function Tracker:get_global_stats() return self.global_stats end
function Tracker:get_project_stats() return self.project_stats end

-- [API] 退出清理 (强制保存所有)
function Tracker:on_exit()
    self:save_current_project_stats()
    self:save_global_data()
end

-- [常量] Global Stats 字段白名单（用于保存和加载）
-- 注意：排除 coin_system 和 shop_system，它们由各自的模块管理
local GLOBAL_STATS_FIELDS = {
    "total_operations", "total_time", "active_time", "global_undo_count",
    "projects", "plugin_cache", "treasure_box", "pomo_presets",
    "ui_settings", "operations_by_action", "total_focus_sessions",
    "total_focus_time", "schemaVersion"
}

-- [内部] 保存全局数据
function Tracker:save_global_data()
    -- 读取旧数据
    local data = load_json_file(DATA_FILE) or {}
    
    local coin_system_backup = data.coin_system
    local shop_system_backup = data.shop_system
    
    -- 使用白名单机制更新字段（确保字段完整性）
    for _, key in ipairs(GLOBAL_STATS_FIELDS) do
        if self.global_stats[key] ~= nil then
            data[key] = self.global_stats[key]
        end
    end
    
    -- 特殊处理 schemaVersion（如果没有则设置默认值）
    if not data.schemaVersion then
    data.schemaVersion = self.global_stats.schemaVersion or 1
    end
    
    -- 保留 coin_system 和 shop_system（由各自的模块管理）
    if coin_system_backup then data.coin_system = coin_system_backup end
    if shop_system_backup then data.shop_system = shop_system_backup end
    
    save_json_file(DATA_FILE, data)
    self.is_global_dirty = false
end

return Tracker