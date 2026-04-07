# Copyright 2022 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""A repository rule for integrating the Android NDK."""

DEFAULT_API_LEVEL = 31

_EXEC_CONSTRAINTS = {
    "darwin-arm64": [
        "@platforms//os:macos",
        "@platforms//cpu:aarch64",
    ],
    "darwin-x86_64": [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
    ],
    "linux-x86_64": [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    "windows-x86_64": [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
}

def _get_clang_resource_dir(ctx, clang_directory, is_windows):
    clang_resource_dir = getattr(ctx.attr, "clang_resource_dir", None)
    if clang_resource_dir:
        return clang_resource_dir

    result = ctx.execute([clang_directory + "/bin/clang", "--print-resource-dir"])
    if result.return_code != 0:
        fail("Failed to execute clang: %s" % result.stderr)
    stdout = result.stdout.strip()
    if is_windows:
        stdout = stdout.replace("\\", "/")
    return stdout.split(clang_directory)[1].strip("/")

def _android_ndk_repository_common(ctx, ndk_path):
    """Install the Android NDK files.

    Args:
        ctx: An implementation context.
        ndk_path: The path to the ndk

    Returns:
        A final dict of configuration attributes and values.
    """
    is_windows = False
    executable_extension = ""
    exec_compatible_with = None
    platform = ctx.os.name
    if hasattr(ctx.attr, "platform"):
        platform = ctx.attr.platform
        exec_compatible_with = _EXEC_CONSTRAINTS[platform]

    if platform.startswith("linux"):
        clang_directory = "toolchains/llvm/prebuilt/linux-x86_64"
    elif platform.startswith(("mac", "darwin")):
        # Note: darwin-x86_64 does indeed contain fat binaries with arm64 slices, too.
        clang_directory = "toolchains/llvm/prebuilt/darwin-x86_64"
    elif platform.startswith("windows"):
        clang_directory = "toolchains/llvm/prebuilt/windows-x86_64"
        is_windows = True
        executable_extension = ".exe"
    else:
        fail("Unsupported operating system: " + ctx.os.name)

    sysroot_directory = "%s/sysroot" % clang_directory

    _create_symlinks(ctx, ndk_path, clang_directory, sysroot_directory)

    api_level = ctx.attr.api_level or DEFAULT_API_LEVEL

    clang_resource_directory = _get_clang_resource_dir(ctx, clang_directory, is_windows)

    # Use a label relative to the workspace from which this repository rule came
    # to get the workspace name.
    repository_name = ctx.attr._build.workspace_name

    ctx.template(
        "BUILD.bazel",
        ctx.attr._template_ndk_root,
        {
            "{clang_directory}": clang_directory,
            "{exec_compatible_with}": repr(exec_compatible_with),
        },
        executable = False,
    )

    ctx.template(
        "target_systems.bzl",
        ctx.attr._template_target_systems,
        {
        },
        executable = False,
    )

    ctx.template(
        "%s/BUILD.bazel" % clang_directory,
        ctx.attr._template_ndk_clang,
        {
            "{api_level}": str(api_level),
            "{clang_resource_directory}": clang_resource_directory,
            "{executable_extension}": executable_extension,
            "{repository_name}": repository_name,
            "{sysroot_directory}": sysroot_directory,
        },
        executable = False,
    )

    ctx.template(
        "%s/BUILD.bazel" % sysroot_directory,
        ctx.attr._template_ndk_sysroot,
        {
            "{api_level}": str(api_level),
        },
        executable = False,
    )

# Manually create a partial symlink tree of the NDK to avoid creating BUILD
# files in the real NDK directory.
def _create_symlinks(ctx, ndk_path, clang_directory, sysroot_directory):
    # Path needs to end in "/" for replace() below to work
    if not ndk_path.endswith("/"):
        ndk_path = ndk_path + "/"

    for p in ctx.path(ndk_path + clang_directory).readdir():
        repo_relative_path = str(p).replace(ndk_path, "")

        # Skip sysroot directory, since it gets its own BUILD file
        if repo_relative_path != sysroot_directory:
            ctx.symlink(p, repo_relative_path)

    for p in ctx.path(ndk_path + sysroot_directory).readdir():
        repo_relative_path = str(p).replace(ndk_path, "")
        ctx.symlink(p, repo_relative_path)

    ctx.symlink(ndk_path + "sources", "sources")

    # TODO(#32): Remove this hack
    ctx.symlink(ndk_path + "sources", "ndk/sources")

_COMMON_ATTR = {
    "api_level": attr.int(
        doc = "The minimum Android API level to target.",
        default = DEFAULT_API_LEVEL,
    ),
    "_build": attr.label(
        default = Label("//:BUILD"),
        allow_single_file = True,
    ),
    "_template_ndk_clang": attr.label(
        default = Label("//:BUILD.ndk_clang.tpl"),
        allow_single_file = True,
    ),
    "_template_ndk_root": attr.label(
        default = Label("//:BUILD.ndk_root.tpl"),
        allow_single_file = True,
    ),
    "_template_ndk_sysroot": attr.label(
        default = Label(":BUILD.ndk_sysroot.tpl"),
        allow_single_file = True,
    ),
    "_template_target_systems": attr.label(
        default = Label("//:target_systems.bzl.tpl"),
        allow_single_file = True,
    ),
}

def _exec_configuration_android_ndk_repository_impl(ctx):
    ndk_path = ctx.path(Label(ctx.attr.anchor)).dirname

    return _android_ndk_repository_common(ctx, ndk_path)

exec_configuration_android_ndk_repository = repository_rule(
    doc = "A repository rule that integrates the Android NDK from a workspace. Uses an anchor label to locate the NDK and requires the host platform and Clang resource directory to be specified. For local NDK installations, use android_ndk_repository instead.",
    implementation = _exec_configuration_android_ndk_repository_impl,
    attrs = _COMMON_ATTR | {
        "anchor": attr.string(
            doc = "A label to a file in the NDK directory. The directory containing this file is used as the NDK root path.",
            mandatory = True,
        ),
        "clang_resource_dir": attr.string(
            doc = "The Clang resource directory path. Pass an empty string to auto-detect by running clang --print-resource-dir.",
            mandatory = True,
        ),
        "platform": attr.string(
            doc = "The execution platform for the NDK toolchain (e.g., 'linux-x86_64', 'darwin-arm64', 'windows-x86_64'). Determines which prebuilt toolchain directory is used.",
            values = _EXEC_CONSTRAINTS.keys(),
            mandatory = True,
        ),
    },
)

def _android_ndk_repository_impl(ctx):
    ndk_path = ctx.attr.path or ctx.getenv("ANDROID_NDK_HOME", None)
    if not ndk_path:
        fail("Either the ANDROID_NDK_HOME environment variable or the " +
             "path attribute of android_ndk_repository must be set.")

    if ndk_path.startswith("$WORKSPACE_ROOT"):
        ndk_path = str(ctx.workspace_root) + ndk_path.removeprefix("$WORKSPACE_ROOT")

    return _android_ndk_repository_common(ctx, ndk_path)

android_ndk_repository = repository_rule(
    doc = "A repository rule that integrates the Android NDK from a local path. Uses ANDROID_NDK_HOME environment variable or the path attribute. This is the rule used by the bzlmod extension.",
    implementation = _android_ndk_repository_impl,
    attrs = _COMMON_ATTR | {
        "path": attr.string(
            doc = "The path to the local Android NDK installation. If not set, ANDROID_NDK_HOME environment variable is used. May start with $WORKSPACE_ROOT to reference the workspace root.",
        ),
    },
    environ = ["ANDROID_NDK_HOME"],
    local = True,
)
