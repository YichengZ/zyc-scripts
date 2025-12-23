--[[
  REAPER Companion - 通用对象池 (Object Pool)
  职责：复用对象，减少 Lua 垃圾回收 (GC) 压力，提升性能
  
  使用方法：
  local pool = ObjectPool.new(function() return { x=0, y=0 } end)
  local obj = pool:get()
  -- 使用 obj...
  pool:release(obj)
  pool:clear() -- 清理所有对象
--]]

local ObjectPool = {}
ObjectPool.__index = ObjectPool

-- 创建新对象池
-- @param constructor_fn 构造函数，当池为空时调用此函数创建新对象
-- @param initial_size 初始预分配数量（可选）
function ObjectPool.new(constructor_fn, initial_size)
  local self = setmetatable({}, ObjectPool)
  self.pool = {}
  self.constructor = constructor_fn or function() return {} end
  self.count = 0
  
  -- 预分配
  if initial_size and initial_size > 0 then
    for i = 1, initial_size do
      table.insert(self.pool, self.constructor())
    end
    self.count = initial_size
  end
  
  return self
end

-- 获取对象
function ObjectPool:get()
  if self.count > 0 then
    local obj = self.pool[self.count]
    self.pool[self.count] = nil
    self.count = self.count - 1
    return obj
  else
    return self.constructor()
  end
end

-- 回收对象
function ObjectPool:release(obj)
  self.count = self.count + 1
  self.pool[self.count] = obj
end

-- 清空池（通常不需要，除非想释放内存）
function ObjectPool:clear()
  self.pool = {}
  self.count = 0
end

return ObjectPool

