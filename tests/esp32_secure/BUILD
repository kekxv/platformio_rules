load("//platformio:platformio.bzl", "platformio_project", "platformio_key")

platformio_key(
    name = "dummy_encryption_key",
    key = "flash_key.bin",
    type = "encryption",
)

platformio_project(
    name = "secure_blink",
    srcs = ["main.cc"],
    board = "esp32dev",
    framework = "arduino",
    platform = "espressif32",
    deps = [
        ":dummy_encryption_key",
    ],
)
