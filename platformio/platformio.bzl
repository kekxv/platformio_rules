# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

"""PlatformIO Rules.

These are Bazel Starlark rules for building and uploading
[Arduino](https://www.arduino.cc/) programs using the
[PlatformIO](http://platformio.org/) build system.
"""

# Command that makes a directory
_MAKE_DIR_COMMAND = "mkdir -p {dirname}"

# Command that copies the source to the destination.
_COPY_COMMAND = "cp {source} {destination}"

# Command that unzips a zip archive into the specified directory. It will create
# the destination directory if it doesn't exist.
_UNZIP_COMMAND = "mkdir -p {project_dir} && unzip -qq -o -d {project_dir} {zip_filename}"

# Command that executes the PlatformIO build system and builds the project in
# the specified directory.
_BUILD_COMMAND = "platformio run -d {project_dir}"

# Command that executes the PlatformIO build system and uploads the compiled
# firmware to the device.
_UPLOAD_COMMAND = "platformio run -d {project_dir} -t upload"

# Command that executed the PlatformIO system to upload data files to the
# device's FS
_FS_UPLOAD_COMMAND = "platformio run -d {project_dir} -t uploadfs"

# Header used in the shell script that makes platformio_project executable.
# Execution will upload the firmware to the Arduino device.
_SHELL_HEADER = """#!/bin/bash"""

PlatformIOLibraryInfo = provider(
    "Information needed to define a PlatformIO library.",
    fields = {
        "default_runfiles": "Files needed to execute anything depending on this library.",
        "transitive_libdeps": "External platformIO libraries needed by this library.",
    },
)

def _platformio_library_impl(ctx):
    """Collects all transitive dependencies and emits the zip output."""
    name = ctx.label.name
    inputs = []
    outputs = []
    commands = []

    # Use a specific directory for this library to avoid conflicts.
    staging_dir = name + "_staging"

    # Copy all header and source files.
    for target in ctx.attr.hdrs + ctx.attr.srcs:
        for f in target.files.to_list():
            # Use the actual filename from the file object
            filename = f.basename

            # Heuristic: Only rename if it exactly matches the target name (case-insensitive).
            file_basename_only = filename.rsplit(".", 1)[0] if "." in filename else filename
            file_ext = "." + filename.rsplit(".", 1)[1] if "." in filename else ""

            if file_basename_only.lower() == name.lower():
                # Rename to match the exact library name for Arduino compatibility.
                new_ext = file_ext
                if file_ext == ".cc":
                    new_ext = ".cpp"
                filename = name + new_ext

            dest_file = ctx.actions.declare_file(
                "{}/lib/{}/{}".format(staging_dir, name, filename),
            )
            inputs.append(f)
            outputs.append(dest_file)
            # Use cp -f to be safe
            commands.append("mkdir -p {} && cp -f {} {}".format(
                dest_file.dirname,
                f.path,
                dest_file.path,
            ))

    # Zip the entire content of the library folder.
    zip_file = ctx.actions.declare_file("%s.zip" % name)
    outputs.append(zip_file)

    commands.append("cd {}/{} && zip -qq -r ../{} lib/".format(
        zip_file.dirname,
        staging_dir,
        zip_file.basename,
    ))

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = outputs,
        command = "\n".join(commands),
    )

    transitive_zip_files = [
        dep[PlatformIOLibraryInfo].default_runfiles
        for dep in ctx.attr.deps
    ]
    runfiles = ctx.runfiles(files = [zip_file])
    runfiles = runfiles.merge_all(transitive_zip_files)

    # We include the library's own name in transitive_libdeps to ensure
    # PlatformIO LDF finds it when it's unzipped into the project.
    transitive_libdeps = [name]
    transitive_libdeps.extend(ctx.attr.lib_deps)
    for dep in ctx.attr.deps:
        transitive_libdeps.extend(dep[PlatformIOLibraryInfo].transitive_libdeps)

    return [
        PlatformIOLibraryInfo(
            default_runfiles = runfiles,
            transitive_libdeps = transitive_libdeps,
        ),
        DefaultInfo(files = depset([zip_file])),
    ]

def _declare_outputs(ctx):
    """Declares the output files needed by the platformio_project rule.

    Args:
      ctx: The Starlark context.

    Returns:
      List of output files declared by ctx.actions.declare_file().
    """
    dirname = "%s_workdir" % ctx.attr.name
    platformio_ini = ctx.actions.declare_file("%s/platformio.ini" % dirname)
    firmware_elf = ctx.actions.declare_file("%s/.pio/build/%s/firmware.elf" % (dirname, ctx.attr.board))
    return struct(
        platformio_ini = platformio_ini,
        firmware_elf = firmware_elf,
    )

def _emit_ini_file_action(ctx, platformio_ini):
    """Emits a Bazel action that generates the PlatformIO configuration file.

    Args:
      ctx: The Starlark context.
      platformio_ini: Declared output for the platformio.ini file.
    """
    environment_kwargs = []
    if ctx.attr.environment_kwargs:
        environment_kwargs.append("")

    for key, value in ctx.attr.environment_kwargs.items():
        if key == "" or value == "":
            continue
        environment_kwargs.append("{key} = {value}".format(key = key, value = value))

    build_flags = []
    for flag in ctx.attr.build_flags:
        if flag == "":
            continue
        build_flags.append(flag)

    # Collect and deduplicate lib_deps
    lib_deps_map = {}
    for lib in ctx.attr.lib_deps:
        lib_deps_map[lib] = True
    for dep in ctx.attr.deps:
        for lib in dep[PlatformIOLibraryInfo].transitive_libdeps:
            lib_deps_map[lib] = True
    
    lib_deps = lib_deps_map.keys()

    substitutions = json.encode(struct(
        board = ctx.attr.board,
        platform = ctx.attr.platform,
        framework = ctx.attr.framework,
        environment_kwargs = environment_kwargs,
        build_flags = build_flags,
        programmer = ctx.attr.programmer,
        port = ctx.attr.port,
        lib_ldf_mode = ctx.attr.lib_ldf_mode,
        lib_deps = lib_deps,
    ))
    ctx.actions.run(
        outputs = [platformio_ini],
        inputs = [ctx.file._platformio_ini_tmpl],
        executable = ctx.executable._template_renderer,
        arguments = [
            ctx.file._platformio_ini_tmpl.path,
            platformio_ini.path,
            substitutions,
        ],
    )

def _emit_project_files_action(ctx, project_dirname):
    """Emits a Bazel action that outputs the project source and header files.

    Args:
      ctx: The Starlark context.
      project_dirname: The relative directory name for the project workdir.
    """
    commands = []
    inputs = []
    outputs = []

    for target in ctx.attr.srcs:
        for f in target.files.to_list():
            filename = target.label.name
            # Convert .cc to .cpp for PlatformIO compatibility and to avoid 
            # dual-extension issues if lingering files exist.
            if filename.endswith(".cc"):
                filename = filename[:-3] + ".cpp"
            
            dest = ctx.actions.declare_file("%s/src/%s" % (project_dirname, filename))
            inputs.append(f)
            outputs.append(dest)
            commands.append("mkdir -p {} && cp -f {} {}".format(
                dest.dirname,
                f.path,
                dest.path,
            ))

    for target in ctx.attr.hdrs:
        for f in target.files.to_list():
            dest = ctx.actions.declare_file("%s/include/%s" % (project_dirname, target.label.name))
            inputs.append(f)
            outputs.append(dest)
            commands.append("mkdir -p {} && cp -f {} {}".format(
                dest.dirname,
                f.path,
                dest.path,
            ))

    if commands:
        ctx.actions.run_shell(
            inputs = inputs,
            outputs = outputs,
            command = "\n".join(commands),
        )
    return outputs

def _emit_build_action(ctx, project_dir, output_files, project_inputs):
    """Emits a Bazel action that unzips the libraries and builds the project.

    Args:
      ctx: The Starlark context.
      project_dir: A string, the main directory of the PlatformIO project.
        This is where the zip files will be extracted.
      output_files: List of output files declared by ctx.actions.declare_file().
      project_inputs: List of project source/header files.
    """
    transitive_zip_files = depset(
        transitive = [
            dep[PlatformIOLibraryInfo].default_runfiles.files
            for dep in ctx.attr.deps
        ],
    )

    commands = []
    for zip_file in transitive_zip_files.to_list():
        commands.append(_UNZIP_COMMAND.format(
            project_dir = project_dir,
            zip_filename = zip_file.path,
        ))
    commands.append(_BUILD_COMMAND.format(project_dir = project_dir))

    # The PlatformIO build system needs the project configuration file, the main
    # file and all the transitive dependancies.
    inputs = [output_files.platformio_ini] + project_inputs
    for zip_file in transitive_zip_files.to_list():
        inputs.append(zip_file)
    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [output_files.firmware_elf],
        command = "\n".join(commands),
        env = {
            # The PlatformIO binary assumes that the build tools are in the path.
            "PATH": "/bin:/usr/bin:/usr/local/bin:/usr/sbin:/sbin:/opt/homebrew/bin",

            # Changes the Encoding to allow PlatformIO's Click to work as expected
            # See https://github.com/mum4k/platformio_rules/issues/22
            "LC_ALL": "C.UTF-8",
            "LANG": "C.UTF-8",
        },
        execution_requirements = {
            # PlatformIO cannot be executed in a sandbox.
            "local": "1",
        },
    )

def _emit_executable_action(ctx, project_dir):
    """Emits a Bazel action that produces executable script.

    When the script is executed, the compiled firmware gets uploaded to the
    Arduino device.

    Args:
      ctx: The Starlark context.
      project_dir: A string, the main directory of the PlatformIO project.
        This is where the zip files will be extracted.
    """

    # TODO(mum4k): Make this script smarter, when executed via Bazel, the current
    # directory is project_name.runfiles/__main__ so we need to go two dirs up.
    # This however won't work when executed directly.
    transitive_zip_files = depset(
        transitive = [
            dep[PlatformIOLibraryInfo].default_runfiles.files
            for dep in ctx.attr.deps
        ],
    )

    commands = [_SHELL_HEADER]
    for zip_file in transitive_zip_files.to_list():
        commands.append(_UNZIP_COMMAND.format(
            project_dir = project_dir,
            zip_filename = zip_file.short_path,
        ))
    commands.append(_UPLOAD_COMMAND.format(project_dir = project_dir))
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = "\n".join(commands),
        is_executable = True,
    )

def _platformio_project_impl(ctx):
    """Builds and optionally uploads (when executed) a PlatformIO project."""
    output_files = _declare_outputs(ctx)
    project_dirname = "%s_workdir" % ctx.attr.name
    
    _emit_ini_file_action(ctx, output_files.platformio_ini)
    project_inputs = _emit_project_files_action(ctx, project_dirname)

    # Determine the build directory used by Bazel, that is the directory where
    # our output files will be placed.
    project_build_dir = output_files.platformio_ini.dirname
    _emit_build_action(ctx, project_build_dir, output_files, project_inputs)

    # Determine the run directory used by Bazel, that is the directory where our
    # output files will be placed.
    project_run_dir = "./%s" % project_build_dir[len(output_files.platformio_ini.root.path) + 1:]
    _emit_executable_action(ctx, project_run_dir)

    default_info_files = [
        ctx.outputs.executable,
        output_files.platformio_ini,
        output_files.firmware_elf,
    ] + project_inputs + depset(
        transitive = [
            dep[PlatformIOLibraryInfo].default_runfiles.files
            for dep in ctx.attr.deps
        ],
    ).to_list()
    return DefaultInfo(
        default_runfiles = ctx.runfiles(files = default_info_files),
    )

def _emit_upload_fs_ini_file_action(ctx, platformio_ini):
    """Emits a Bazel action that generates the PlatformIO configuration file.

    Args:
      ctx: The Starlark context.
      platformio_ini: Declared output for the platformio.ini file.
    """
    substitutions = json.encode(struct(
        board = ctx.attr.board,
        platform = ctx.attr.platform,
        framework = ctx.attr.framework,
        environment_kwargs = [],
        build_flags = [],
        programmer = ctx.attr.programmer,
        port = ctx.attr.port,
        lib_ldf_mode = "deep+",
        lib_deps = [],
    ))
    ctx.actions.run(
        outputs = [platformio_ini],
        inputs = [ctx.file._platformio_ini_tmpl],
        executable = ctx.executable._template_renderer,
        arguments = [
            ctx.file._platformio_ini_tmpl.path,
            platformio_ini.path,
            substitutions,
        ],
    )

def _emit_upload_fs_copy_action(ctx, fs_dir):
    """Emits a Bazel action that creates the folder with data to upload to the FS

    Args:
      ctx: The Starlark context.
      fs_dir: Directory where the files to be copied to the filesystem are to be
        copied.
    """
    commands = []
    commands.append(
        _MAKE_DIR_COMMAND.format(dirname = fs_dir.path),
    )
    fs_files = depset(transitive = [
        ctx.attr.data[DefaultInfo].default_runfiles.files,
    ]).to_list()
    input_files = []
    for file in fs_files:
        input_files.append(file)
        commands.append(
            _COPY_COMMAND.format(
                source = file.path,
                destination = fs_dir.path,
            ),
        )
    ctx.actions.run_shell(
        outputs = [fs_dir],
        inputs = input_files,
        command = "\n".join(commands),
    )

def _emit_upload_fs_executable_action(ctx, project_dir):
    """Emits a Bazel action that produces executable script.

    When the script is executed, the compiled firmware gets uploaded to the
    Arduino device.

    Args:
      ctx: The Starlark context.
      project_dir: A string, the main directory of the PlatformIO project.
        This is where the zip files will be extracted.
    """
    commands = [_SHELL_HEADER]
    commands.append(_FS_UPLOAD_COMMAND.format(project_dir = project_dir))
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = "\n".join(commands),
        is_executable = True,
    )

def _platformio_fs_impl(ctx):
    dirname = "%s_workdir" % ctx.attr.name
    platformio_ini = ctx.actions.declare_file("%s/platformio.ini" % dirname)
    fs_dir = ctx.actions.declare_directory("%s/data/" % dirname)
    _emit_upload_fs_ini_file_action(ctx, platformio_ini)
    _emit_upload_fs_copy_action(ctx, fs_dir)
    _emit_upload_fs_executable_action(
        ctx,
        "./%s" % platformio_ini.dirname[len(platformio_ini.root.path) + 1:],
    )
    return DefaultInfo(
        default_runfiles = ctx.runfiles(files = [ctx.outputs.executable, platformio_ini, fs_dir]),
    )

# --- START: Renamed original rule to be "private" ---
_platformio_library = rule(
    # --- END: Renamed original rule to be "private" ---
    implementation = _platformio_library_impl,
    attrs = {
        "hdrs": attr.label_list(
            allow_files = [".h", ".hpp"],
            allow_empty = True,
            doc = "A list of labels, header files to include in the resulting zip file.",
        ),
        "srcs": attr.label_list(
            allow_files = [".c", ".cc", ".cpp"],
            allow_empty = True,
            doc = "A list of labels, source files to include in the resulting zip file.",
        ),
        "deps": attr.label_list(
            providers = [DefaultInfo, PlatformIOLibraryInfo],
            doc = """
A list of Bazel targets, other platformio_library targets that this one depends on.
""",
        ),
        "lib_deps": attr.string_list(
            allow_empty = True,
            mandatory = False,
            default = [],
            doc = """
A list of external (PlatformIO) libraries that this library depends on. These
libraries will be added to any platformio_project() rules that directly or
indirectly link this library.
""",
        ),
        "esp32_framework_include_path": attr.string(),
    },
    doc = """
Defines a C++ library that can be imported in an PlatformIO project.

The PlatformIO build system requires a set project directory structure. All
libraries must be under the lib directory.
Outputs a single zip file containing the C++ library in the directory structure
expected by PlatformIO.
""",
)

# --- START: Renamed original rule to be "private" ---
_platformio_project = rule(
    # --- END: Renamed original rule to be "private" ---
    implementation = _platformio_project_impl,
    executable = True,
    attrs = {
        "_platformio_ini_tmpl": attr.label(
            default = Label("//platformio:platformio_ini_tmpl"),
            allow_single_file = True,
        ),
        "_template_renderer": attr.label(
            default = Label("//platformio:template_renderer"),
            executable = True,
            cfg = "exec",
        ),
        "srcs": attr.label_list(
            allow_files = [".c", ".cc", ".cpp"],
            allow_empty = False,
            mandatory = True,
            doc = """
A list of labels, source files for the project.
""",
        ),
        "hdrs": attr.label_list(
            allow_files = [".h", ".hpp"],
            allow_empty = True,
            doc = """
A list of labels, header files for the project.
""",
        ),
        "board": attr.string(
            mandatory = True,
            doc = """
A string, name of the Arduino board to build this project for. You can
find the supported boards in the
[PlatformIO Embedded Boards Explorer](http://platformio.org/boards). This is
mandatory.
""",
        ),
        "port": attr.string(
            doc = """
Port where your microcontroller is connected. This field is mandatory if you
are using arduino_as_isp as your programmer.
""",
        ),
        "platform": attr.string(
            default = "atmelavr",
            doc = """
A string, the name of the
[development platform](
http://docs.platformio.org/en/latest/platforms/index.html#platforms) for
this project.
""",
        ),
        "framework": attr.string(
            default = "arduino",
            doc = """
A string, the name of the
[framework](
http://docs.platformio.org/en/latest/frameworks/index.html#frameworks) for
this project.
""",
        ),
        "environment_kwargs": attr.string_dict(
            allow_empty = True,
            doc = """
A dictionary of strings to strings, any provided keys and
values will directly appear in the generated platformio.ini file under the
env:board section. Refer to the [Project Configuration File manual](
http://docs.platformio.org/en/latest/projectconf.html) for the available
options.
""",
        ),
        "build_flags": attr.string_list(
            allow_empty = True,
            doc = """
A list of strings, any provided strings will directly appear in the
generated platformio.ini file in the build_flags option for the selected
env:board section. Refer to the [Project Configuration File manual](
http://docs.platformio.org/en/latest/projectconf.html) for the available
options.
""",
        ),
        "programmer": attr.string(
            default = "direct",
            values = [
                "arduino_as_isp",
                "direct",
                "usbtinyisp",
            ],
            doc = """
Type of programmer to use:
- direct: Use the USB connection in the microcontroller deveopment board to
program it
- arduino_as_isp: Use an arduino programmed with the Arduino as ISP code to
in-circuit program another microcontroller (see
https://docs.arduino.cc/built-in-examples/arduino-isp/ArduinoISP for details).
- usbtinyisp: Use an USBTinyISP programmer, like
https://www.amazon.com/gp/product/B09DG384MK
""",
        ),
        "deps": attr.label_list(
            providers = [PlatformIOLibraryInfo],
            doc = """
A list of Bazel targets, the platformio_library targets that this one
depends on.
""",
        ),
        "lib_ldf_mode": attr.string(
            default = "deep+",
            mandatory = False,
            doc = """
Library dependency finder for PlatformIO
(https://docs.platformio.org/en/stable/librarymanager/ldf.html).
""",
        ),
        "lib_deps": attr.string_list(
            allow_empty = True,
            mandatory = False,
            default = [],
            doc = """
A list of external (PlatformIO) libraries that this project depends on.
""",
        ),
        # This attribute is only read by the macro, not the rule implementation
        "esp32_framework_include_path": attr.string(),
    },
    doc = """
Defines a project that will be built and uploaded using PlatformIO.

Creates, configures and runs a PlatformIO project.

This rule is executable and when executed, it will upload the compiled firmware
to the connected Arduino device.
""",
)

def _get_clion_label(label):
    """Transforms a platformio_library label to its corresponding hidden cc_library label."""
    if label.startswith(":"):
        return ":__{}_clion".format(label[1:])
    if label.startswith("//") or label.startswith("@"):
        if ":" in label:
            parts = label.rsplit(":", 1)
            return "{}:__{}_clion".format(parts[0], parts[1])
        else:
            # For labels like //path/to which means //path/to:to
            parts = label.rsplit("/", 1)
            return "{}:__{}_clion".format(label, parts[-1])
    return label

# --- START: NEW Macro for platformio_library ---
def platformio_library(name, srcs = [], hdrs = [], deps = [], native_deps = [], esp32_framework_include_path = None, includes = [], **kwargs):
    """A macro that creates a platformio_library and a backing cc_library for IDE support."""

    # Filter kwargs to only pass what the rule expects
    rule_kwargs = {}
    for k, v in kwargs.items():
        if k in ["lib_deps", "visibility", "tags", "testonly"]:
            rule_kwargs[k] = v

    # 1. Create the actual platformio_library target
    _platformio_library(
        name = name,
        srcs = srcs,
        hdrs = hdrs,
        deps = deps,
        **rule_kwargs
    )

    # 2. Create the hidden cc_library for IDE support
    clion_deps_ = [_get_clion_label(d) for d in deps]

    clion_includes = list(includes)  # Create a mutable copy
    if esp32_framework_include_path:
        clion_includes.append(esp32_framework_include_path)

    native.cc_library(
        name = "__{}_clion".format(name),
        srcs = srcs,
        hdrs = hdrs,
        includes = clion_includes,
        deps = clion_deps_ + native_deps,
        tags = ["clion", "manual"],
        visibility = kwargs.get("visibility"),
    )

# --- END: NEW Macro for platformio_library ---

# --- START: NEW Macro for platformio_project ---
def platformio_project(name, srcs = [], hdrs = [], deps = [], native_deps = [], esp32_framework_include_path = None, includes = [], **kwargs):
    """A macro that creates a platformio_project and a backing cc_binary for IDE support."""

    # Filter kwargs to only pass what the rule expects
    rule_kwargs = {}
    for k, v in kwargs.items():
        if k in ["board", "port", "platform", "framework", "environment_kwargs", "build_flags", "programmer", "lib_ldf_mode", "lib_deps", "visibility", "tags", "testonly"]:
            rule_kwargs[k] = v

    # 1. Create the actual platformio_project target
    _platformio_project(
        name = name,
        srcs = srcs,
        hdrs = hdrs,
        deps = deps,
        **rule_kwargs
    )

    # 2. Create the hidden cc_binary for IDE support
    clion_includes = list(includes)  # Create a mutable copy
    if esp32_framework_include_path:
        clion_includes.append(esp32_framework_include_path)

    clion_deps_ = [_get_clion_label(d) for d in deps]

    native.cc_binary(
        name = "__{}_clion".format(name),
        srcs = srcs,
        deps = clion_deps_ + native_deps,
        includes = clion_includes,
        copts = [
            "-DARDUINO_ARCH_ESP32",
            "-DARDUINO=10805",
        ],
        tags = ["clion", "manual"],
        visibility = kwargs.get("visibility"),
    )

# --- END: NEW Macro for platformio_project ---


platformio_fs = rule(
    implementation = _platformio_fs_impl,
    executable = True,
    attrs = {
        "_platformio_ini_tmpl": attr.label(
            default = Label("//platformio:platformio_ini_tmpl"),
            allow_single_file = True,
        ),
        "_template_renderer": attr.label(
            default = Label("//platformio:template_renderer"),
            executable = True,
            cfg = "exec",
        ),
        "board": attr.string(
            mandatory = True,
            doc = """
A string, name of the Arduino board to build this project for. You can
find the supported boards in the
[PlatformIO Embedded Boards Explorer](http://platformio.org/boards). This is
mandatory.
""",
        ),
        "port": attr.string(
            doc = """
Port where your microcontroller is connected. This field is mandatory if you
are using arduino_as_isp as your programmer.
""",
        ),
        "platform": attr.string(
            default = "atmelavr",
            doc = """
A string, the name of the
[development platform](
http://docs.platformio.org/en/latest/platforms/index.html#platforms) for
this project.
""",
        ),
        "framework": attr.string(
            default = "arduino",
            doc = """
A string, the name of the
[framework](
http://docs.platformio.org/en/latest/frameworks/index.html#frameworks) for
this project.
""",
        ),
        "programmer": attr.string(
            default = "direct",
            values = [
                "arduino_as_isp",
                "direct",
                "usbtinyisp",
            ],
            doc = """
Type of programmer to use:
- direct: Use the USB connection in the microcontroller deveopment board to
program it
- arduino_as_isp: Use an arduino programmed with the Arduino as ISP code to
in-circuit program another microcontroller (see
https://docs.arduino.cc/built-in-examples/arduino-isp/ArduinoISP for details).
- usbtinyisp: Use an USBTinyISP programmer, like
https://www.amazon.com/gp/product/B09DG384MK
""",
        ),
        "data": attr.label(
            default = None,
            mandatory = True,
            allow_files = None,
            allow_single_file = None,
            doc = """
Filegroup containing files to upload to the device's FS memory.
""",
        ),
    },
    doc = """
Defines data that will be uploaded to the microcontroller's filesystem using
PlatformIO.

Creates, configures and runs a PlatformIO project. This is equivalent to running:

""",
)
