# 开发者模式使用指南

> **注意**：这是给开发者使用的指南，普通用户不需要了解。

---

## 🎯 什么是开发者模式？

开发者模式是一组隐藏的调试工具，用于：
- 调试 bug
- 测试功能
- 调整 UI 元素
- 查看性能信息
- 访问开发者面板

**默认状态**：所有开发者功能都是**关闭**的，用户看不到。

---

## 🔧 如何启用开发者模式？

### 方法 1：通过配置文件（推荐）

1. **找到配置文件**
   - 位置：`data/companion_data.json`
   - 如果不存在，运行程序一次会自动创建

2. **编辑配置文件**
   ```json
   {
     "ui_settings": {
       "developer_mode": true,
       "show_debug_info": true,
       "show_performance": true,
       "show_test_buttons": true,
       "show_debug_console": true
     }
   }
   ```

3. **重启程序**
   - 关闭 REAPER
   - 重新打开 REAPER
   - 开发者功能已启用

4. **访问开发者功能**
   - 打开设置窗口（右键点击主窗口）
   - 在 "System" 标签页中会看到开发者选项
   - 可以打开 "Developer Panel"

---

### 方法 2：临时修改代码（快速调试）

1. **编辑 `config.lua`**
   ```lua
   Config.DEVELOPER_MODE = true  -- 临时改为 true
   ```

2. **重启程序**
   - 调试完成后记得改回 `false`

---

### 方法 3：添加隐藏快捷键（可选）

如果需要更方便的方式，可以在设置界面添加隐藏快捷键：

```lua
-- 在 settings.lua 中添加
if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_D()) and 
   r.ImGui_IsKeyDown(ctx, r.ImGui_Key_LeftCtrl()) and 
   r.ImGui_IsKeyDown(ctx, r.ImGui_Key_LeftShift()) then
  Config.DEVELOPER_MODE = not Config.DEVELOPER_MODE
end
```

按住 `Ctrl+Shift+D` 即可切换开发者模式。

---

## 🛠️ 开发者功能列表

### 1. Developer Panel（开发者面板）

**功能**：
- 实时调整 UI 元素位置和大小
- 查看当前状态信息
- 测试功能

**访问**：
- 启用开发者模式后
- 在设置窗口的 "System" 标签页
- 点击 "Open Developer Panel" 按钮

---

### 2. Debug Console（调试控制台）

**功能**：
- 查看程序运行日志
- 查看错误信息
- 跟踪数据流

**启用**：
- 在设置中勾选 "Show Debug Console"
- 或设置 `show_debug_console: true`

---

### 3. Performance Info（性能信息）

**功能**：
- 查看 FPS
- 查看内存使用
- 查看更新耗时

**启用**：
- 设置 `show_performance: true`

---

### 4. Test Buttons（测试按钮）

**功能**：
- 快速测试功能
- 触发特定事件
- 重置数据

**启用**：
- 设置 `show_test_buttons: true`

---

## 🔍 常见调试场景

### 场景 1：调试数据保存问题

```lua
-- 1. 启用开发者模式
Config.DEVELOPER_MODE = true
Config.SHOW_DEBUG_CONSOLE = true

-- 2. 在代码中添加调试输出
Debug.log("Saving data...")
Debug.logf("Project ID: %s", project_id)

-- 3. 查看控制台输出
```

---

### 场景 2：调整 UI 元素位置

```lua
-- 1. 启用开发者模式
Config.DEVELOPER_MODE = true

-- 2. 打开 Developer Panel
-- 3. 使用面板调整元素位置
-- 4. 复制调整后的值到代码中
```

---

### 场景 3：测试新功能

```lua
-- 1. 启用测试按钮
Config.SHOW_TEST_BUTTONS = true

-- 2. 使用测试按钮快速测试
-- 3. 测试完成后关闭
```

---

## ⚠️ 注意事项

1. **不要提交开发者模式开启的状态**
   - 调试完成后，记得关闭开发者模式
   - 检查 `data/companion_data.json` 中 `developer_mode` 是否为 `false`

2. **不要在生产环境启用**
   - 开发者模式会影响性能
   - 可能暴露调试信息

3. **及时关闭**
   - 调试完成后立即关闭
   - 避免影响正常使用

---

## 📝 配置文件位置

**macOS**:
```
~/Library/Application Support/REAPER/ReaPet/data/companion_data.json
```

**Windows**:
```
%APPDATA%\REAPER\ReaPet\data\companion_data.json
```

**Linux**:
```
~/.config/REAPER/ReaPet/data/companion_data.json
```

---

## 🔄 工作流程建议

### 日常开发
1. 在 `develop` 分支开发
2. 开发者模式默认开启（在 `config.lua` 中）
3. 使用所有开发者工具

### 准备发布
1. 确保 `config.lua` 中所有开发者功能默认 `false`
2. 移除设置界面中的开发者模式开关
3. 测试用户视角（开发者模式关闭）

### 发现 Bug（发布后）
1. 启用开发者模式（通过配置文件）
2. 使用开发者工具调试
3. 修复 bug
4. 关闭开发者模式
5. 提交修复

---

## 💡 最佳实践

1. **保留代码，隐藏 UI**
   - 代码中保留所有开发者功能
   - UI 中移除开发者模式开关
   - 通过配置文件启用

2. **文档化**
   - 记录如何启用开发者模式
   - 记录开发者功能的使用方法

3. **版本控制**
   - 不要提交 `developer_mode: true` 的配置
   - 在 `.gitignore` 中忽略用户数据文件

---

**最后更新**：2025-01  
**维护者**：开发团队

