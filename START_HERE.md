📍 **START HERE** - PlatformIO Rules 改进开始指南

# 欢迎！👋

您的 platformio_rules 项目已通过全面改进。本文件将帮助您快速上手。

## ⚡ 30 秒快速概览

您的项目现在支持：
1. ✅ **多文件库** - 库可以有多个源文件
2. ✅ **多文件项目** - 项目可以有多个源文件  
3. ✅ **工作区默认值** - 定义一次，使用到处，无需重复

示例：
```python
# 定义一次
PLATFORMIO_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)

# 在每个项目中使用
platformio_project(
    name = "my_project",
    src = "main.cc",
    defaults = PLATFORMIO_DEFAULTS,  # 完成！无需重复 board/platform/framework
)
```

## 🎯 您接下来想做什么？

### 选项 A: 快速开始（5 分钟）
👉 **推荐**: 第一次看这个  
📄 [IMPROVEMENTS_SUMMARY.md](IMPROVEMENTS_SUMMARY.md) - 概览和快速开始

### 选项 B: 查看代码示例
👉 **推荐**: 如果您喜欢通过代码学习  
📄 [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) - 快速参考和示例

### 选项 C: 查看工作示例
👉 **推荐**: 如果您喜欢实践学习  
📁 [tests/with_defaults/](tests/with_defaults/) - 完整的工作示例

### 选项 D: 完整指南
👉 **推荐**: 如果您想深入了解  
📄 [docs/DEFAULTS_GUIDE.md](docs/DEFAULTS_GUIDE.md) - 默认值完整指南

### 选项 E: 从旧方式迁移
👉 **推荐**: 如果您有现有代码  
📄 [docs/MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) - 迁移步骤

## 📋 文件导航地图

```
START HERE
    ↓
    ├─ 快速概览? → IMPROVEMENTS_SUMMARY.md
    ├─ 代码示例? → docs/QUICK_REFERENCE.md
    ├─ 工作示例? → tests/with_defaults/README.md
    ├─ 详细指南? → docs/DEFAULTS_GUIDE.md
    ├─ 迁移指南? → docs/MIGRATION_GUIDE.md
    ├─ 完整技术说明? → docs/COMPLETE_CHANGES.md
    └─ 找文档? → INDEX.md
```

## ✨ 核心改进概览

### 1️⃣ 多文件支持
**问题**: 库和项目只能有一个源文件  
**解决**: 添加了 `srcs` 属性支持多个文件

```python
platformio_library(
    name = "mylib",
    hdr = "mylib.h",
    src = "mylib.cc",
    srcs = ["helper.cc", "utils.cc"],  # 新增！
)
```

### 2️⃣ 工作区默认值
**问题**: 每个项目重复指定 board、platform、framework  
**解决**: 定义一次，使用到处

```python
# 定义一次 (platformio/workspace_defaults.bzl)
PLATFORMIO_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)

# 使用多次 (任何 BUILD 文件)
platformio_project(
    name = "proj",
    src = "main.cc",
    defaults = PLATFORMIO_DEFAULTS,  # 完成！
)
```

### 3️⃣ 完整文档
**新增**: 1000+ 行详细文档和示例

## ✅ 重要信息

- ✅ **向后兼容**: 所有现有代码继续工作
- ✅ **可选**: 新功能是可选的，您可以继续使用旧方式
- ✅ **已验证**: 通过 Bazel 8.5.1 验证
- ✅ **有文档**: 包含快速参考、详细指南、迁移说明
- ✅ **有示例**: 包含工作示例项目

## 🚀 3 步快速开始

### 第 1 步: 了解新功能（2 分钟）
阅读 [IMPROVEMENTS_SUMMARY.md](IMPROVEMENTS_SUMMARY.md) 的快速开始部分

### 第 2 步: 查看示例（3 分钟）
查看 [tests/with_defaults/README.md](tests/with_defaults/README.md) 中的工作示例

### 第 3 步: 在您的项目中使用（5 分钟）
创建 `platformio/workspace_defaults.bzl` 文件：

```python
load("//platformio:config.bzl", "platformio_config")

PLATFORMIO_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)
```

然后在您的 BUILD 文件中：

```python
load("//platformio:platformio.bzl", "platformio_project")
load("//platformio:workspace_defaults.bzl", "PLATFORMIO_DEFAULTS")

platformio_project(
    name = "my_project",
    src = "main.cc",
    defaults = PLATFORMIO_DEFAULTS,
)
```

完成！ 🎉

## ❓ 常见问题

**Q: 我需要立即更改所有代码吗？**  
A: 不需要。所有改进都是向后兼容的。现有代码继续工作。

**Q: 新功能是否成熟可用？**  
A: 是的，已通过 Bazel 8.5.1 完整验证。

**Q: 是否可以混合使用旧新方式？**  
A: 完全可以。您可以在同一工作区使用两种方式。

**Q: 文档是否完整？**  
A: 是的，包含 1000+ 行文档、示例和故障排查。

**Q: 我如何验证我的配置是否正确？**  
A: 构建项目后查看生成的 `platformio.ini` 文件。

## 🔗 相关链接

| 主题 | 文档 | 说明 |
|------|------|------|
| 快速开始 | [IMPROVEMENTS_SUMMARY.md](IMPROVEMENTS_SUMMARY.md) | 5 分钟概览 |
| 快速参考 | [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) | 代码示例 |
| 完整指南 | [docs/DEFAULTS_GUIDE.md](docs/DEFAULTS_GUIDE.md) | 详细说明 |
| 迁移指南 | [docs/MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) | 迁移步骤 |
| 技术说明 | [docs/COMPLETE_CHANGES.md](docs/COMPLETE_CHANGES.md) | 技术细节 |
| 文件清单 | [docs/FILES_CHANGED.md](docs/FILES_CHANGED.md) | 改动清单 |
| 完整索引 | [INDEX.md](INDEX.md) | 所有文档索引 |

## 📚 学习路径

**如果您只有 5 分钟:**  
→ 读 [IMPROVEMENTS_SUMMARY.md](IMPROVEMENTS_SUMMARY.md)

**如果您有 15 分钟:**  
→ 读上面的内容 + [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)

**如果您有 30 分钟:**  
→ 读上面的内容 + [docs/DEFAULTS_GUIDE.md](docs/DEFAULTS_GUIDE.md)

**如果您有一小时:**  
→ 读所有文档并查看所有示例

## 🎯 下一步

现在您已了解概况，选择一个文档开始深入：

1. 📄 [IMPROVEMENTS_SUMMARY.md](IMPROVEMENTS_SUMMARY.md) - 推荐首先阅读
2. 📄 [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) - 查看代码示例
3. 📄 [docs/DEFAULTS_GUIDE.md](docs/DEFAULTS_GUIDE.md) - 了解完整功能
4. 📄 [docs/MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) - 迁移现有代码

---

**准备好了吗？** 👉 [从这里开始](IMPROVEMENTS_SUMMARY.md)

**需要完整索引？** 👉 [查看 INDEX.md](INDEX.md)

**想要快速参考？** 👉 [查看快速参考](docs/QUICK_REFERENCE.md)
