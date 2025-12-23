--[[
  REAPER Companion - 番茄钟模块 (Core Logic)
  负责状态管理、时间追踪与格式化
--]]

local Pomodoro = {}
local Config = require('config')

-- ========= 辅助函数 =========
local function get_precise_time()
  return (reaper and reaper.time_precise) and reaper.time_precise() or os.clock()
end

-- ========= 内部状态 =========
local state = "idle"  -- idle, focus, break
local remaining_time = 0
local is_paused = false
local last_tick_time = 0 
local focus_duration = Config.POMODORO_FOCUS_DURATION or (25 * 60)
local short_break_duration = Config.POMODORO_BREAK_DURATION or (5 * 60)
local long_break_duration = (15 * 60)  -- 默认15分钟
local break_duration = short_break_duration  -- 当前使用的休息时长

-- 自动开始设置（默认开启）
local auto_start_breaks = true
local auto_start_pomodoros = true
local long_break_interval = 4  -- 每4个番茄钟后进行一次长休息
local completed_pomodoros = 0  -- 已完成的番茄钟数量

-- 回调
local on_focus_complete = nil
local on_break_complete = nil
local on_focus_skip = nil  -- 跳过focus时的回调（用于debug）

-- ========= 初始化 =========
function Pomodoro.init()
  state = "idle"
  remaining_time = 0
  is_paused = false
  last_tick_time = get_precise_time()
  completed_pomodoros = 0
  break_duration = short_break_duration
end

-- ========= 控制接口 =========
function Pomodoro.start_focus()
  state = "focus"
  remaining_time = focus_duration
  is_paused = false
  last_tick_time = get_precise_time()
end

function Pomodoro.start_break(is_long)
  state = "break"
  -- 根据间隔决定使用长休息还是短休息
  if is_long == nil then
    -- 自动判断：每 long_break_interval 个番茄钟后使用长休息
    is_long = (completed_pomodoros > 0 and completed_pomodoros % long_break_interval == 0)
  end
  
  if is_long then
    break_duration = long_break_duration
  else
    break_duration = short_break_duration
  end
  
  remaining_time = break_duration
  is_paused = false
  last_tick_time = get_precise_time()
end

function Pomodoro.toggle_pause()
  if state == "idle" then 
    Pomodoro.start_focus()
  else
    is_paused = not is_paused
    if not is_paused then
      last_tick_time = get_precise_time() -- 恢复时重置计时点，防止跳秒
    end
  end
end

function Pomodoro.reset()
  state = "idle"
  remaining_time = 0
  is_paused = false
end

function Pomodoro.skip_phase()
  if state == "focus" then
    -- 增加完成的番茄钟数量（因为跳过了，也算完成）
    completed_pomodoros = completed_pomodoros + 1
    -- 触发跳过回调（用于debug）
    if on_focus_skip then on_focus_skip() end
    -- 根据间隔判断是否应该使用长休息
    local is_long = (completed_pomodoros > 0 and completed_pomodoros % long_break_interval == 0)
    -- 进入休息阶段
    state = "break"
    if is_long then
      break_duration = long_break_duration
    else
      break_duration = short_break_duration
    end
    remaining_time = break_duration
    last_tick_time = get_precise_time()
    -- 根据 auto_start_breaks 决定是否自动开始计时
    if auto_start_breaks then
      is_paused = false  -- 自动开始计时
    else
      is_paused = true   -- 不自动开始，等待用户手动开始
    end
  elseif state == "break" then
    -- 进入 focus 阶段
    state = "focus"
    remaining_time = focus_duration
    last_tick_time = get_precise_time()
    -- 根据 auto_start_pomodoros 决定是否自动开始计时
    if auto_start_pomodoros then
      is_paused = false  -- 自动开始计时
    else
      is_paused = true   -- 不自动开始，等待用户手动开始
    end
  end
end

-- ========= 设置接口 =========
function Pomodoro.set_focus_duration(seconds)
  local old_duration = focus_duration
  focus_duration = seconds
  
  -- 如果当前正在 focus 阶段，根据进度更新剩余时间
  if state == "focus" and old_duration > 0 then
    local progress = 1.0 - (remaining_time / old_duration)  -- 当前进度 (0.0 到 1.0)
    remaining_time = focus_duration * (1.0 - progress)  -- 根据新时长和进度计算新的剩余时间
    -- 确保剩余时间不会超过新时长
    if remaining_time > focus_duration then
      remaining_time = focus_duration
    elseif remaining_time < 0 then
      remaining_time = 0
    end
  end
end

function Pomodoro.set_break_duration(seconds)
  -- 这个函数现在用于设置短休息时长（保持向后兼容）
  local old_duration = short_break_duration
  short_break_duration = seconds
  
  -- 如果当前正在 break 阶段且使用的是短休息，根据进度更新剩余时间
  if state == "break" and break_duration == old_duration and old_duration > 0 then
    local progress = 1.0 - (remaining_time / old_duration)
    remaining_time = short_break_duration * (1.0 - progress)
    if remaining_time > short_break_duration then
      remaining_time = short_break_duration
    elseif remaining_time < 0 then
      remaining_time = 0
    end
    break_duration = short_break_duration
  end
end

function Pomodoro.set_short_break_duration(seconds)
  local old_duration = short_break_duration
  short_break_duration = seconds
  
  -- 如果当前正在 break 阶段且使用的是短休息，根据进度更新剩余时间
  if state == "break" and break_duration == old_duration and old_duration > 0 then
    local progress = 1.0 - (remaining_time / old_duration)
    remaining_time = short_break_duration * (1.0 - progress)
    if remaining_time > short_break_duration then
      remaining_time = short_break_duration
    elseif remaining_time < 0 then
      remaining_time = 0
    end
    break_duration = short_break_duration
  end
end

function Pomodoro.set_long_break_duration(seconds)
  local old_duration = long_break_duration
  long_break_duration = seconds
  
  -- 如果当前正在 break 阶段且使用的是长休息，根据进度更新剩余时间
  if state == "break" and break_duration == old_duration and old_duration > 0 then
    local progress = 1.0 - (remaining_time / old_duration)
    remaining_time = long_break_duration * (1.0 - progress)
    if remaining_time > long_break_duration then
      remaining_time = long_break_duration
    elseif remaining_time < 0 then
      remaining_time = 0
    end
    break_duration = long_break_duration
  end
end

function Pomodoro.set_auto_start_breaks(enabled) auto_start_breaks = enabled end
function Pomodoro.set_auto_start_pomodoros(enabled) auto_start_pomodoros = enabled end
function Pomodoro.set_long_break_interval(interval) long_break_interval = math.max(1, interval) end

function Pomodoro.set_on_focus_complete(cb) on_focus_complete = cb end
function Pomodoro.set_on_break_complete(cb) on_break_complete = cb end
function Pomodoro.set_on_focus_skip(cb) on_focus_skip = cb end

-- ========= Getter 接口 =========
function Pomodoro.get_focus_duration() return focus_duration end
function Pomodoro.get_break_duration() return break_duration end  -- 返回当前使用的休息时长
function Pomodoro.get_short_break_duration() return short_break_duration end
function Pomodoro.get_long_break_duration() return long_break_duration end
function Pomodoro.get_auto_start_breaks() return auto_start_breaks end
function Pomodoro.get_auto_start_pomodoros() return auto_start_pomodoros end
function Pomodoro.get_long_break_interval() return long_break_interval end
function Pomodoro.get_completed_pomodoros() return completed_pomodoros end

-- ========= 核心更新循环 =========
function Pomodoro.update(global_stats)
  if state == "idle" or is_paused then 
    last_tick_time = get_precise_time() -- 暂停时不断更新基准时间
    return 
  end
  
  local now = get_precise_time()
  local delta = now - last_tick_time
  
  if delta >= 0.1 then -- 只有经过足够时间才更新，减少抖动
    remaining_time = remaining_time - delta
    last_tick_time = now
  end
  
  if remaining_time <= 0 then
      -- 阶段完成逻辑
      if state == "focus" then
        -- 记录统计
        if global_stats then
          global_stats.total_focus_sessions = (global_stats.total_focus_sessions or 0) + 1
          global_stats.total_focus_time = (global_stats.total_focus_time or 0) + focus_duration
        end
        -- 增加完成的番茄钟数量
        completed_pomodoros = completed_pomodoros + 1
        -- 触发回调
        if on_focus_complete then on_focus_complete() end
        -- 根据间隔判断是否应该使用长休息
        local is_long = (completed_pomodoros > 0 and completed_pomodoros % long_break_interval == 0)
        -- 进入休息阶段
        state = "break"
        if is_long then
          break_duration = long_break_duration
        else
          break_duration = short_break_duration
        end
        remaining_time = break_duration
        last_tick_time = get_precise_time()
        -- 根据 auto_start_breaks 决定是否自动开始计时
        if auto_start_breaks then
          is_paused = false  -- 自动开始计时
        else
          is_paused = true   -- 不自动开始，等待用户手动开始
        end
      elseif state == "break" then
        -- 触发回调
        if on_break_complete then on_break_complete() end
        -- 进入 focus 阶段
        state = "focus"
        remaining_time = focus_duration
        last_tick_time = get_precise_time()
        -- 根据 auto_start_pomodoros 决定是否自动开始计时
        if auto_start_pomodoros then
          is_paused = false  -- 自动开始计时
        else
          is_paused = true   -- 不自动开始，等待用户手动开始
        end
      end
    end
end

-- ========= Getters & Helpers =========
function Pomodoro.get_state() return state end
function Pomodoro.is_paused() return is_paused end
function Pomodoro.get_remaining_time() return math.max(0, math.floor(remaining_time)) end

function Pomodoro.get_formatted_time()
  if state == "idle" then return "IDLE" end
  local total_sec = math.max(0, math.ceil(remaining_time))
  local m = math.floor(total_sec / 60)
  local s = total_sec % 60
  return string.format("%02d:%02d", m, s)
end

function Pomodoro.get_progress()
  if state == "idle" then return 0 end
  local total = (state == "focus" and focus_duration or break_duration)
  if total <= 0 then return 0 end
  return 1.0 - (remaining_time / total)
end

return Pomodoro