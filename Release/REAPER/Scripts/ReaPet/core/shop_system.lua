--[[
  REAPER Companion - 商店系统
  负责皮肤购买、盲盒抽取、拥有状态管理
--]]

local ShopSystem = {}
local CoinSystem = require('core.coin_system')
local SkinManager = require('ui.skins.skin_manager')
local json = require("utils.json")
local Debug = require("utils.debug")
local r = reaper

-- 配置
local BLIND_BOX_PRICE = 300      -- 盲盒价格
local DIRECT_BUY_PRICE = 600    -- 直购价格
local DUPLICATE_REFUND = 250     -- 重复皮肤返现金币

-- 数据文件路径
local DATA_FILE = nil

-- 内部状态
local owned_skins = {}  -- 已拥有皮肤 ID 列表

-- ========= 辅助函数 =========
-- 规范化路径（处理 ../ 等相对路径）
local function normalize_path(path)
  if not path then return nil end
  -- 替换多个斜杠为单个斜杠
  path = path:gsub("/+", "/")
  -- 处理 ../ 相对路径（循环处理直到没有 ../）
  local changed = true
  while changed do
    local new_path = path:gsub("[^/]+/%.%./", "")
    changed = (new_path ~= path)
    path = new_path
  end
  -- 移除开头的 ./
  path = path:gsub("^%.%/", "")
  return path
end

local function load_json_file(path)
  -- 规范化路径（处理 ../ 等）
  local normalized_path = normalize_path(path)
  if not normalized_path then return nil end
  
  local file = io.open(normalized_path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(json.decode, content)
    if ok and type(data) == "table" then return data end
  end
  return nil
end

local function save_json_file(path, data)
  -- 规范化路径（处理 ../ 等）
  local normalized_path = normalize_path(path)
  if not normalized_path then 
    Debug.logf("ShopSystem: Invalid path: %s\n", tostring(path))
    return false
  end
  
  -- 确保目录存在
  local dir = normalized_path:match("(.*)/")
  if dir then
    -- 优化：使用 REAPER API 创建目录，避免 Windows 上 os.execute 弹窗和卡顿
    r.RecursiveCreateDirectory(dir, 0)
  end
  
  local file = io.open(normalized_path, "w+")
  if file then
    local json_str = json.encode(data)
    file:write(json_str)
    file:close()
    Debug.logf("ShopSystem: File saved successfully to %s (size: %d bytes)\n", normalized_path, #json_str)
    return true
  else
    Debug.logf("ShopSystem: Failed to open file for writing: %s (check permissions)\n", normalized_path)
    return false
  end
end

-- ========= 辅助函数：跨平台路径连接 =========
local function join_path(...)
  local parts = {...}
  local path = table.concat(parts, "/")
  path = path:gsub("/+", "/")
  return path
end

-- ========= 初始化 =========
function ShopSystem.init(data_file_path)
  DATA_FILE = data_file_path
  if not DATA_FILE then
    -- 后备方案：使用 REAPER 资源目录保存用户数据
    local resource_path = r.GetResourcePath()
    if resource_path then
      -- 确保目录存在（使用跨平台路径连接）
      local data_dir = join_path(resource_path, "Data", "ReaPet")
      r.RecursiveCreateDirectory(data_dir, 0)
      DATA_FILE = join_path(data_dir, "companion_data.json")
    else
      -- 最后的后备方案：使用脚本目录（不推荐）
      local script_path = debug.getinfo(1, "S").source:match("@(.*[\\//])")
      DATA_FILE = script_path .. "../data/companion_data.json"
    end
  end
  
  -- 规范化路径（处理 ../ 等）
  if DATA_FILE then
    DATA_FILE = DATA_FILE:gsub("/+", "/"):gsub("/[^/]+/%.%./", "/"):gsub("/[^/]+/%.%./", "/")
  end
  
  -- 加载已拥有皮肤列表
  Debug.logf("ShopSystem: Initializing, DATA_FILE = %s\n", DATA_FILE or "nil")
  local data = load_json_file(DATA_FILE)
  Debug.logf("ShopSystem: Loaded data, has shop_system = %s\n", tostring(data and data.shop_system ~= nil))
  
  if data and data.shop_system and data.shop_system.owned_skins then
    owned_skins = data.shop_system.owned_skins
    Debug.logf("ShopSystem: Loaded %d owned skins from file: %s\n", #owned_skins, table.concat(owned_skins, ", "))
  else
    -- 默认：原皮（cat_base）已拥有
    owned_skins = {"cat_base"}
    Debug.log("ShopSystem: First run, initialized with default skin\n")
  end
  
  -- 确保原皮始终拥有
  local has_default = false
  for _, id in ipairs(owned_skins) do
    if id == "cat_base" then
      has_default = true
      break
    end
  end
  if not has_default then
    table.insert(owned_skins, "cat_base")
  end
  
  -- 保存初始状态（确保数据被写入文件）
  Debug.log("ShopSystem: Saving initial state...\n")
  ShopSystem.save()
  Debug.log("ShopSystem: Initial state saved.\n")
end

-- ========= 拥有状态管理 =========
function ShopSystem.is_owned(skin_id)
  for _, id in ipairs(owned_skins) do
    if id == skin_id then
      return true
    end
  end
  return false
end

function ShopSystem.get_owned_skins()
  return owned_skins
end

function ShopSystem.own_skin(skin_id)
  if not ShopSystem.is_owned(skin_id) then
    table.insert(owned_skins, skin_id)
    ShopSystem.save()
    Debug.logf("ShopSystem: Owned skin: %s\n", skin_id)
    return true
  end
  return false
end

-- ========= 盲盒抽取 =========
-- 抽取盲盒
-- @return success, result, message
-- result: "new" (新皮肤), "duplicate" (重复), "insufficient" (余额不足)
function ShopSystem.buy_blind_box()
  -- 检查余额
  if not CoinSystem.can_afford(BLIND_BOX_PRICE) then
    return false, "insufficient", "Insufficient coins (need " .. BLIND_BOX_PRICE .. ")"
  end
  
  -- 扣除金币
  local success, remaining = CoinSystem.spend(BLIND_BOX_PRICE)
  if not success then
    return false, "insufficient", "Failed to spend coins"
  end
  
  -- 获取所有皮肤列表
  local all_skins, _ = SkinManager.get_skins()
  if not all_skins or #all_skins == 0 then
    return false, "error", "No skins available"
  end
  
  -- 过滤出未拥有的皮肤
  local unowned_skins = {}
  for _, skin in ipairs(all_skins) do
    if not ShopSystem.is_owned(skin.id) then
      table.insert(unowned_skins, skin)
    end
  end
  
  -- 如果所有皮肤都已拥有，返回特殊状态
  if #unowned_skins == 0 then
    -- 返还金币（因为无法抽取新皮肤）
    CoinSystem.add(BLIND_BOX_PRICE)
    Debug.log("ShopSystem: All skins owned, refunded coins\n")
    return false, "all_owned", "All skins already owned! Coins refunded."
  end
  
  -- 从未拥有的皮肤中随机抽取
  local random_index = math.random(1, #unowned_skins)
  local selected_skin = unowned_skins[random_index]
  
  -- 新皮肤：拥有 (不自动切换，交由 UI 层处理动画和切换)
  ShopSystem.own_skin(selected_skin.id)
  -- SkinManager.set_active_skin(selected_skin.id) -- Removed to allow animation delay
  Debug.logf("ShopSystem: New skin unlocked: %s\n", selected_skin.id)
  return true, selected_skin, string.format("Unlocked: %s!", selected_skin.name)
end

-- ========= 直购 =========
-- 购买指定皮肤
-- @param skin_id 皮肤 ID
-- @return success, message
function ShopSystem.buy_specific_skin(skin_id)
  -- 检查是否已拥有
  if ShopSystem.is_owned(skin_id) then
    return false, "Already owned"
  end
  
  -- 检查余额
  if not CoinSystem.can_afford(DIRECT_BUY_PRICE) then
    return false, string.format("Insufficient coins (need %d)", DIRECT_BUY_PRICE)
  end
  
  -- 扣除金币
  local success, remaining = CoinSystem.spend(DIRECT_BUY_PRICE)
  if not success then
    return false, "Failed to spend coins"
  end
  
  -- 拥有 (不自动切换)
  ShopSystem.own_skin(skin_id)
  -- SkinManager.set_active_skin(skin_id) -- Removed
  
  Debug.logf("ShopSystem: Purchased skin: %s\n", skin_id)
  return true, "Purchase successful!"
end

-- ========= 数据持久化 =========
function ShopSystem.save()
  if not DATA_FILE then 
    Debug.log("ShopSystem: DATA_FILE is nil, cannot save\n")
    return 
  end
  
  -- 加载现有数据（合并，不覆盖）
  local data = load_json_file(DATA_FILE) or {}
  
  -- 更新 shop_system 部分
  data.shop_system = {
    owned_skins = owned_skins,
  }
  
  -- 保存（合并后的完整数据）
  save_json_file(DATA_FILE, data)
  Debug.logf("ShopSystem: Data saved to %s (owned skins: %d)\n", DATA_FILE, #owned_skins)
end

-- ========= Getter 函数 =========
function ShopSystem.get_blind_box_price()
  return BLIND_BOX_PRICE
end

function ShopSystem.get_direct_buy_price()
  return DIRECT_BUY_PRICE
end

-- ========= Getter for data file =========
function ShopSystem.get_data_file()
  return DATA_FILE
end

-- ========= Reset function =========
function ShopSystem.reset()
  owned_skins = {"cat_base"}  -- 只保留默认皮肤
  ShopSystem.save()
  Debug.log("ShopSystem: Reset to initial state\n")
end

-- ========= Get state for atomic save =========
function ShopSystem.get_state()
  return {
    owned_skins = owned_skins,
  }
end

return ShopSystem

