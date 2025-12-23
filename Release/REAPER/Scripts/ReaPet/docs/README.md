# 📚 Reaper Companion - 文档目录

> **最后更新**: 2025年1月

---

## 📖 核心文档

### 项目状态与规划

- **[项目审查报告](PROJECT_REVIEW_2025.md)** - 完整的项目审查、架构说明和上线计划
- **[项目进度更新](PROJECT_PROGRESS_UPDATE.md)** - 最新进度和后续规划
- **[专家建议](EXPERT_RECOMMENDATION.md)** - 下一步行动建议和优先级

### 产品规划

- **[产品规划](ProductPlan.md)** - 完整的产品设计和架构说明

---

## 🔧 技术文档

### API 参考

- **[API 参考](API_REFERENCE.md)** - 完整的模块接口文档

### 数据存储

- **[数据存储逻辑](DATA_STORAGE_LOGIC.md)** - 数据存储机制详解
- **[数据持久化逻辑](DATA_PERSISTENCE_LOGIC.md)** - 数据持久化流程

### 修复文档

- **[数据保存竞态条件修复](FIX_DATA_RACE_CONDITION.md)** - 原子性保存实现
- **[字段完整性修复](FIX_FIELD_COMPLETENESS.md)** - 白名单机制实现

---

## 🧪 测试文档

所有测试相关文档已移至 **[tests/](tests/)** 文件夹：

- [测试指南](tests/TESTING_GUIDE.md) - 测试流程和工具使用
- [全面测试清单](tests/COMPREHENSIVE_TEST_CHECKLIST.md) - 详细测试步骤
- [测试结果](tests/TEST_RESULTS.md) - 测试结果记录
- [原子性保存测试](tests/TEST_ATOMIC_SAVE.md) - 原子性保存测试指南

**测试脚本**:
- `test_data_consistency.lua` - 数据一致性测试
- `test_quick_check.lua` - 快速功能检查
- `test_save_load.lua` - 保存/加载测试

---

## 🚀 开发与发布

### 开发流程

- **[开发工作流程](DEVELOPMENT_WORKFLOW.md)** - 开发流程和规范
- **[发布工作流程](RELEASE_WORKFLOW.md)** - 发布流程和检查清单

### 迁移文档

- **[迁移状态](MIGRATION_STATUS.md)** - 功能迁移状态对比
- **[迁移到 zyc-scripts](MIGRATION_TO_ZYC_SCRIPTS.md)** - 发布迁移指南

---

## 🎨 UI 设计

- **[UI 设计标准](UI_DESIGN_STANDARDS.md)** - UI 设计规范和标准
- **[皮肤配置指南](SKIN_CONFIGURATION_GUIDE.md)** - 皮肤系统配置说明

---

## ⚙️ 优化与配置

- **[代码优化记录](OPTIMIZATIONS.md)** - 已完成的优化和改进
- **[跨平台优化](CROSS_PLATFORM_OPTIMIZATION.md)** - 跨平台兼容性说明

---

## 📁 文档结构

```
docs/
├── README.md                    # 本文档（文档索引）
│
├── 核心文档/
│   ├── PROJECT_REVIEW_2025.md      # 项目审查报告（最新）
│   ├── PROJECT_PROGRESS_UPDATE.md   # 进度更新（最新）
│   ├── EXPERT_RECOMMENDATION.md    # 专家建议
│   └── ProductPlan.md              # 产品规划
│
├── 技术文档/
│   ├── API_REFERENCE.md            # API 参考
│   ├── DATA_STORAGE_LOGIC.md       # 数据存储逻辑
│   ├── DATA_PERSISTENCE_LOGIC.md   # 数据持久化逻辑
│   ├── FIX_DATA_RACE_CONDITION.md  # 修复文档
│   └── FIX_FIELD_COMPLETENESS.md   # 修复文档
│
├── tests/                          # 测试文档和脚本
│   ├── TESTING_GUIDE.md
│   ├── COMPREHENSIVE_TEST_CHECKLIST.md
│   ├── TEST_RESULTS.md
│   ├── TEST_ATOMIC_SAVE.md
│   ├── test_data_consistency.lua
│   ├── test_quick_check.lua
│   └── test_save_load.lua
│
├── 开发与发布/
│   ├── DEVELOPMENT_WORKFLOW.md
│   ├── RELEASE_WORKFLOW.md
│   ├── MIGRATION_STATUS.md
│   └── MIGRATION_TO_ZYC_SCRIPTS.md
│
├── UI 设计/
│   ├── UI_DESIGN_STANDARDS.md
│   └── SKIN_CONFIGURATION_GUIDE.md
│
├── 优化/
│   ├── OPTIMIZATIONS.md
│   └── CROSS_PLATFORM_OPTIMIZATION.md
│
└── archive/                        # 归档文档（过时）
    ├── PROJECT_STATUS.md
    ├── PROJECT_REVIEW.md
    ├── PROJECT_REVIEW_AND_NEXT_STEPS.md
    ├── NEXT_STEPS_PLAN.md
    ├── DEBUG_PROJECT_ACTION.md
    ├── POMODORO_UI_PLAN.md
    ├── POMODORO_UI_INTERFACE.md
    ├── TREASURE_BOX_UI_PLAN.md
    └── STATS_BOX_PLAN.md
```

---

## 🎯 快速导航

### 新手上路
1. 阅读 [README.md](../README.md) 了解项目
2. 查看 [产品规划](ProductPlan.md) 了解功能
3. 阅读 [项目审查报告](PROJECT_REVIEW_2025.md) 了解架构

### 开发者
1. [API 参考](API_REFERENCE.md) - 查看接口
2. [开发工作流程](DEVELOPMENT_WORKFLOW.md) - 开发规范
3. [数据存储逻辑](DATA_STORAGE_LOGIC.md) - 数据机制

### 测试人员
1. [测试指南](tests/TESTING_GUIDE.md) - 测试流程
2. [全面测试清单](tests/COMPREHENSIVE_TEST_CHECKLIST.md) - 测试步骤
3. 运行测试脚本进行验证

### 准备发布
1. [项目进度更新](PROJECT_PROGRESS_UPDATE.md) - 当前状态
2. [发布工作流程](RELEASE_WORKFLOW.md) - 发布步骤
3. [专家建议](EXPERT_RECOMMENDATION.md) - 上线建议

---

## 📝 文档维护

- **最新文档**: `PROJECT_REVIEW_2025.md`, `PROJECT_PROGRESS_UPDATE.md`
- **过时文档**: 已移至 `archive/` 文件夹
- **测试文档**: 已移至 `tests/` 文件夹

---

**文档索引创建时间**: 2025年1月  
**维护者**: 项目团队

