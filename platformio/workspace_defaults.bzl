"""Workspace-wide configuration for PlatformIO projects."""

load("//platformio:config.bzl", "platformio_config")

# Global defaults for all PlatformIO projects in this workspace
# Use this by loading it in your BUILD files:
#
#   load("//platformio:workspace_defaults.bzl", "PLATFORMIO_DEFAULTS")
#   
#   platformio_project(
#       name = "my_project",
#       src = "main.cc",
#       defaults = PLATFORMIO_DEFAULTS,
#   )
#
# Or mix defaults with overrides:
#
#   platformio_project(
#       name = "custom_project",
#       src = "main.cc",
#       defaults = PLATFORMIO_DEFAULTS,
#       board = "esp32dev",  # Override the default board
#   )

PLATFORMIO_DEFAULTS = platformio_config(
    board = "megaatmega2560",
    platform = "atmelavr",
    framework = "arduino",
    lib_ldf_mode = "deep+",
)
