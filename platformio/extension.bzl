"""PlatformIO Configuration Provider for global defaults."""

PlatformIOConfig = provider(
    "Configuration for PlatformIO",
    fields = {
        "board": "Default board",
        "platform": "Default platform",
        "framework": "Default framework",
        "port": "Default port",
        "programmer": "Default programmer",
        "lib_ldf_mode": "Default lib_ldf_mode",
        "lib_deps": "Default lib_deps",
        "build_flags": "Default build_flags",
        "environment_kwargs": "Default environment_kwargs",
    },
)

