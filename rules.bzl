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

def _get_clang_directory(rctx):
    exec_system = rctx.attr.exec_system
    os_name, _ = (exec_system if exec_system else rctx.os.name).split("_", 1)
    if os_name == "linux":
        clang_directory = "toolchains/llvm/prebuilt/linux-x86_64"
    elif os_name == "mac os x" or os_name == "darwin" or os_name == "macos":
        # Note: darwin-x86_64 does indeed contain fat binaries with arm64 slices, too.
        clang_directory = "toolchains/llvm/prebuilt/darwin-x86_64"
    else:
        fail("Unsupported operating system: " + os_name)

    return clang_directory

def _android_ndk_repository_impl(rctx):
    """Install the Android NDK files.

    Args:
        rctx: An implementation context.

    Returns:
        A final dict of configuration attributes and values.
    """
    clang_directory = _get_clang_directory(rctx)
    sysroot_directory = "%s/sysroot" % clang_directory

    if len(rctx.attr.urls) > 0:
        rctx.download_and_extract(
            url = rctx.attr.urls,
            sha256 = rctx.attr.sha256,
            stripPrefix = rctx.attr.strip_prefix,
        )
    else:
        ndk_path = rctx.attr.path or rctx.os.environ.get("ANDROID_NDK_HOME", None)
        if not ndk_path:
            fail("Either the ANDROID_NDK_HOME environment variable or the " +
                 "path attribute of android_ndk_repository must be set.")
        _create_symlinks(rctx, ndk_path, clang_directory, sysroot_directory)

    api_level = rctx.attr.api_level or 31

    clang_resource_directory = "%s/lib/clang/%s" % (clang_directory, str(rctx.attr.clang_resource_version))

    # Use a label relative to the workspace from which this repository rule came
    # to get the workspace name.
    repository_name = rctx.attr._build.workspace_name

    rctx.template(
        "BUILD.bazel",
        rctx.attr._template_ndk_root,
        {
            "{clang_directory}": clang_directory,
        },
        executable = False,
    )

    rctx.template(
        "%s/BUILD.bazel" % clang_directory,
        rctx.attr._template_ndk_clang,
        {
            "{repository_name}": repository_name,
            "{api_level}": str(api_level),
            "{clang_resource_directory}": clang_resource_directory,
            "{sysroot_directory}": sysroot_directory,
        },
        executable = False,
    )

    rctx.template(
        "target_systems.bzl",
        rctx.attr._template_target_systems,
        {
        },
        executable = False,
    )

    rctx.template(
        "ndk_cc_toolchain_config.bzl",
        rctx.attr._template_ndk_cc_toolchain_config,
        {
        },
        executable = False,
    )

    rctx.template(
        "%s/BUILD.bazel" % sysroot_directory,
        rctx.attr._template_ndk_sysroot,
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

android_ndk_repository = repository_rule(
    attrs = {
        "path": attr.string(),
        "api_level": attr.int(),
        "urls": attr.string_list(),
        "sha256": attr.string(default = ""),
        "strip_prefix": attr.string(default = ""),
        "exec_system": attr.string(),
        "clang_resource_version": attr.int(),
        "_build": attr.label(default = ":BUILD", allow_single_file = True),
        "_template_target_systems": attr.label(default = ":target_systems.bzl.tpl", allow_single_file = True),
        "_template_ndk_root": attr.label(default = ":BUILD.ndk_root.tpl", allow_single_file = True),
        "_template_ndk_clang": attr.label(default = ":BUILD.ndk_clang.tpl", allow_single_file = True),
        "_template_ndk_sysroot": attr.label(default = ":BUILD.ndk_sysroot.tpl", allow_single_file = True),
        "_template_ndk_cc_toolchain_config": attr.label(default = ":ndk_cc_toolchain_config.bzl", allow_single_file = True),
    },
    local = True,
    implementation = _android_ndk_repository_impl,
)

def _android_ndk_toolchain_impl(rctx):
    rctx.template(
        "BUILD.bazel",
        rctx.attr._template_ndk_toolchain,
        {
            "{repository_name}": rctx.name,
            "{exec_system_names}": "[%s]" % ",".join(['"%s"' % name for name in rctx.attr.exec_system_names]),
        },
        executable = False,
    )

    rctx.template(
        "target_systems.bzl",
        rctx.attr._template_target_systems,
        {
        },
        executable = False,
    )

android_ndk_toolchain = repository_rule(
    implementation = _android_ndk_toolchain_impl,
    attrs = {
        "exec_system_names": attr.string_list(),
        "_template_target_systems": attr.label(default = ":target_systems.bzl.tpl", allow_single_file = True),
        "_template_ndk_toolchain": attr.label(default = ":BUILD.ndk_toolchain.tpl", allow_single_file = True),
        "_template_ndk_module": attr.label(default = ":MODULE.ndk_toolchain.tpl", allow_single_file = True),
    },
)
