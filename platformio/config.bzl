"""PlatformIO configuration management.

This module provides a clean way to manage PlatformIO configuration globally.

Usage pattern (in workspace root BUILD file):

    load("//platformio:config.bzl", "platformio_config")
    
    # Set global defaults
    _platformio_defaults = platformio_config(
        board = "megaatmega2560",
        platform = "atmelavr",
        framework = "arduino",
    )
    
Then in your individual BUILD files, the platformio_project macro will automatically
use these defaults if not explicitly provided.
"""

# Global storage via top-level variables
# These must be set via load in individual .bzl files
_DEFAULTS = {}

def platformio_config(
    board = None,
    platform = "atmelavr",
    framework = "arduino",
    port = "",
    programmer = "direct",
    lib_ldf_mode = "deep+",
    lib_deps = None,
    build_flags = None,
    environment_kwargs = None,
):
    """Set up global PlatformIO configuration.
    
    Call this function once in your workspace root BUILD or workspace.bzl file.
    
    Example:
        _defaults = platformio_config(
            board = "megaatmega2560",
            platform = "atmelavr",
            framework = "arduino",
        )
    
    Args:
        board: Default board name
        platform: Default platform
        framework: Default framework
        port: Default port
        programmer: Default programmer
        lib_ldf_mode: Default lib_ldf_mode
        lib_deps: Default external libraries
        build_flags: Default build flags
        environment_kwargs: Default environment variables
    
    Returns:
        A dict containing all configuration values
    """
    config = {
        "board": board,
        "platform": platform,
        "framework": framework,
        "port": port,
        "programmer": programmer,
        "lib_ldf_mode": lib_ldf_mode,
        "lib_deps": lib_deps or [],
        "build_flags": build_flags or [],
        "environment_kwargs": environment_kwargs or {},
    }
    return config

def get_platformio_board(defaults = None):
    """Get the configured default board name.
    
    Args:
        defaults: The defaults dict returned from platformio_config()
    
    Returns:
        The board name or None if not configured
    """
    if defaults and "board" in defaults:
        return defaults["board"]
    return None

def get_platformio_platform(defaults = None):
    """Get the configured default platform."""
    if defaults and "platform" in defaults:
        return defaults["platform"]
    return "atmelavr"

def get_platformio_framework(defaults = None):
    """Get the configured default framework."""
    if defaults and "framework" in defaults:
        return defaults["framework"]
    return "arduino"

def get_platformio_port(defaults = None):
    """Get the configured default port."""
    if defaults and "port" in defaults:
        return defaults["port"]
    return ""

def get_platformio_programmer(defaults = None):
    """Get the configured default programmer."""
    if defaults and "programmer" in defaults:
        return defaults["programmer"]
    return "direct"

def get_platformio_lib_ldf_mode(defaults = None):
    """Get the configured default lib_ldf_mode."""
    if defaults and "lib_ldf_mode" in defaults:
        return defaults["lib_ldf_mode"]
    return "deep+"

def get_platformio_lib_deps(defaults = None):
    """Get the configured default lib_deps."""
    if defaults and "lib_deps" in defaults:
        return defaults["lib_deps"]
    return []

def get_platformio_build_flags(defaults = None):
    """Get the configured default build_flags."""
    if defaults and "build_flags" in defaults:
        return defaults["build_flags"]
    return []

def get_platformio_environment_kwargs(defaults = None):
    """Get the configured default environment_kwargs."""
    if defaults and "environment_kwargs" in defaults:
        return defaults["environment_kwargs"]
    return {}

def get_platformio_config(defaults = None, key = None, default_value = None):
    """Get a specific configuration value.
    
    Args:
        defaults: The defaults dict returned from platformio_config()
        key: Configuration key
        default_value: Default value if key not found
    
    Returns:
        Configuration value or default
    """
    if defaults and key in defaults:
        return defaults[key]
    return default_value

