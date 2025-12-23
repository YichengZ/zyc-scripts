# Assets 资源结构约定

> 所有图片 / 贴图资源都放在 `assets/` 目录下，按用途和皮肤拆分子文件夹，方便管理与未来扩展。

## 目录结构

```text
assets/
  skins/                  # 角色皮肤相关图片
    cat_base/             # Cat Base PNG 皮肤
      desk.png            # 桌面
      head.png            # 头部
      face.png            # 表情 / 五官叠加层
      hand_left.png       # 左手（含透明背景）
      hand_right.png      # 右手（含透明背景）
      cat_base.png        # 可选：整张合成图，作为兼容 fallback

  ui/                     # 通用 UI 图标、背景（预留）
    icons/
      settings.png
      play.png
      pause.png
    backgrounds/
      dashboard_bg.png
```

## 路径约定

- 工程根目录为 `ReaPet`，`zyc_ReaPet.lua` 位于根目录。
- 皮肤模块位于 `ui/skins/`，加载图片时通过脚本路径回到根目录，再进入 `assets`：

```lua
-- 以 cat_base.lua 为例：
-- script_path 类似 ".../ui/skins/"
local root = script_path:gsub("[/\\]ui[/\\]skins[/\\]$", "")
local path = root .. "assets/skins/cat_base/cat_base_desk.png"
```

## Cat Base PNG 图层规范

- **画布尺寸**：推荐正方形（1024×1024 或 2048×2048，需与 `base_w/base_h` 一致）
- **每个图层独立 PNG**，并使用完全相同的画布尺寸及对齐方式，元素以透明背景居中绘制：
  - `body.png`：角色身体及基础背景（不含头、表情、双手）
  - `table.png`：桌面区域（可选；若 `body` 已包含，可留空）
  - `head.png`：头部轮廓，用于点头动画
  - `face.png`：表情/五官叠加层，用于跟随鼠标的表情偏移
  - `hand_left.png` / `hand_right.png`：左右手/爪子图层，手部静止位置需与矢量版一致
- **动态要求**：
  - 头部与表情会在脚本中加入上下轻微摆动及表情追随，请确保 PNG 留有足够透明空间，以免移动时被裁切。
  - 双手将根据点击/操作动画抬起，PNG 中的手需要在静止坐标上（与 BongoCat 矢量版本一致）。
- **兼容旧资源**：
  - 若只提供 `cat_base.png`，脚本会自动退回到整张图的渲染方式，但不会有独立的表情/手部动画。

- **新增 PNG 皮肤时的建议**
  1. 在 `assets/skins/` 下创建新子目录，例如 `my_cat_png/`。
  2. 按上述图层规范放置图片（body/head/face/hand_left/hand_right 等）。
  3. 在 `ui/skins/` 下新增对应的 Lua 模块，并在 `ui/skins/skin_manager.lua` 中注册：
     - `id`：皮肤 ID
     - `name`：在 Dashboard 中展示的名称
     - `module`：Lua 模块路径（如 `ui.skins.my_cat_png`）
     - `accent`：皮肤在皮肤选择器中使用的点缀颜色（可选）


