# ReaPet v1.0.0 - 用户版本文件清单

> 最后更新：2025-12-24

## 📋 用户版本必需文件清单

这是发布给用户的版本应包含的**最小文件集**。所有文件都是运行 ReaPet 所必需的。

### ✅ 核心文件（必需）

```
ReaPet/
├── zyc_ReaPet.lua              # 主入口文件
├── config.lua                  # 配置文件
├── README.md                    # 用户说明文档
└── .gitignore                  # Git 忽略规则（包含用户数据文件）
```

### ✅ 核心业务逻辑（core/）

```
core/
├── tracker.lua                 # 操作统计和项目管理
├── pomodoro.lua                # 番茄钟状态机
├── pomodoro_presets.lua        # 番茄钟预设
├── treasure.lua                # 宝箱系统逻辑
├── fx_scanner.lua              # VST 插件扫描器
├── coin_system.lua             # 金币系统
└── shop_system.lua             # 商店系统
```

### ✅ 工具库（utils/）

```
utils/
├── json.lua                    # JSON 编码/解码库（rxi）
├── debug.lua                   # 调试工具
├── font_manager.lua            # 字体管理
├── imgui_utils.lua             # ImGui 辅助函数
├── object_pool.lua             # 对象池（性能优化）
└── scale_manager.lua           # 缩放管理
```

### ✅ UI 层（ui/）

```
ui/
├── window.lua                  # 主窗口管理
├── stats_box.lua              # 统计框显示
├── menu_button.lua            # 菜单按钮
├── pomodoro_timer.lua         # 番茄钟计时器 UI
├── treasure_box.lua           # 宝箱 UI
└── transformation_effect.lua   # 变形特效
```

### ✅ 皮肤系统（ui/skins/）

```
ui/skins/
├── skin_manager.lua           # 皮肤管理器
├── cat_base.lua               # 猫咪皮肤（默认）
├── dog_base.lua               # 狗狗皮肤
├── bear_base.lua              # 熊皮肤
├── rabbit_base.lua            # 兔子皮肤
├── chick_base.lua             # 小鸡皮肤
├── koala_base.lua             # 考拉皮肤
├── lion_base.lua              # 狮子皮肤
└── onion_base.lua             # 洋葱皮肤
```

### ✅ UI 工具（ui/utils/）

```
ui/utils/
├── coin_effect.lua            # 金币特效
├── particles.lua             # 粒子系统
├── treasure_chest.lua        # 宝箱渲染
└── debug_treasure.lua         # 调试工具（开发者功能）
```

### ✅ 窗口模块（ui/windows/）

```
ui/windows/
├── settings.lua               # 设置窗口
├── shop.lua                   # 商店窗口
├── pomodoro_settings.lua      # 番茄钟设置窗口
└── dev_panel.lua              # 开发者面板（隐藏，可通过配置启用）
```

### ✅ 资源文件（assets/）

```
assets/
├── README.md                  # 资源说明
└── skins/
    ├── cat_base/              # 猫咪皮肤资源（7个PNG）
    │   ├── cat_base.png
    │   ├── cat_base_desk.png
    │   ├── cat_base_face.png
    │   ├── cat_base_hand_left.png
    │   ├── cat_base_hand_right.png
    │   ├── cat_base_head.png
    │   └── cat_base_rest.png
    │
    ├── dog_base/              # 狗狗皮肤资源（7个PNG）
    ├── bear_base/             # 熊皮肤资源（7个PNG）
    ├── rabbit_base/           # 兔子皮肤资源（7个PNG）
    ├── chick_base/            # 小鸡皮肤资源（7个PNG）
    ├── koala_base/            # 考拉皮肤资源（7个PNG）
    ├── lion_base/             # 狮子皮肤资源（7个PNG）
    ├── onion_base/            # 洋葱皮肤资源（7个PNG）
    └── shop/
        └── blindbox.png       # 商店盲盒图片
```

### 📚 文档文件（可选但推荐）

```
docs/
├── README.md                  # 文档索引
├── API_REFERENCE.md           # API 参考（高级用户）
├── SKIN_CONFIGURATION_GUIDE.md # 皮肤配置指南（开发者）
└── DEVELOPER_MODE_GUIDE.md    # 开发者模式指南（高级用户）
```

---

## ❌ 不应包含的文件

以下文件**不应**出现在用户版本中：

### 旧版本和备份
- ❌ `releases/` - 旧版本脚本
- ❌ `backup/` - 备份文件
- ❌ `scripts/` - 旧脚本目录

### 开发工具
- ❌ `tool/` - 图像处理工具（Python脚本）

### 测试相关
- ❌ `docs/tests/` - 所有测试文档和脚本

### 开发文档（已归档）
- ❌ `docs/archive/` - 所有归档文档
- ❌ `docs/CROSS_PLATFORM_OPTIMIZATION.md`
- ❌ `docs/DATA_PERSISTENCE_LOGIC.md`
- ❌ `docs/FIX_FIELD_COMPLETENESS.md`
- ❌ `docs/MIGRATION_STATUS.md`
- ❌ `docs/OPTIMIZATIONS.md`
- ❌ `docs/PROJECT_PROGRESS_UPDATE.md`
- ❌ `docs/RELEASE_PREPARATION_PLAN.md`
- ❌ `docs/ARCHIVE_PLAN.md`（本文件）

### 用户数据（已在 .gitignore）
- ❌ `data/companion_data.json` - 用户数据文件（运行时自动生成）

### 临时文件
- ❌ `core/rabbit_base.png` - 临时文件（应在 assets/ 中）
- ❌ `tool/rabbit_base.png` - 临时文件

---

## 📊 文件统计

### 必需文件数量
- **Lua 脚本**: ~35 个文件
- **资源文件**: ~60 个 PNG 文件（8个皮肤 × 7个PNG + 1个商店图片）
- **文档文件**: 4-5 个 Markdown 文件（可选）

### 总大小估算
- **代码**: ~50-100 KB
- **资源**: ~5-10 MB（取决于PNG压缩）
- **文档**: ~50-100 KB

---

## ✅ 发布前检查清单

- [ ] 所有必需文件都存在
- [ ] 所有旧版本/备份文件已移除或归档
- [ ] 所有开发工具已移除或归档
- [ ] 所有测试文件已移除或归档
- [ ] 所有开发文档已归档
- [ ] 临时文件已清理
- [ ] README.md 已更新为最新版本
- [ ] .gitignore 已正确配置
- [ ] 应用可以正常运行
- [ ] 所有皮肤资源文件完整
- [ ] 文档已更新（如包含）

---

## 🚀 快速验证

运行以下命令验证文件完整性：

```bash
# 检查核心文件
ls zyc_ReaPet.lua config.lua README.md .gitignore

# 检查核心模块
ls core/*.lua | wc -l  # 应该输出 7

# 检查工具库
ls utils/*.lua | wc -l  # 应该输出 6

# 检查皮肤文件
ls ui/skins/*.lua | wc -l  # 应该输出 9（skin_manager + 8个皮肤）

# 检查资源文件
find assets/skins -name "*.png" | wc -l  # 应该输出 ~57（8个皮肤 × 7 + 1个商店图片）
```

---

## 📝 注意事项

1. **用户数据**: `data/companion_data.json` 不应包含在发布版本中，它会在首次运行时自动创建。

2. **开发者功能**: `dev_panel.lua` 和 `debug_treasure.lua` 保留在代码中，但默认隐藏。高级用户可以通过修改配置文件启用。

3. **文档**: 文档文件是可选的，但强烈建议包含 `README.md` 和 `docs/README.md`，以帮助用户理解如何使用。

4. **资源文件**: 确保所有皮肤的资源文件完整，缺少资源文件会导致皮肤无法正常显示。

