--[[
  REAPER Companion - 宝箱模块 (Treasure)
  负责宝箱逻辑、插件扫描、随机插件插入
--]]

local Treasure = {}
local Config = require('config')
local Debug = require('utils.debug')

-- 加载依赖
local fx_scanner = nil
local script_path = nil

-- ========= 内部状态 =========
local available = false
local plugin_list = {}
local opened_plugins = {}
local cache_initialized = false
local last_scan = 0

-- ========= 调试变量 =========
local dbg_candidates = 0
local dbg_last_pick = nil
local dbg_last_result = nil
local dbg_last_clicked = 0

-- ========= 初始化 =========
function Treasure.init(path)
  script_path = path
  -- 尝试使用 require 加载 fx_scanner（更优雅的模块系统）
  local ok, scanner = pcall(require, 'core.fx_scanner')
  if ok and scanner then
    fx_scanner = scanner
  else
    -- 回退到 dofile（兼容旧代码）
    ok, scanner = pcall(dofile, script_path .. "core/fx_scanner.lua")
    if ok and scanner then
      fx_scanner = scanner
    else
      reaper.ShowMessageBox("无法加载 fx_scanner.lua", "错误", 0)
    end
  end
end

-- ========= 插件扫描 =========
local Debug = require('utils.debug')

local function generate_fx_list()
  if not fx_scanner then return {}, {} end
  Debug.log("GenerateFxList() 开始\n")
  local names, infos = fx_scanner.generate_fx_list()
  Debug.logf("GenerateFxList() 返回 %d 个插件\n", #(names or {}))
  return names or {}, infos or {}
end

local function filter_third_party_plugins(plugin_info_list)
  if not fx_scanner then return {} end
  return fx_scanner.filter_third_party_vst(plugin_info_list)
end

local function scan_all_plugins()
  reaper.ShowConsoleMsg("scan_all_plugins() 开始\n")
  local plugin_list, plugin_info_list = generate_fx_list()
  local new_plugins_found = 0
  
  reaper.ShowConsoleMsg("插件扫描：已扫描 " .. #plugin_list .. " 个插件\n")
  print("插件扫描：已扫描 " .. #plugin_list .. " 个插件")
  
  local third_party_plugins = filter_third_party_plugins(plugin_info_list)
  
  print("插件扫描：过滤后保留 " .. #third_party_plugins .. " 个第三方插件")
  for i = 1, math.min(3, #third_party_plugins) do
    print("  过滤后插件 " .. i .. ": " .. third_party_plugins[i].name)
  end
  
  return third_party_plugins, new_plugins_found
end

function Treasure.init_plugin_cache(global_stats)
  Debug.log("init_plugin_cache() 开始\n")
  if cache_initialized then
    Debug.log("插件缓存已初始化，跳过\n")
    return
  end
  
  local current_time = os.time()
  local should_scan = false
  
  if not global_stats.plugin_cache then
    should_scan = true
    Debug.log("插件缓存：首次运行，开始扫描插件\n")
    Debug.print("插件缓存：首次运行，开始扫描插件")
  elseif current_time - (global_stats.plugin_cache.last_scan_time or 0) > Config.PLUGIN_CACHE_SCAN_INTERVAL then
    should_scan = true
    Debug.log("插件缓存：缓存过期，重新扫描插件\n")
    Debug.print("插件缓存：缓存过期，重新扫描插件")
  end
  
  if should_scan then
    Debug.log("开始扫描插件...\n")
    local plugins, new_plugins = scan_all_plugins()
    
    global_stats.plugin_cache = {
      last_scan_time = current_time,
      total_plugins = #plugins,
      plugins = plugins
    }
    
    plugin_list = {}
    for _, plugin in ipairs(plugins) do
      table.insert(plugin_list, plugin.name)
    end
    Debug.print("插件缓存：构建宝箱候选列表，共 " .. #plugin_list .. " 个插件")
    
    last_scan = current_time
    cache_initialized = true
    
    Debug.print("插件缓存：扫描完成，共 " .. #plugins .. " 个VST插件")
    if new_plugins > 0 then
      Debug.print("插件缓存：发现 " .. new_plugins .. " 个新插件")
    end
  else
    if global_stats.plugin_cache and global_stats.plugin_cache.plugins then
      local filtered = filter_third_party_plugins(global_stats.plugin_cache.plugins)
      plugin_list = {}
      for _, plugin in ipairs(filtered) do
        table.insert(plugin_list, plugin.name)
      end
      Debug.print("插件缓存：从缓存加载(已过滤) " .. #plugin_list .. " 个第三方插件")
      for i = 1, math.min(3, #plugin_list) do
        Debug.print("  - " .. plugin_list[i])
      end
    end
    cache_initialized = true
  end
end

function Treasure.refresh_plugin_cache(global_stats)
  Debug.log("插件缓存：手动刷新开始\n")
  Debug.print("插件缓存：手动刷新开始")
  cache_initialized = false
  global_stats.plugin_cache = nil
  Treasure.init_plugin_cache(global_stats)
  Debug.log("插件缓存：手动刷新完成\n")
  Debug.print("插件缓存：手动刷新完成")
end

-- ========= 随机插件 =========
function Treasure.get_random_plugin()
  Debug.logf("get_random_plugin() 开始，候选数量: %d\n", #plugin_list)
  if #plugin_list == 0 then
    Debug.log("宝箱系统：没有可用的插件\n")
    Debug.print("宝箱系统：没有可用的插件")
    dbg_candidates = 0
    return nil
  end
  
  math.randomseed(os.time() + os.clock() * 1000)
  local random_index = math.random(1, #plugin_list)
  local selected_plugin = plugin_list[random_index]
  
  Debug.logf("宝箱系统：从 %d 个插件中随机选择: %s\n", #plugin_list, selected_plugin)
  Debug.print("宝箱系统：从 " .. #plugin_list .. " 个插件中随机选择: " .. selected_plugin)
  dbg_candidates = #plugin_list
  dbg_last_pick = selected_plugin
  return selected_plugin
end

-- ========= 插入插件 =========
function Treasure.insert_plugin_to_track(plugin_name)
  local track = reaper.GetSelectedTrack(0, 0)
  
  if not track then
    track = reaper.GetMasterTrack(0)
    Debug.print("宝箱系统：没有选中轨道，插入到主轨道")
  else
    local _, track_name = reaper.GetTrackName(track)
    Debug.print("宝箱系统：插入插件到轨道: " .. (track_name or "未命名"))
  end
  
  if track then
    local mode = -1000 - reaper.TrackFX_GetCount(track)
    local fx_index = reaper.TrackFX_AddByName(track, plugin_name, false, mode)
    if fx_index >= 0 then
      local rv, actual_name = reaper.TrackFX_GetFXName(track, fx_index, "")
      if rv then
        Debug.print("宝箱系统：成功插入插件 -> 期望: [" .. plugin_name .. "] 实际: [" .. actual_name .. "]")
        dbg_last_result = "Inserted OK: expected '" .. plugin_name .. "' got '" .. actual_name .. "'"
      else
        Debug.print("宝箱系统：成功插入插件 " .. plugin_name .. " (无法读取实际名称)")
        dbg_last_result = "Inserted OK: '" .. plugin_name .. "' (no name)"
      end
      return true, track
    else
      Debug.print("宝箱系统：插入插件 " .. plugin_name .. " 失败")
      dbg_last_result = "Insert FAILED: '" .. tostring(plugin_name) .. "'"
      return false, nil
    end
  end
  
  return false, nil
end

-- ========= 宝箱控制 =========
function Treasure.show()
  available = true
  Debug.log("=== Treasure.show() 被调用，宝箱已解锁 ===\n")
  Debug.print("Debug: 宝箱已手动显示")
end

function Treasure.hide()
  available = false
  Debug.log("=== Treasure.hide() 被调用，宝箱已隐藏 ===\n")
end

function Treasure.open(global_stats)
  Debug.log("open_treasure_box() 开始执行\n")
  if not available then
    Debug.log("宝箱未解锁，退出\n")
    return
  end
  
  Debug.log("宝箱已解锁，开始获取随机插件\n")
  dbg_last_clicked = os.time()
  local plugin_name = Treasure.get_random_plugin()
  if not plugin_name then
    Debug.log("宝箱系统：无法获取可用插件\n")
    Debug.print("宝箱系统：无法获取可用插件")
    dbg_last_result = "No candidates"
    return
  end
  
  Debug.logf("获取到插件: %s\n", plugin_name)
  
  local success, track = Treasure.insert_plugin_to_track(plugin_name)
  if success then
    local track_name = "Unknown Track"
    if track then
      local _, name = reaper.GetTrackName(track)
      if name and name ~= "" then
        track_name = name
      end
    end
    
    local opened_plugin = {
      name = plugin_name,
      opened_ts = os.time(),
      inserted_track = track_name
    }
    table.insert(opened_plugins, opened_plugin)
    
    global_stats.treasure_box = global_stats.treasure_box or {}
    global_stats.treasure_box.total_opened = (global_stats.treasure_box.total_opened or 0) + 1
    global_stats.treasure_box.last_opened_ts = os.time()
    global_stats.treasure_box.opened_plugins = global_stats.treasure_box.opened_plugins or {}
    table.insert(global_stats.treasure_box.opened_plugins, opened_plugin)
    
    Debug.print("宝箱系统：成功开箱！插件 " .. plugin_name .. " 已插入到 " .. track_name)
    
    available = false
  end
end

-- ========= Getter函数 =========
function Treasure.is_available()
  return available
end

function Treasure.get_opened_plugins()
  return opened_plugins
end

function Treasure.get_debug_info()
  return {
    candidates = dbg_candidates,
    last_pick = dbg_last_pick,
    last_result = dbg_last_result,
    last_clicked = dbg_last_clicked
  }
end

function Treasure.get_plugin_count()
  return #plugin_list
end

return Treasure

