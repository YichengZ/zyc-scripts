# zyc-scripts 工具脚本

## 索引生成工具

### 方法 1：使用官方 reapack-index（推荐）

**安装**：
```bash
bash scripts/install_reapack_index.sh
```

**使用**：
```bash
bash scripts/use_official_index.sh
```

**手动安装**：
```bash
gem install reapack-index --user-install
export PATH="$HOME/.gem/ruby/$(ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]')/bin:$PATH"
```

**手动使用**：
```bash
cd /Users/zhuyicheng/Documents/GitHub/zyc_scripts
reapack-index --rebuild Release/
```

### 方法 2：使用自定义脚本（快速）

**使用**：
```bash
cd /Users/zhuyicheng/Documents/GitHub/zyc_scripts
ruby scripts/generate_index.rb > Release/index.xml
```

## 工具对比

| 特性 | 官方 reapack-index | 自定义脚本 |
|------|-------------------|-----------|
| 安装 | 需要 gem install | 无需安装 |
| 版本管理 | 自动 | 手动 |
| Git 集成 | 是 | 否 |
| 文件检测 | 自动 | 手动 |
| 推荐场景 | 发布版本 | 快速迭代 |

## 文件说明

- `install_reapack_index.sh` - 安装官方工具
- `use_official_index.sh` - 使用官方工具生成索引
- `generate_index.rb` - 自定义索引生成脚本
- `INSTALL_REAPACK_INDEX.md` - 详细安装指南

## 推荐工作流程

1. **开发阶段**：使用自定义脚本快速生成
2. **发布前**：使用官方工具生成最终索引
3. **验证**：在 REAPER 中测试安装
