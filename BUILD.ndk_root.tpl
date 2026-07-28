"""Top-level aliases."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("//:target_systems.bzl", "CPU_CONSTRAINT", "TARGET_SYSTEM_NAMES")

package(default_visibility = ["//visibility:public"])

exports_files(["target_systems.bzl"])

# A simple file group that includes all files with public visiblity.
# This is useful to easily export NDK files outside of the bazel package,
# e.g. to allow Gradle to access the NDK files when using the NDK managed
# by Bazel.
# See this discussion for more context: https://github.com/bazelbuild/rules_android_ndk/pull/136
# Once Android Studio Bazel plugin reaches feature parity with Gradle, and AS integration will
# no longer needed hacks where Bazel is used as a secondary citizen, this filegroup can be removed.
filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//visibility:public"],
)

alias(
    name = "toolchain",
    actual = "//{clang_directory}:cc_toolchain_suite",
)

# Loop over TARGET_SYSTEM_NAMES and define all toolchain targets.
[toolchain(
    name = "toolchain_%s" % target_system_name,
    exec_compatible_with = {exec_compatible_with},
    target_compatible_with = [
        "@platforms//os:android",
        CPU_CONSTRAINT[target_system_name],
    ],
    toolchain = "//{clang_directory}:cc_toolchain_%s" % target_system_name,
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
) for target_system_name in TARGET_SYSTEM_NAMES]

cc_library(
    name = "cpufeatures",
    srcs = glob([
        "sources/android/cpufeatures/*.c",
        # TODO(#32): Remove this hack
        "ndk/sources/android/cpufeatures/*.c",
    ]),
    hdrs = glob([
        "sources/android/cpufeatures/*.h",
        # TODO(#32): Remove this hack
        "ndk/sources/android/cpufeatures/*.h",
    ]),
    linkopts = ["-ldl"],
)

# NOTE: New projects should use GameActivity instead.
# https://developer.android.com/games/agdk/game-activity
cc_library(
    name = "native_app_glue",
    srcs = glob([
        "sources/android/native_app_glue/*.c",
        # TODO(#32): Remove this hack
        "ndk/sources/android/native_app_glue/*.c",
    ]),
    hdrs = glob([
        "sources/android/native_app_glue/*.h",
        # TODO(#32): Remove this hack
        "ndk/sources/android/native_app_glue/*.h",
    ]),
)

exports_files([
    "sources/android/native_app_glue/android_native_app_glue.h",
])
