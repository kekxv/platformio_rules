# Migration Guide: Using PlatformIO Defaults

This guide shows how to migrate your existing PlatformIO rules to use the new defaults configuration system.

## What's New?

The `platformio_project` macro now supports a `defaults` parameter that lets you specify default values for `board`, `platform`, `framework`, and other settings once, then reuse them across all projects.

## Migration Steps

### Before (Original Implementation)

In `tests/blink/BUILD`:

```python
load("//platformio:platformio.bzl", "platformio_project")

platformio_project(
    name = "blink",
    src = "blink.cc",
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)
```

In `tests/binary_counter/BUILD`:

```python
load("//platformio:platformio.bzl", "platformio_project")

platformio_project(
    name = "binary_counter",
    src = "binary_counter.cc",
    board = "megaatmega2560",        # Repeated!
    platform = "atmelavr",           # Repeated!
    framework = "arduino",           # Repeated!
)
```

### Step 1: Create Workspace Defaults

Create `platformio/workspace_defaults.bzl`:

```python
load("//platformio:config.bzl", "platformio_config")

PLATFORMIO_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)
```

### Step 2: Update Your BUILD Files

Update each BUILD file to use defaults:

In `tests/blink/BUILD`:

```python
load("//platformio:platformio.bzl", "platformio_project")
load("//platformio:workspace_defaults.bzl", "PLATFORMIO_DEFAULTS")

platformio_project(
    name = "blink",
    src = "blink.cc",
    defaults = PLATFORMIO_DEFAULTS,  # Add this line!
    # Remove: board, platform, framework (they come from defaults)
)
```

In `tests/binary_counter/BUILD`:

```python
load("//platformio:platformio.bzl", "platformio_project")
load("//platformio:workspace_defaults.bzl", "PLATFORMIO_DEFAULTS")

platformio_project(
    name = "binary_counter",
    src = "binary_counter.cc",
    defaults = PLATFORMIO_DEFAULTS,  # Add this line!
    # Remove: board, platform, framework (they come from defaults)
)
```

### Step 3: Override When Needed

If a specific project needs different settings, just override them:

```python
load("//platformio:platformio.bzl", "platformio_project")
load("//platformio:workspace_defaults.bzl", "PLATFORMIO_DEFAULTS")

platformio_project(
    name = "esp32_blink",
    src = "blink.cc",
    defaults = PLATFORMIO_DEFAULTS,
    board = "esp32dev",              # Override just this
    platform = "espressif32",        # Override just this
    # framework still comes from defaults
)
```

## Benefits

| Aspect | Before | After |
|--------|--------|-------|
| **Boilerplate** | Every file repeats `board`, `platform`, `framework` | Defined once in `workspace_defaults.bzl` |
| **Consistency** | Easy to have inconsistent configs | All projects use same defaults |
| **Maintainability** | Changing board requires editing multiple files | Change one file, all projects updated |
| **Flexibility** | All settings the same for all projects | Can override specific settings per-project |
| **Clarity** | Unclear which is the "standard" config | Clear workspace defaults |

## Checking What's Configured

If you're unsure what defaults are being used, check the generated `platformio.ini`:

```bash
# Build your project
bazel build //tests/blink:blink

# Check the generated config
cat bazel-out/k8-fastbuild/bin/tests/blink/blink_workdir/platformio.ini
```

You should see your defaults applied:

```ini
[env:megaatmega2560]
board = megaatmega2560
platform = atmelavr
framework = arduino
lib_ldf_mode = deep+
```

## Backward Compatibility

The old way (specifying all settings explicitly) still works:

```python
platformio_project(
    name = "old_style",
    src = "main.cc",
    board = "megaatmega2560",      # Still works
    platform = "atmelavr",          # Still works
    framework = "arduino",          # Still works
    # No 'defaults' parameter
)
```

You don't have to migrate all projects at once. Mix old and new styles in the same workspace.

## Advanced: Multiple Default Sets

For complex workspaces, you might want multiple default sets:

```python
# platformio/workspace_defaults.bzl
load("//platformio:config.bzl", "platformio_config")

# Arduino defaults (for most projects)
ARDUINO_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)

# ESP32 defaults (for IoT projects)
ESP32_DEFAULTS = platformio_config(
    board = "esp32dev",
    platform = "espressif32",
    framework = "espidf",
)

# Development defaults (with extra debugging)
DEV_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
    build_flags = ["-DDEBUG"],
)
```

Then use the appropriate defaults in each project:

```python
# Standard Arduino project
platformio_project(
    name = "standard",
    src = "main.cc",
    defaults = ARDUINO_DEFAULTS,
)

# ESP32 project
platformio_project(
    name = "iot_device",
    src = "main.cc",
    defaults = ESP32_DEFAULTS,
)

# Development version with debugging
platformio_project(
    name = "blink_debug",
    src = "main.cc",
    defaults = DEV_DEFAULTS,
)
```

## FAQ

**Q: Do I have to use defaults?**  
A: No, they're optional. The old style of specifying all settings explicitly still works.

**Q: Can I use defaults and override everything?**  
A: Yes, but if you're overriding everything, you might not need defaults. They're most useful when projects share most settings.

**Q: What if I forget to pass `defaults` to `platformio_project`?**  
A: It still works, but you'll need to specify `board` explicitly (it's mandatory).

**Q: Can I have project-specific defaults?**  
A: Yes, create additional `.bzl` files with different `platformio_config()` calls and load them as needed.

**Q: How do defaults interact with `platformio_library`?**  
A: Libraries don't use defaults - they don't need board/platform settings. Only `platformio_project` uses defaults.
