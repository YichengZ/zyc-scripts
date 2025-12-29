# 脚本间调用完整流程指南

## 📋 目标
- ✅ 不重复注册 action（避免 Action List 混乱）
- ✅ 脚本间能互相调用
- ✅ 通过 ReaPack 自动管理注册

## 🎯 方案：使用命名命令 ID（_RS...）

### 核心原理
1. **命名命令 ID 是固定的**：基于脚本内容的 SHA-1 哈希，内容不变 ID 就不变
2. **ReaPack 自动注册**：用户通过 ReaPack 安装时，脚本自动注册到 Action List
3. **硬编码缓存 ID**：在代码中硬编码已知的命名命令 ID，用于脚本间调用

---

## 📝 完整流程

### 第一步：获取脚本的命令 ID

#### 方法 1：在 REAPER 中获取（推荐）
1. 在 REAPER 中运行脚本一次（通过 ReaPack 安装后）
2. 打开 Action List（Actions > Show action list）
3. 搜索脚本名称（如 "Zyc ReaPet"）
4. 右键点击脚本 > "Copy selected action command ID"
5. 你会得到类似 `_RS2bff3c4d5742f41cc75fb9d04fa7c041c2d023d5` 的 ID

#### 方法 2：通过代码获取
```lua
-- 临时脚本：获取当前脚本的命令 ID
local cmd_id = reaper.NamedCommandLookup("_RS...")  -- 如果已知
-- 或者通过 AddRemoveReaScript 注册后获取
local cmd_id = reaper.AddRemoveReaScript(true, 0, script_path, true)
local named_id = reaper.ReverseNamedCommandLookup(cmd_id)
print("Command ID: " .. tostring(named_id))
```

---

### 第二步：在代码中硬编码命令 ID

#### 示例：Startup Actions 调用 ReaPet

在 `zyc_startup_actions.lua` 中：

```lua
-- ReaPet 的命令 ID 缓存
-- ⚠️ 重要：当 ReaPet 版本更新时，需要更新此 ID
-- 获取方法：在 REAPER Action List 中右键 ReaPet > Copy command ID
local REAPET_COMMAND_ID = "_RS2bff3c4d5742f41cc75fb9d04fa7c041c2d023d5"  -- ReaPet v1.0.4.7

-- 查找 ReaPet 的命令 ID（三层查找策略）
local function find_reapet_command_id()
    -- 方案 1：尝试通过文件名查找（最快，如果 REAPER 支持）
    local cmd_id = r.NamedCommandLookup("zyc_ReaPet.lua")
    if cmd_id and cmd_id > 0 then
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
    
    -- 方案 2：使用缓存的命名命令 ID
    if REAPET_COMMAND_ID then
        cmd_id = r.NamedCommandLookup(REAPET_COMMAND_ID)
        if cmd_id and cmd_id > 0 then
            return REAPET_COMMAND_ID
        end
    end
    
    -- 方案 3：搜索已注册的命令（后备方案，避免重复注册）
    if r.kbd_getTextFromCmd then
        for i = 32000, 33000 do
            local text = r.kbd_getTextFromCmd(i, 0)
            if text and (text:find("ReaPet") or text:find("reapet") or text:find("Zyc ReaPet")) then
                local named_id = r.ReverseNamedCommandLookup(i)
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
    
    return nil
end

-- 调用 ReaPet
local function launch_reapet()
    local reapet_id = find_reapet_command_id()
    if reapet_id then
        local cmd_id = r.NamedCommandLookup(reapet_id)
        if cmd_id and cmd_id > 0 then
            r.Main_OnCommand(cmd_id, 0)
            return true
        end
    end
    return false
end
```

#### 示例：ReaPet 调用 Startup Actions

在 `settings.lua` 或 `welcome.lua` 中：

```lua
-- Startup Actions 的命令 ID 缓存
-- ⚠️ 重要：当 Startup Actions 版本更新时，需要更新此 ID
local STARTUP_ACTIONS_COMMAND_ID = "_RS350cc747a0ffd1bb085bea4fadd4f4a09a2549c1"  -- Startup Actions v2.2.2

-- 打开 Startup Actions（三层查找策略）
if r.ImGui_Button(ctx, "Open Startup Actions", 200, 32) then
    local found = false
    
    -- 方案 1：尝试通过文件名查找（最快，如果 REAPER 支持）
    local cmd_id = r.NamedCommandLookup("zyc_startup_actions.lua")
    if cmd_id and cmd_id > 0 then
        r.Main_OnCommand(cmd_id, 0)
        found = true
    end
    
    -- 方案 2：如果文件名查找失败，使用缓存的命名命令 ID
    if not found then
        cmd_id = r.NamedCommandLookup(STARTUP_ACTIONS_COMMAND_ID)
        if cmd_id and cmd_id > 0 then
            r.Main_OnCommand(cmd_id, 0)
            found = true
        end
    end
    
    -- 方案 3：如果缓存也失败，搜索已注册的命令（后备方案）
    if not found and r.kbd_getTextFromCmd then
        for i = 32000, 33000 do
            local text = r.kbd_getTextFromCmd(i, 0)
            if text and (text:find("Startup Actions") or text:find("startup actions") or text:find("Zyc Startup")) then
                r.Main_OnCommand(i, 0)
                found = true
                break
            end
        end
    end
    
    -- 如果都找不到，提示用户安装
    if not found then
        r.ShowMessageBox(
            "Startup Actions not found.\n\nPlease install via ReaPack:\n1. Extensions > ReaPack > Browse packages\n2. Search for 'zyc_startup_actions'\n3. Click Install",
            "Startup Actions Not Found",
            0
        )
    end
end
```

---

### 第三步：确保 ReaPack 元数据正确

#### 在脚本文件头部添加元数据

**zyc_ReaPet.lua:**
```lua
-- @description Zyc ReaPet - Productivity Companion
-- @version 1.0.4.7
-- @author Yicheng Zhu (Ethan)
-- @provides
--   config.lua
--   core/*.lua
--   utils/*.lua
--   ui/**/*.lua
--   assets/**/*.png
```

**zyc_startup_actions.lua:**
```lua
-- @description Zyc Startup Actions Manager
-- @version 2.2.2
-- @author Yicheng Zhu (Ethan)
-- @provides
--   [main] .
--   zyc_startup_actions_run.lua
--   utils/i18n.lua
--   i18n/*.lua
```

---

### 第四步：GitHub 工作流程

#### 1. 开发流程

```bash
# 1. 在 dev 分支开发
git checkout dev

# 2. 修改代码，更新命令 ID 缓存（如果需要）
# 编辑 zyc_startup_actions.lua，更新 REAPET_COMMAND_ID
# 编辑 settings.lua，更新 STARTUP_ACTIONS_COMMAND_ID

# 3. 测试脚本间调用
# 在 REAPER 中测试，确保能互相调用

# 4. 提交到 dev
git add .
git commit -m "feat: update inter-script communication with cached command IDs"
git push origin dev
```

#### 2. 发布到 main 流程

```bash
# 1. 合并 dev 到 main
git checkout main
git merge dev

# 2. 推送到 main（触发 GitHub Actions）
git push origin main
```

#### 3. GitHub Actions 自动流程

当推送到 `main` 分支时，`.github/workflows/reapack-index.yml` 会自动：

1. **检查更改**：检测 `Release/**` 目录的更改
2. **生成 index.xml**：运行 `reapack-index --scan Release --commit`
3. **更新元数据**：根据脚本文件头部的 `@provides`、`@version` 等元数据生成索引
4. **提交并推送**：自动提交 `index.xml` 并推送到 `main` 分支

#### 4. 用户安装流程

1. 用户添加仓库：`https://github.com/YichengZ/zyc-scripts/raw/main/index.xml`
2. ReaPack 读取 `index.xml`，获取所有脚本的元数据
3. 用户安装脚本：ReaPack 自动注册脚本到 Action List
4. 脚本获得命令 ID：REAPER 分配数字 ID（32000-33000），生成命名命令 ID（_RS...）

---

### 第五步：版本更新时的处理

#### 当脚本内容改变时

1. **命令 ID 会改变**：因为命名命令 ID 基于内容哈希
2. **需要更新缓存的 ID**：
   - 在 REAPER 中运行新版本脚本
   - 获取新的命令 ID
   - 更新代码中的缓存 ID

#### 更新流程

```lua
-- 在 zyc_startup_actions.lua 中
-- ReaPet 版本对应的命名命令 ID（缓存）
-- ⚠️ 更新 ReaPet 版本时，需要更新此 ID
-- ReaPet v1.0.4.7: _RS2bff3c4d5742f41cc75fb9d04fa7c041c2d023d5
-- ReaPet v1.0.4.8: _RS新的ID（需要获取）
local REAPET_COMMAND_ID_CACHE = "_RS2bff3c4d5742f41cc75fb9d04fa7c041c2d023d5"
```

---

## ✅ 最佳实践总结

### 1. 脚本间调用（三层查找策略）
- ✅ **方法 1**：尝试通过文件名查找（`r.NamedCommandLookup("script_name.lua")`）
  - 最快，如果 REAPER 支持
  - 如果无效，自动回退到方法 2
- ✅ **方法 2**：使用缓存的命名命令 ID（`_RS...`）
  - 硬编码在代码中，基于脚本内容哈希
  - 版本更新时需要更新缓存
- ✅ **方法 3**：搜索已注册的命令（后备方案）
  - 遍历 32000-33000 范围
  - 通过脚本描述匹配
- ❌ 不使用 `AddRemoveReaScript`（会导致重复注册）
- ❌ 不使用 `dofile`（会触发脚本内部的注册逻辑）

### 2. 版本管理
- ✅ 在代码注释中记录每个版本的命令 ID
- ✅ 版本更新时，更新缓存的命令 ID
- ✅ 在 changelog 中说明命令 ID 的变更

### 3. ReaPack 集成
- ✅ 确保脚本文件头部有正确的 `@provides` 元数据
- ✅ 确保 `@version` 正确
- ✅ 让 GitHub Actions 自动生成 `index.xml`
- ✅ 用户通过 ReaPack 安装，自动注册脚本

### 4. 错误处理
- ✅ 如果找不到命令 ID，提示用户通过 ReaPack 安装
- ✅ 提供友好的错误消息和安装指引

---

## 🔄 完整工作流程示例

### 场景：ReaPet 调用 Startup Actions

1. **开发阶段**（dev 分支）
   ```lua
   -- settings.lua
   local STARTUP_ACTIONS_ID = "_RS350cc747a0ffd1bb085bea4fadd4f4a09a2549c1"
   
   if r.ImGui_Button(ctx, "Open Startup Actions") then
       local cmd_id = r.NamedCommandLookup(STARTUP_ACTIONS_ID)
       if cmd_id and cmd_id > 0 then
           r.Main_OnCommand(cmd_id, 0)
       else
           -- 后备方案：搜索
           for i = 32000, 33000 do
               local text = r.kbd_getTextFromCmd(i, 0)
               if text and text:find("Startup Actions") then
                   r.Main_OnCommand(i, 0)
                   break
               end
           end
       end
   end
   ```

2. **测试**
   - 在 REAPER 中测试，确保能正常调用
   - 检查 Action List，确认没有重复注册

3. **提交到 dev**
   ```bash
   git add .
   git commit -m "feat: add startup actions launcher with cached command ID"
   git push origin dev
   ```

4. **合并到 main**
   ```bash
   git checkout main
   git merge dev
   git push origin main
   ```

5. **GitHub Actions 自动执行**
   - 检测到 `Release/**` 更改
   - 运行 `reapack-index --scan Release --commit`
   - 生成/更新 `index.xml`
   - 自动提交并推送

6. **用户安装**
   - 用户通过 ReaPack 安装脚本
   - ReaPack 自动注册脚本到 Action List
   - 脚本获得命令 ID
   - 脚本间可以正常调用

---

## 📚 参考

- REAPER 命令 ID 系统：32000-33000 是 ReaScript 的固定范围
- 命名命令 ID：基于内容哈希，内容不变 ID 就不变
- ReaPack 元数据：`@provides`、`@version` 等用于生成索引

