load("@py_deps//:requirements.bzl", "requirement")

package(
    default_visibility = ["//visibility:public"],
)

py_binary(
    name = "template_renderer",
    srcs = ["template_renderer.py"],
    deps = [
        requirement("jinja2"),
    ]
)

py_binary(
    name = "pio_tool",
    srcs = ["pio_wrapper.py"],
    main = "pio_wrapper.py",
    deps = [
        requirement("platformio"),
        requirement("click"),
        requirement("semantic_version"),
        requirement("tabulate"),
        requirement("requests"),
        requirement("pyserial"),
        requirement("esptool"),
        requirement("bitstring"),
        requirement("reedsolo"),
        requirement("cryptography"),
        requirement("intelhex"),
    ],
)

filegroup(
    name = "platformio_ini_tmpl",
    srcs = ["platformio.ini.tmpl"],
)

exports_files(["platformio.bzl"])
