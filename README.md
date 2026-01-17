# PlatformIO Bazel Rules

Bazel Starlark rules for building and uploading [Arduino](https://www.arduino.cc/) programs using the [PlatformIO](http://platformio.org/) build system.

---

## English Version

### Features
*   **Automatic Tool Management**: Uses `rules_python` to automatically manage PlatformIO and `esptool` dependencies. No system-wide PlatformIO installation required.
*   **Modern API**: Supports `srcs` and `hdrs` lists for flexible file management.
*   **Security Support**: Integrated firmware signing and flash encryption via `platformio_key`.
*   **IDE Ready**: Built-in support for CLion with automatic header indexing and `.debug` targets.
*   **Cross-Platform**: Supports macOS, Linux, and Windows.

### Setup - Bzlmod (Recommended)

Add the following to your `MODULE.bazel`:

```python
bazel_dep(name = "platformio_rules", version = "0.0.15") # Use the latest version
```

### Usage Examples

#### 1. Define a Library
```python
load("@platformio_rules//platformio:platformio.bzl", "platformio_library")

platformio_library(
    name = "MyLib",
    srcs = ["MyLib.cc"],
    hdrs = ["MyLib.h"],
    defines = ["ENABLE_FEATURE_X"], # Propagated to dependents
)
```

#### 2. Define a Project with Security & Debugging
```python
load("@platformio_rules//platformio:platformio.bzl", "platformio_project", "platformio_key")

# Define an encryption key
platformio_key(
    name = "my_flash_key",
    key = "encryption_key.bin",
    type = "encryption",
)

platformio_project(
    name = "my_app",
    srcs = ["main.cc"],
    board = "esp32dev",
    platform = "espressif32",
    framework = "arduino",
    deps = [
        ":MyLib",
        ":my_flash_key", # Automatically triggers flash encryption
    ],
    native_deps = [
        "@platformio_rules//:esp32_framework", # For IDE header indexing
    ],
)
```

### Commands
*   **Build**: `bazel build //:my_app`
*   **Upload**: `bazel run //:my_app`
*   **Debug**: `bazel run //:my_app.debug` (Starts PIO Debugger for CLion/GDB)

---

## 中文版 (Chinese Version)

### 功能特性
*   **自动化工具管理**：基于 `rules_python` 自动管理 PlatformIO 和 `esptool` 依赖，无需手动安装系统级的 PlatformIO。
*   **现代 API**：支持 `srcs` 和 `hdrs` 列表，符合 Bazel 原生习惯。
*   **安全构建**：通过 `platformio_key` 规则支持固件签名和 Flash 加密。
*   **IDE 优化**：深度适配 CLion，提供自动索引支持和 `.debug` 调试目标。
*   **跨平台**：完美运行于 macOS, Linux 和 Windows。

### 快速配置 - Bzlmod (推荐)

在您的 `MODULE.bazel` 文件中添加：

```python
bazel_dep(name = "platformio_rules", version = "0.0.15") # 使用最新版本
```

### 使用示例

#### 1. 定义库 (Library)
```python
load("@platformio_rules//platformio:platformio.bzl", "platformio_library")

platformio_library(
    name = "MyLib",
    srcs = ["MyLib.cc"],
    hdrs = ["MyLib.h"],
    defines = ["ENABLE_FEATURE_X"], # 宏定义会自动透传给依赖方
)
```

#### 2. 定义项目 (支持加密与调试)
```python
load("@platformio_rules//platformio:platformio.bzl", "platformio_project", "platformio_key")

# 定义加密密钥
platformio_key(
    name = "my_flash_key",
    key = "encryption_key.bin",
    type = "encryption",
)

platformio_project(
    name = "my_app",
    srcs = ["main.cc"],
    board = "esp32dev",
    platform = "espressif32",
    framework = "arduino",
    deps = [
        ":MyLib",
        ":my_flash_key", # 依赖密钥即自动开启 Flash 加密
    ],
    native_deps = [
        "@platformio_rules//:esp32_framework", # 用于 CLion 头文件索引
    ],
)
```

### 常用命令
*   **构建 (Build)**：`bazel build //:my_app`
*   **上传 (Upload)**：`bazel run //:my_app`
*   **调试 (Debug)**：`bazel run //:my_app.debug` (启动 PIO 调试后端，适配 CLion GDB)

---

## Disclaimer
This is not an official Google product.
非 Google 官方产品。