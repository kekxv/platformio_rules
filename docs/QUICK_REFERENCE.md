# PlatformIO Rules - Quick Reference

## Multi-file Library

### Old Way
```python
platformio_library(
    name = "mylib",
    hdr = "mylib.h",
    src = "mylib.cc",
)
```

### New Way (Multiple Files)
```python
platformio_library(
    name = "mylib",
    hdr = "mylib.h",
    src = "mylib.cc",
    srcs = ["helper.cc", "utils.cc"],  # Additional files
    add_hdrs = ["helper.h"],  # Additional headers
)
```

## Multi-file Project

### Old Way
```python
platformio_project(
    name = "proj",
    src = "main.cc",
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)
```

### New Way (Multiple Files)
```python
platformio_project(
    name = "proj",
    src = "main.cc",
    srcs = ["setup.cc", "loop.cc"],  # Additional files
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)
```

## Using Workspace Defaults

### Step 1: Define Defaults
Create `platformio/workspace_defaults.bzl`:
```python
load("//platformio:config.bzl", "platformio_config")

PLATFORMIO_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)
```

### Step 2: Use in Projects
```python
load("//platformio:platformio.bzl", "platformio_project")
load("//platformio:workspace_defaults.bzl", "PLATFORMIO_DEFAULTS")

platformio_project(
    name = "proj",
    src = "main.cc",
    defaults = PLATFORMIO_DEFAULTS,
)
```

### Step 3: Override When Needed
```python
platformio_project(
    name = "esp32_proj",
    src = "main.cc",
    defaults = PLATFORMIO_DEFAULTS,
    board = "esp32dev",
    platform = "espressif32",
)
```

## Configuration Options

```python
PLATFORMIO_DEFAULTS = platformio_config(
    # Required
    board = "megaatmega2560",
    
    # Optional (defaults shown)
    platform = "atmelavr",
    framework = "arduino",
    port = "/dev/ttyACM0",
    programmer = "direct",
    lib_ldf_mode = "deep+",
    lib_deps = ["Wire", "Servo"],
    build_flags = ["-Wall"],
    environment_kwargs = {"board_f_cpu": "16000000L"},
)
```

## Common Boards

| Board | Platform | Framework |
|-------|----------|-----------|
| megaatmega2560 | atmelavr | arduino |
| uno | atmelavr | arduino |
| nano | atmelavr | arduino |
| esp32dev | espressif32 | espidf |
| esp32doit-devkit-v1 | espressif32 | espidf |
| huzzah32 | espressif32 | espidf |

## Common Programmers

- `direct` - Default (bootloader)
- `arduino_as_isp` - Arduino as ISP
- `usbtinyisp` - USBtinyISP
- `avrisp` - AVRisp

## Build Commands

```bash
# Build project
bazel build //path/to:project_target

# Run project (uploads to device)
bazel run //path/to:project_target

# Build and show platformio.ini
bazel build //path/to:project_target
cat bazel-out/k8-fastbuild/bin/path/to/project_target_workdir/platformio.ini

# Build library
bazel build //path/to:library_target
```

## Debugging Configuration

To see what configuration is actually being used:

```bash
# Build your project
bazel build //tests/myproject:mytarget

# Check the generated platformio.ini
cat bazel-out/k8-fastbuild/bin/tests/myproject/mytarget_workdir/platformio.ini
```

## Common Issues

### "board is mandatory"
You forgot to either:
1. Specify `board` explicitly, or
2. Pass `defaults = PLATFORMIO_DEFAULTS`

### "platformio: command not found"
PlatformIO is not installed. Install with:
```bash
pip install platformio
```

### "target 'X' not found"
Check that your target name in the `name` attribute matches what you're building.

## Multiple Default Sets

```python
# In platformio/workspace_defaults.bzl
load("//platformio:config.bzl", "platformio_config")

ARDUINO_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)

ESP32_DEFAULTS = platformio_config(
    board = "esp32dev",
    platform = "espressif32",
    framework = "espidf",
)

DEBUG_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
    build_flags = ["-DDEBUG"],
)
```

Then use the appropriate set:
```python
# Arduino project
platformio_project(name = "proj1", src = "main.cc", defaults = ARDUINO_DEFAULTS)

# ESP32 project
platformio_project(name = "proj2", src = "main.cc", defaults = ESP32_DEFAULTS)

# Debug version
platformio_project(name = "proj3", src = "main.cc", defaults = DEBUG_DEFAULTS)
```

## Backward Compatibility

✅ Old code still works. These don't require any changes:

```python
# Still works!
platformio_project(
    name = "old_style",
    src = "main.cc",
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)

# Still works!
platformio_library(
    name = "old_lib",
    hdr = "lib.h",
    src = "lib.cc",
)
```

## Documentation

- [Defaults Configuration Guide](../docs/DEFAULTS_GUIDE.md) - Comprehensive guide
- [Migration Guide](../docs/MIGRATION_GUIDE.md) - How to migrate to new style
- [Complete Changes](../docs/COMPLETE_CHANGES.md) - All changes summary
- [PlatformIO Documentation](../docs/platformio_doc.md) - Rule details
