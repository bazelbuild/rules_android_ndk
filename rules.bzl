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

def _android_ndk_repository_impl(ctx):
    """Install the Android NDK files.

    Args:
        ctx: An implementation context.

    Returns:
        A final dict of configuration attributes and values.
    """

    ndk_path = ctx.os.environ.get("ANDROID_NDK_HOME", None)
    if ndk_path == None:
        ndk_path = ctx.attr.path
    if not ndk_path:
        fail("Either the ANDROID_NDK_HOME environment variable or the " +
             "path attribute of android_ndk_repository must be set.")

    if ctx.os.name == "linux":
        clang_directory = "toolchains/llvm/prebuilt/linux-x86_64"
    elif ctx.os.name == "mac os x":
        clang_directory = "toolchains/llvm/prebuilt/darwin-x86_64"
        # Note: ^ darwin-x86_64 does indeed contain fat binaries with arm64 slices, too.

    else:
        fail("Unsupported operating system: " + ctx.os.name)

    sysroot_directory = "%s/sysroot" % clang_directory

    _create_symlinks(ctx, ndk_path, clang_directory, sysroot_directory)

    api_level = ctx.attr.api_level or 31

    lib64_clang_directory = clang_directory + "/lib64/clang"
    lib64_clang_files = ctx.path(lib64_clang_directory).readdir()
    if len(lib64_clang_files) != 1:
        fail("Expected 1 directory under " + lib64_clang_directory)
    clang_resource_directory = lib64_clang_files[0]

    # Use a label relative to the workspace from which this repository rule came
    # to get the workspace name.
    repository_name = Label("//:BUILD").workspace_name

    ctx.template(
        "BUILD",
        Label("//:BUILD.ndk_root.tpl"),
        {
            "{clang_directory}": clang_directory,
        },
        executable = False,
    )

    ctx.template(
        "%s/BUILD" % clang_directory,
        Label("//:BUILD.ndk_clang.tpl"),
        {
            "{repository_name}": repository_name,
            "{api_level}": str(api_level),
            "{clang_resource_directory}": str(clang_resource_directory),
            "{sysroot_directory}": sysroot_directory,
        },
        executable = False,
    )

    ctx.template(
        "%s/BUILD" % sysroot_directory,
        Label("//:BUILD.ndk_sysroot"),
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

android_ndk_repository = repository_rule(
    implementation = _android_ndk_repository_impl,
    attrs = {
        "path": attr.string(),
        "api_level": attr.int(),
    },
    local = True,
)
