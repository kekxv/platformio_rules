# PlatformIO Defaults Configuration System

## Overview

The platformio_rules now supports a workspace-wide default configuration system to avoid repeating `board`, `platform`, `framework` and other settings in every `platformio_project` target.

## Quick Start

### Step 1: Create Workspace Defaults

Create a file `platformio/workspace_defaults.bzl` in your workspace:

```python
load("//platformio:config.bzl", "platformio_config")

# Define workspace-wide defaults
PLATFORMIO_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
    lib_ldf_mode = "deep+",
    port = "/dev/ttyACM0",
    lib_deps = [
        "Wire",
        "Servo",
    ],
)
```

### Step 2: Use Defaults in Your Projects

In any `BUILD` file:

```python
load("//platformio:platformio.bzl", "platformio_project")
load("//platformio:workspace_defaults.bzl", "PLATFORMIO_DEFAULTS")

platformio_project(
    name = "my_project",
    src = "main.cc",
    defaults = PLATFORMIO_DEFAULTS,
)
```

The project will automatically get:
- board = "megaatmega2560"
- platform = "atmelavr"
- framework = "arduino"
- lib_ldf_mode = "deep+"
- port = "/dev/ttyACM0"
- lib_deps = ["Wire", "Servo"]

### Step 3: Override Specific Settings

You can override any default for a specific project:

```python
platformio_project(
    name = "esp32_project",
    src = "main.cc",
    defaults = PLATFORMIO_DEFAULTS,
    board = "esp32dev",  # Override the default board
    platform = "espressif32",  # Override the default platform
)
```

Only `board` and `platform` are overridden, other settings (framework, port, lib_ldf_mode, etc.) still use the defaults.

## Configuration Options

The `platformio_config()` function supports:

- `board`: Default board name (e.g., "megaatmega2560", "esp32dev")
- `platform`: Platform name (e.g., "atmelavr", "espressif32")
- `framework`: Framework name (e.g., "arduino", "espidf")
- `port`: Upload port (e.g., "/dev/ttyACM0", "COM3")
- `programmer`: Programmer type (e.g., "direct", "arduino_as_isp", "usbtinyisp")
- `lib_ldf_mode`: Library dependency finder mode (e.g., "deep+", "chain+")
- `lib_deps`: List of external libraries (as strings)
- `build_flags`: List of build flags (as strings)
- `environment_kwargs`: Dict of additional environment variables

## Best Practices

1. **Centralized Configuration**: Keep all defaults in `platformio/workspace_defaults.bzl` for easy modification
2. **Override When Needed**: Use explicit parameters to override defaults for special projects
3. **Document Defaults**: Add comments explaining why certain defaults are chosen
4. **Version Control**: Commit `workspace_defaults.bzl` to version control for team consistency

## Example Workspace Layout

```
workspace/
├── BUILD                           # Root BUILD (minimal)
├── platformio/
│   ├── BUILD
│   ├── platformio.bzl             # Core rules
│   ├── config.bzl                 # Configuration functions
│   ├── workspace_defaults.bzl     # Your workspace defaults
│   ├── platformio.ini.tmpl
│   └── template_renderer.py
├── tests/
│   ├── with_defaults/
│   │   ├── BUILD                  # Uses PLATFORMIO_DEFAULTS
│   │   ├── main.cc
│   │   └── README.md
│   └── custom_board/
│       ├── BUILD                  # Overrides board
│       └── main.cc
```

## Comparing With and Without Defaults

### Without Defaults (Old Way)

```python
# Every BUILD file repeats the same settings
load("//platformio:platformio.bzl", "platformio_project")

platformio_project(
    name = "project1",
    src = "main1.cc",
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
    lib_ldf_mode = "deep+",
    port = "/dev/ttyACM0",
)

platformio_project(
    name = "project2",
    src = "main2.cc",
    board = "megaatmega2560",      # Repeated!
    platform = "atmelavr",          # Repeated!
    framework = "arduino",          # Repeated!
    lib_ldf_mode = "deep+",         # Repeated!
    port = "/dev/ttyACM0",          # Repeated!
)
```

### With Defaults (New Way)

```python
# Much cleaner! Defaults are shared
load("//platformio:platformio.bzl", "platformio_project")
load("//platformio:workspace_defaults.bzl", "PLATFORMIO_DEFAULTS")

platformio_project(
    name = "project1",
    src = "main1.cc",
    defaults = PLATFORMIO_DEFAULTS,
)

platformio_project(
    name = "project2",
    src = "main2.cc",
    defaults = PLATFORMIO_DEFAULTS,
)

# When you need different settings:
platformio_project(
    name = "esp32_project",
    src = "main3.cc",
    defaults = PLATFORMIO_DEFAULTS,
    board = "esp32dev",
    platform = "espressif32",
)
```

## Implementation Details

- **No Global State**: The solution doesn't use global state (which isn't supported in Starlark)
- **Dict-Based**: Defaults are passed as a dictionary to each target
- **Load-Time Resolution**: All values are resolved at load time in BUILD files
- **Simple and Transparent**: No complex macros or indirection

## Troubleshooting

### Error: "undefined symbol: PLATFORMIO_DEFAULTS"

Make sure you're loading it:

```python
load("//platformio:workspace_defaults.bzl", "PLATFORMIO_DEFAULTS")
```

### Settings Not Applied

Make sure you're passing the defaults to `platformio_project()`:

```python
platformio_project(
    name = "my_project",
    src = "main.cc",
    defaults = PLATFORMIO_DEFAULTS,  # Don't forget this!
)
```

### Need Different Defaults for Different Teams/Machines?

Create multiple default configurations:

```python
# platformio/workspace_defaults.bzl
load("//platformio:config.bzl", "platformio_config")

# Development machine defaults
DEV_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    port = "/dev/ttyACM0",
    platform = "atmelavr",
    framework = "arduino",
)

# CI/CD defaults (no port needed)
CI_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
)

# Then in your BUILD files:
# - Use DEV_DEFAULTS for local development
# - Use CI_DEFAULTS for CI/CD pipelines
```

## See Also

- [Example Project](../tests/with_defaults/README.md)
- [Core Rules Documentation](platformio_doc.md)
- [platformio.bzl](platformio.bzl) - Rule implementations
- [config.bzl](config.bzl) - Configuration functions
