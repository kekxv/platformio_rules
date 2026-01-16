load("@py_deps//:requirements.bzl", "requirement")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(
    default_visibility = ["//visibility:public"],
)

bzl_library(
    name = "extension_bzl",
    srcs = ["extension.bzl"],
)

bzl_library(
    name = "config_bzl",
    srcs = ["config.bzl"],
)

bzl_library(
    name = "platformio_bzl",
    srcs = ["platformio.bzl"],
    deps = [
        ":config_bzl",
        ":extension_bzl",
    ],
)

py_binary(
    name = "template_renderer",
    srcs = ["template_renderer.py"],
    deps = [
        requirement("jinja2"),
    ]
)

py_binary(
    name = "platformio_runner",
    srcs = ["platformio_wrapper.py"],
    main = "platformio_wrapper.py",
    deps = [
        requirement("platformio"),
    ],
)

filegroup(
    name = "platformio_ini_tmpl",
    srcs = ["platformio.ini.tmpl"],
)

exports_files(["platformio.bzl"])
