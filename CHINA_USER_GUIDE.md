# 中国用户安装指南

## 🎯 针对中国用户的完整安装流程

### 第一步：安装 ReaPack（如果还没有）

1. 访问：https://reapack.com/
2. 下载 ReaPack 插件
3. 按照说明安装到 REAPER
4. 重启 REAPER

### 第二步：添加仓库到 ReaPack

1. 打开 REAPER
2. 菜单栏：`扩展` → `ReaPack` → `管理仓库...`
   - 英文界面：`Extensions` → `ReaPack` → `Manage repositories...`

3. 点击 `导入仓库` 或 `Import a repository`

4. **重要**：粘贴以下链接（**推荐中国用户使用**）：

   ```
   https://group.reaget.com/mirrors/YichengZ/zyc-scripts/index.xml
   ```

   > 💡 **为什么用这个链接？**
   > - 这是 REAPER 社区提供的镜像服务，国内访问速度快且稳定
   > - 所有文件都通过镜像下载，无需访问 GitHub

5. 点击 `确定` 或 `OK`

6. 点击 `应用` 或 `Apply`

### 第三步：安装脚本

1. 菜单栏：`扩展` → `ReaPack` → `浏览包...`
   - 英文界面：`Extensions` → `ReaPack` → `Browse packages...`

2. 在搜索框输入：`zyc_ReaPet` 或 `ReaPet`

3. 找到脚本后，点击 `安装` 或 `Install`

4. 等待安装完成

### 第四步：运行脚本

1. 菜单栏：`操作` → `显示操作列表...`
   - 英文界面：`Actions` → `Show action list...`

2. 搜索：`zyc_ReaPet`

3. 双击运行，或者添加到工具栏

---

## 🔧 如果遇到问题

### 问题 1：无法添加仓库

**可能原因**：
- 网络连接问题
- 链接输入错误

**解决方法**：
1. 检查网络连接
2. 确认链接完整：`https://group.reaget.com/mirrors/YichengZ/zyc-scripts/index.xml`
3. 尝试使用其他网络（如手机热点）

### 问题 2：添加仓库成功，但无法下载文件

**可能原因**：
- 网络连接问题
- 镜像服务暂时不可用

**解决方法**：
1. 确认使用的是推荐链接：`https://group.reaget.com/mirrors/YichengZ/zyc-scripts/index.xml`
2. 如果镜像不可用，可以尝试备用链接：
   - GitHub 直接链接：`https://github.com/YichengZ/zyc-scripts/raw/main/index.xml`
   - jsDelivr CDN：`https://cdn.jsdelivr.net/gh/YichengZ/zyc-scripts@main/index.xml`

### 问题 3：下载很慢或失败

**可能原因**：
- 使用了 GitHub 直接链接
- 网络环境限制

**解决方法**：
1. 优先使用推荐镜像：`https://group.reaget.com/mirrors/YichengZ/zyc-scripts/index.xml`
2. 如果还是慢，可以尝试 jsDelivr CDN 作为备用

---

## 📋 完整操作步骤（图文说明）

### 步骤 1：打开 ReaPack 管理界面

```
REAPER 菜单栏
  → 扩展 (Extensions)
    → ReaPack
      → 管理仓库... (Manage repositories...)
```

### 步骤 2：添加仓库

1. 点击 `导入仓库` 或 `Import a repository` 按钮
2. 在弹出的输入框中粘贴：
   ```
   https://group.reaget.com/mirrors/YichengZ/zyc-scripts/index.xml
   ```
3. 点击 `确定` 或 `OK`
4. 点击 `应用` 或 `Apply`

### 步骤 3：浏览和安装

1. 菜单栏：`扩展` → `ReaPack` → `浏览包...`
2. 在搜索框输入：`ReaPet`
3. 找到 `zyc_ReaPet`，点击 `安装`
4. 等待安装完成

### 步骤 4：运行脚本

1. 菜单栏：`操作` → `显示操作列表...`
2. 搜索：`zyc_ReaPet`
3. 双击运行

---

## 🎯 推荐配置

### 最佳实践

1. **使用推荐镜像**（`group.reaget.com`）
   - ✅ 访问最快
   - ✅ 最稳定
   - ✅ 专为中国用户优化

2. **备用方案**（如果镜像不可用）
   - GitHub 直接链接
   - jsDelivr CDN

---

## 📝 常见问题 FAQ

### Q: 为什么推荐使用 `group.reaget.com` 镜像？

**A:** 因为：
- 这是 REAPER 社区提供的镜像服务，专门为国内用户优化
- 访问速度快，稳定性好
- 所有文件都通过镜像下载，无需访问 GitHub

### Q: 可以同时添加多个仓库链接吗？

**A:** 可以，但建议只添加一个（推荐镜像），避免混淆。

### Q: 如何更新脚本？

**A:** 
1. 菜单栏：`扩展` → `ReaPack` → `同步仓库...`
2. 或者：`扩展` → `ReaPack` → `浏览包...` → 找到脚本 → 点击 `更新`

### Q: 安装后找不到脚本？

**A:**
1. 检查是否安装成功（在 ReaPack 浏览包中查看状态）
2. 在操作列表中搜索：`zyc_ReaPet`
3. 确保脚本已启用

---

## 🔗 相关链接

- **推荐镜像**：https://group.reaget.com/mirrors/YichengZ/zyc-scripts/index.xml
- **GitHub 仓库**：https://github.com/YichengZ/zyc-scripts
- **ReaPack 官网**：https://reapack.com/

---

**最后更新：** 2025-01-04

