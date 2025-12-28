--[[
  REAPER Companion - 金币系统
  负责金币产出、每日上限、数据持久化
--]]

local CoinSystem = {}
local json = require("utils.json")
local Debug = require("utils.debug")
local r = reaper

-- 配置
local DAILY_COIN_LIMIT = 600  -- 每日上限 600 金币
local COINS_PER_MINUTE = 1     -- 每分钟专注获得 1 金币
local INITIAL_COINS = 500      -- 首次启动赠送 500 金币

-- 数据文件路径
local DATA_FILE = nil

-- 内部状态
local state = {
  current_balance = 0,          -- 当前余额
  daily_coins_earned = 0,       -- 今日已获得金币
  last_reset_time = 0,          -- 上次重置时间（Unix 时间戳）
  is_first_run = true,          -- 是否首次运行
}

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
  local normalized_path = normalize_path(path)
  if not normalized_path then 
    Debug.logf("CoinSystem: Invalid path: %s\n", tostring(path))
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
    Debug.logf("CoinSystem: File saved successfully to %s (size: %d bytes)\n", normalized_path, #json_str)
    return true
  else
    Debug.logf("CoinSystem: Failed to open file for writing: %s\n", normalized_path)
    return false
  end
end

-- 获取今天的开始时间（Unix 时间戳，UTC+0）
local function get_today_start()
  local now = os.time()
  -- 转换为本地时间的年月日
  local t = os.date("*t", now)
  -- 构造今天 0:00:00 的时间戳
  t.hour = 0
  t.min = 0
  t.sec = 0
  return os.time(t)
end

-- 检查并重置每日限制
local function check_and_reset_daily()
  local today_start = get_today_start()
  if state.last_reset_time < today_start then
    -- 新的一天，重置每日金币计数
    state.daily_coins_earned = 0
    state.last_reset_time = today_start
    Debug.log("CoinSystem: Daily limit reset\n")
    return true
  end
  return false
end

-- ========= 初始化 =========
function CoinSystem.init(data_file_path)
  DATA_FILE = data_file_path
  if not DATA_FILE then
    local script_path = debug.getinfo(1, "S").source:match("@(.*[\\//])")
    -- script_path 已经是脚本所在目录（如 /path/to/ReaperCompanion/core/）
    -- data 文件夹在项目根目录下，所以应该是 script_path .. "../data/companion_data.json"
    DATA_FILE = script_path .. "../data/companion_data.json"
  end
  
  -- 加载数据
  Debug.logf("CoinSystem: Initializing, DATA_FILE = %s\n", DATA_FILE or "nil")
  local data = load_json_file(DATA_FILE)
  Debug.logf("CoinSystem: Loaded data, has coin_system = %s\n", tostring(data and data.coin_system ~= nil))
  
  if data and data.coin_system then
    -- 如果数据存在，说明不是首次运行
    state.current_balance = data.coin_system.current_balance or 0
    state.daily_coins_earned = data.coin_system.daily_coins_earned or 0
    state.last_reset_time = data.coin_system.last_reset_time or 0
    state.is_first_run = false  -- 数据存在，不是首次运行
    
    -- 检查每日重置
    check_and_reset_daily()
    
    Debug.logf("CoinSystem: Loaded from file (balance: %d, daily: %d)\n", state.current_balance, state.daily_coins_earned)
  else
    -- 首次运行：初始化
    state.current_balance = INITIAL_COINS
    state.daily_coins_earned = 0
    state.last_reset_time = get_today_start()
    state.is_first_run = false
    Debug.log("CoinSystem: First run, initialized with " .. INITIAL_COINS .. " coins\n")
  end
  
  -- 保存初始状态
  Debug.log("CoinSystem: Saving initial state...\n")
  CoinSystem.save()
  Debug.log("CoinSystem: Initial state saved.\n")
end

-- ========= 金币奖励 =========
-- 奖励金币（基于专注时长，单位：分钟）
-- @param focus_minutes 专注时长（分钟）
-- @return success, coins_earned, message
function CoinSystem.reward_focus(focus_minutes)
  -- 检查并重置每日限制
  check_and_reset_daily()
  
  -- 计算应获得的金币（1分钟 = 1金币）
  local coins_to_earn = math.floor(focus_minutes * COINS_PER_MINUTE)
  
  if coins_to_earn <= 0 then
    return false, 0, "No coins earned"
  end
    
  -- 检查每日上限
  local remaining_daily = DAILY_COIN_LIMIT - state.daily_coins_earned
  if remaining_daily <= 0 then
    return false, 0, "Daily limit reached"
  end
  
  -- 应用每日上限
  local actual_coins = math.min(coins_to_earn, remaining_daily)
  
  -- 增加余额和每日计数
  state.current_balance = state.current_balance + actual_coins
  state.daily_coins_earned = state.daily_coins_earned + actual_coins
  
  -- 保存
  CoinSystem.save()
  
  Debug.logf("CoinSystem: Rewarded %d coins (focus: %d min, daily: %d/%d)\n", 
    actual_coins, focus_minutes, state.daily_coins_earned, DAILY_COIN_LIMIT)
  
  return true, actual_coins, string.format("Earned %d coins!", actual_coins)
end

-- ========= 消费金币 =========
-- 消费金币
-- @param amount 消费金额（必须为正数）
-- @return success, remaining_balance
function CoinSystem.spend(amount)
  if amount <= 0 then
    return false, state.current_balance
  end
  
  if state.current_balance < amount then
    return false, state.current_balance
  end
  
  state.current_balance = state.current_balance - amount
  CoinSystem.save()
  
  Debug.logf("CoinSystem: Spent %d coins, remaining: %d\n", amount, state.current_balance)
  
  return true, state.current_balance
end

-- ========= 增加金币（用于返现等）=========
-- 直接增加金币（不经过每日限制）
-- @param amount 增加金额
function CoinSystem.add(amount)
  if amount > 0 then
    state.current_balance = state.current_balance + amount
    CoinSystem.save()
    Debug.logf("CoinSystem: Added %d coins, balance: %d\n", amount, state.current_balance)
  end
end

-- ========= 数据持久化 =========
function CoinSystem.save()
  if not DATA_FILE then 
    Debug.log("CoinSystem: DATA_FILE is nil, cannot save\n")
    return 
  end
  
  -- 加载现有数据（合并，不覆盖）
  local data = load_json_file(DATA_FILE) or {}
  
  -- 更新 coin_system 部分
  data.coin_system = {
    current_balance = state.current_balance,
    daily_coins_earned = state.daily_coins_earned,
    last_reset_time = state.last_reset_time,
    is_first_run = state.is_first_run,
  }
  
  -- 保存（合并后的完整数据）
  save_json_file(DATA_FILE, data)
  Debug.logf("CoinSystem: Data saved to %s (balance: %d, daily: %d)\n", DATA_FILE, state.current_balance, state.daily_coins_earned)
end

-- ========= Getter for data file =========
function CoinSystem.get_data_file()
  return DATA_FILE
end

-- ========= Reset function =========
function CoinSystem.reset()
  state.current_balance = INITIAL_COINS
  state.daily_coins_earned = 0
  state.last_reset_time = get_today_start()
  state.is_first_run = false
  CoinSystem.save()
  Debug.log("CoinSystem: Reset to initial state\n")
end

-- ========= Getter 函数 =========
function CoinSystem.get_balance()
  return state.current_balance
end

function CoinSystem.get_daily_earned()
  check_and_reset_daily()
  return state.daily_coins_earned
end

function CoinSystem.get_daily_remaining()
  check_and_reset_daily()
  return math.max(0, DAILY_COIN_LIMIT - state.daily_coins_earned)
end

function CoinSystem.can_afford(amount)
  return state.current_balance >= amount
end

-- ========= Get state for atomic save =========
function CoinSystem.get_state()
  check_and_reset_daily()
  return {
    current_balance = state.current_balance,
    daily_coins_earned = state.daily_coins_earned,
    last_reset_time = state.last_reset_time,
    is_first_run = state.is_first_run,
  }
end

-- ========= 重置每日限制 =========
function CoinSystem.reset_daily_limit()
  state.daily_coins_earned = 0
  state.last_reset_time = get_today_start()
  CoinSystem.save()
  Debug.log("CoinSystem: Daily limit manually reset\n")
end

return CoinSystem

