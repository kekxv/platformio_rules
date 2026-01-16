# PlatformIO Integration with rules_python

## 概述

platformio_rules 现已通过 Bazel 的 `rules_python` 官方方式集成 PlatformIO，而不是依赖硬编码的绝对路径。这提供了以下优势：

## 主要改进

### ✅ 优势

1. **跨平台兼容性**
   - 不再依赖特定的绝对路径（如 `/usr/local/python/3.12.1/bin/platformio`）
   - 自动适应不同操作系统和 Python 安装位置

2. **规范的依赖管理**
   - PlatformIO 作为 Python 依赖在 `requirements.in` 中声明
   - 通过 Bazel 的 pip 扩展自动管理版本

3. **一致的开发环境**
   - 每个开发者在运行 Bazel 构建时都使用相同的 PlatformIO 版本
   - 无需手动安装 platformio

4. **轻松的环境隔离**
   - 使用 Bazel 提供的 Python 环境
   - 不会与系统 Python 环境冲突

## 实现细节

### 文件更新

#### 1. `requirements.in` - 添加 platformio
```
jinja2==3.1.2
platformio>=6.0.0
```

#### 2. `platformio/BUILD` - 定义 platformio_runner
```starlark
py_binary(
    name = "platformio_runner",
    srcs = ["platformio_wrapper.py"],
    main = "platformio_wrapper.py",
    deps = [
        requirement("platformio"),
    ],
)
```

#### 3. `platformio/platformio_wrapper.py` - 包装脚本
包含用于运行 PlatformIO 的 Python wrapper，确保 `platformio` 模块可用。

#### 4. `platformio/platformio.bzl` - 更新命令
- 将硬编码路径替换为 `{platformio_runner}` 占位符
- 在规则中添加 `_platformio_runner` 属性
- 在 `_emit_build_action` 中注入正确的可执行路径

### 规则属性

```starlark
"_platformio_runner": attr.label(
    default = Label("//platformio:platformio_runner"),
    executable = True,
    cfg = "exec",
    doc = "The PlatformIO runner binary, managed through rules_python.",
),
```

## 使用方式

### 更新 requirements

运行此命令以更新 `requirements_lock.txt`：

```bash
bazel run //:requirements.update
```

这会自动生成包含所有依赖的 locked 版本文件。

### 构建项目

使用完全相同的方式构建项目（无需改动）：

```bash
bazel build //tests/with_defaults:blink_with_defaults
```

### 好处

- ✅ 跨平台工作（Linux, macOS, Windows）
- ✅ 自动版本管理
- ✅ 无需手动安装 platformio
- ✅ 可复现的构建

## 技术实现

### 命令模板化

**之前**:
```starlark
_BUILD_COMMAND = "/usr/local/python/3.12.1/bin/platformio run -d {project_dir}"
```

**之后**:
```starlark
_BUILD_COMMAND = "{platformio_runner} run -d {project_dir}"
```

在 `_emit_build_action` 中：
```starlark
platformio_runner = ctx.executable._platformio_runner.path
commands.append(_BUILD_COMMAND.format(
    project_dir = project_dir,
    platformio_runner = platformio_runner,
))
```

## 故障排查

### 如果遇到 "platformio: command not found"

1. 确保 `platformio` 在 `requirements.in` 中
2. 运行 `bazel run //:requirements.update`
3. 清除缓存：`bazel clean --expunge`
4. 重新构建

### 如果遇到版本问题

1. 编辑 `requirements.in` 更新版本约束
2. 运行 `bazel run //:requirements.update`
3. 重新构建

## 相关文档

- [rules_python 官方文档](https://github.com/bazelbuild/rules_python)
- [PlatformIO 文档](https://docs.platformio.org/)
- [Bazel Python 规则](https://bazel.build/reference/be/python)
