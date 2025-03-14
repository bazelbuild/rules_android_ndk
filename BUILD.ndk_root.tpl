"""Top-level aliases."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("//:target_systems.bzl", "CPU_CONSTRAINT", "TARGET_SYSTEM_NAMES")

package(default_visibility = ["//visibility:public"])

exports_files(["target_systems.bzl"])

alias(
    name = "toolchain",
    actual = "//{clang_directory}:cc_toolchain_suite",
)

# Loop over TARGET_SYSTEM_NAMES and define all toolchain targets.
[toolchain(
    name = "toolchain_%s" % target_system_name,
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
