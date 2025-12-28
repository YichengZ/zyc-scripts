# ReaScript 脚本集成模式与最佳实践

## 📋 概述

当多个 ReaScript 需要相互查找和调用时，有几种常见的实现模式。本文档总结了各种方案的优缺点和适用场景。

## 🎯 核心问题

**问题**：脚本 A 需要找到并调用脚本 B，但：
- 不同用户的安装路径可能不同
- ReaPack 安装路径可能变化
- 命令 ID 可能因版本变化而改变
- 无法在 CI/CD 中自动获取命令 ID

## 🔧 解决方案对比

### 方案 1：相对路径查找（推荐 ⭐⭐⭐⭐⭐）

**适用场景**：脚本在同一仓库/包中，通过 ReaPack 安装

**实现思路**：
```lua
-- 获取当前脚本路径
local current_script_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])')

-- 计算相对路径
local target_script = current_script_path .. "../OtherScript/script.lua"

-- 规范化路径
target_script = target_script:gsub("/+", "/"):gsub("\\+", "\\")

-- 检查并执行
if reaper.file_exists(target_script) then
    local cmd_id = reaper.AddRemoveReaScript(true, 0, target_script, true)
    if cmd_id > 0 then
        reaper.Main_OnCommand(cmd_id, 0)
    end
end
```

**优点**：
- ✅ 最可靠（同一仓库安装，路径关系固定）
- ✅ 不依赖命令 ID
- ✅ 跨平台兼容（自动处理路径分隔符）
- ✅ 版本更新时自动适配

**缺点**：
- ⚠️ 需要知道相对路径关系
- ⚠️ 如果脚本不在同一包中，无法使用

**实际案例**：
- 本项目：StartupActions ↔ ReaPet
- 很多 ReaTeam 脚本包

---

### 方案 2：命令 ID 查找（快速但需维护 ⭐⭐⭐⭐）

**适用场景**：脚本已注册，需要快速调用

**实现思路**：
```lua
-- 方案 2a: 硬编码 ID（最快，但需手动更新）
local SCRIPT_ID = "_RSa83ec3c4ca3001f4f071e3c521bbf360b94d9853"
local cmd_id = reaper.NamedCommandLookup(SCRIPT_ID)
if cmd_id > 0 then
    reaper.Main_OnCommand(cmd_id, 0)
end

-- 方案 2b: 自动查找并缓存（推荐）
local function find_script_by_id(cached_id)
    -- 先尝试缓存 ID
    if cached_id then
        local cmd_id = reaper.NamedCommandLookup(cached_id)
        if cmd_id > 0 then
            return cached_id
        end
    end
    
    -- 如果缓存失效，通过路径查找并获取新 ID
    -- ... (见方案 1)
end
```

**优点**：
- ✅ 最快（直接查找，无需文件系统操作）
- ✅ 如果 ID 存在，性能最好

**缺点**：
- ⚠️ 需要维护缓存 ID（版本更新时可能变化）
- ⚠️ 无法在 CI 中自动获取
- ⚠️ 如果脚本未注册，无法使用

**实际案例**：
- nvk 脚本（使用硬编码 ID）
- 本项目（缓存 ID + 自动查找）

---

### 方案 3：绝对路径查找（后备方案 ⭐⭐⭐）

**适用场景**：相对路径找不到时的后备方案

**实现思路**：
```lua
local resource_path = reaper.GetResourcePath()
local possible_paths = {
    resource_path .. "/Scripts/MyScript/script.lua",
    resource_path .. "/Scripts/script.lua",
}

for _, path in ipairs(possible_paths) do
    if reaper.file_exists(path) then
        local cmd_id = reaper.AddRemoveReaScript(true, 0, path, true)
        if cmd_id > 0 then
            reaper.Main_OnCommand(cmd_id, 0)
            break
        end
    end
end
```

**优点**：
- ✅ 兼容不同安装方式
- ✅ 作为后备方案很可靠

**缺点**：
- ⚠️ 需要知道可能的安装路径
- ⚠️ 性能略差（需要文件系统操作）

---

### 方案 4：通过 Action List 搜索（兜底方案 ⭐⭐）

**适用场景**：完全不知道路径，只能通过名称搜索

**实现思路**：
```lua
-- 搜索包含特定关键词的脚本
local function find_script_by_name(keywords)
    if not reaper.kbd_getTextFromCmd then
        return nil
    end
    
    for i = 32000, 33000 do
        local text = reaper.kbd_getTextFromCmd(i, 0)
        if text then
            local found = true
            for _, keyword in ipairs(keywords) do
                if not text:find(keyword, 1, true) then
                    found = false
                    break
                end
            end
            if found then
                return i  -- 返回命令 ID
            end
        end
    end
    return nil
end
```

**优点**：
- ✅ 不需要知道路径或 ID
- ✅ 完全自动

**缺点**：
- ⚠️ 性能最差（需要遍历大量命令）
- ⚠️ 可能误匹配（名称相似的其他脚本）
- ⚠️ 不适用于生产环境

---

## 🏆 最佳实践：多层查找策略

**推荐方案**：组合使用多种方法，按优先级查找

```lua
local function find_and_run_script(target_script_name)
    local found = false
    
    -- 1. 优先：相对路径（最可靠）
    local current_path = debug.getinfo(1, 'S').source:match('@(.+[/\\])')
    if current_path then
        local relative_path = current_path .. "../" .. target_script_name
        relative_path = relative_path:gsub("/+", "/"):gsub("\\+", "\\")
        
        if reaper.file_exists(relative_path) then
            local cmd_id = reaper.AddRemoveReaScript(true, 0, relative_path, true)
            if cmd_id > 0 then
                reaper.Main_OnCommand(cmd_id, 0)
                found = true
            end
        end
    end
    
    -- 2. 后备：缓存的命令 ID（快速）
    if not found then
        local cached_id = "_RS..."  -- 缓存的 ID
        local cmd_id = reaper.NamedCommandLookup(cached_id)
        if cmd_id > 0 then
            reaper.Main_OnCommand(cmd_id, 0)
            found = true
        end
    end
    
    -- 3. 最后：绝对路径（兼容性）
    if not found then
        local resource_path = reaper.GetResourcePath()
        if resource_path then
            local absolute_path = resource_path .. "/Scripts/" .. target_script_name
            if reaper.file_exists(absolute_path) then
                local cmd_id = reaper.AddRemoveReaScript(true, 0, absolute_path, true)
                if cmd_id > 0 then
                    reaper.Main_OnCommand(cmd_id, 0)
                    found = true
                end
            end
        end
    end
    
    return found
end
```

---

## 📊 方案对比表

| 方案 | 可靠性 | 性能 | 维护成本 | 适用场景 |
|------|--------|------|----------|----------|
| **相对路径** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 同一仓库/包 |
| **命令 ID（缓存）** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 已注册脚本 |
| **命令 ID（自动）** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 动态查找 |
| **绝对路径** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | 后备方案 |
| **Action List 搜索** | ⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ | 兜底方案 |

---

## 🎯 本项目采用的方案

### Startup Actions → ReaPet
1. **缓存命令 ID**（快速，但需手动更新）
2. **相对路径查找**（最可靠，自动适配）
3. **绝对路径查找**（后备方案）

### ReaPet → Startup Actions
1. **相对路径查找**（最可靠）
2. **命令 ID 搜索**（如果已注册）
3. **绝对路径查找**（后备方案）

---

## 💡 其他项目的常见做法

### 1. **nvk 脚本风格**（硬编码 ID）
- 优点：最快
- 缺点：需要手动维护
- 适用：稳定版本，更新频率低

### 2. **ReaTeam 风格**（相对路径）
- 优点：自动适配，无需维护
- 缺点：需要知道路径关系
- 适用：同一包中的脚本

### 3. **混合方案**（本项目）
- 优点：兼顾性能和可靠性
- 缺点：代码稍复杂
- 适用：需要高性能且可靠的项目

---

## 🔍 命令 ID 的特性

### 相同文件 → 相同 ID
- ReaScript 的命令 ID 基于文件内容的哈希
- **相同内容的脚本在所有用户机器上生成相同的 ID**
- 文件内容变化时，ID 会改变

### 无法在 CI 中自动获取
- 需要运行 REAPER 才能获取命令 ID
- GitHub Actions 没有 REAPER 环境
- **无法在 CI/CD 中自动更新**

### 维护建议
1. **版本更新时**：手动运行辅助脚本获取新 ID
2. **或者**：完全依赖自动查找（已有实现）
3. **缓存 ID 是优化**：即使过期，自动查找也能工作

---

## 📝 总结

**最佳实践**：
1. ✅ **优先使用相对路径**（最可靠，自动适配）
2. ✅ **缓存命令 ID 作为优化**（快速，但需手动更新）
3. ✅ **绝对路径作为后备**（兼容性）
4. ✅ **多层查找策略**（兼顾性能和可靠性）

**不推荐**：
- ❌ 完全依赖硬编码 ID（维护成本高）
- ❌ 完全依赖 Action List 搜索（性能差）
- ❌ 单一查找方案（不够健壮）

