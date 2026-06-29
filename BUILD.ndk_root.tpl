"""Top-level aliases."""

load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@@{repository_name}//:ndk_cc_runtimes_toolchain.bzl", "ndk_cc_runtime", "ndk_cc_runtimes_toolchain")
load("//:target_systems.bzl", "CPU_CONSTRAINT", "TARGET_SYSTEM_NAMES")

_BAZEL_MAJOR_VERSION = {bazel_major_version}

package(default_visibility = ["//visibility:public"])

exports_files(["target_systems.bzl"])

alias(
    name = "toolchain",
    actual = "//{clang_directory}:cc_toolchain_suite",
)

toolchain_type(
    name = "disabled_cc_runtimes_toolchain_type",
    visibility = ["//visibility:private"],
)

alias(
    name = "cc_runtimes_toolchain_type",
    actual = "@bazel_tools//tools/cpp:cc_runtimes_toolchain_type" if _BAZEL_MAJOR_VERSION >= 9 else ":disabled_cc_runtimes_toolchain_type",
    visibility = ["//visibility:private"],
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

[ndk_cc_runtime(
    name = "dynamic_cc_runtime_library_%s" % target_system_name,
    shared_libraries = "//{clang_directory}/sysroot:dynamic_runtime_lib_%s" % target_system_name,
    tags = ["manual"],
) for target_system_name in TARGET_SYSTEM_NAMES]

[ndk_cc_runtime(
    name = "static_cc_runtime_library_%s" % target_system_name,
    static_libraries = "//{clang_directory}/sysroot:static_runtime_lib_%s" % target_system_name,
    tags = ["manual"],
) for target_system_name in TARGET_SYSTEM_NAMES]

[ndk_cc_runtimes_toolchain(
    name = "dynamic_cc_runtime_%s" % target_system_name,
    runtime = ":dynamic_cc_runtime_library_%s" % target_system_name,
    tags = ["manual"],
) for target_system_name in TARGET_SYSTEM_NAMES]

[ndk_cc_runtimes_toolchain(
    name = "static_cc_runtime_%s" % target_system_name,
    runtime = ":static_cc_runtime_library_%s" % target_system_name,
    tags = ["manual"],
) for target_system_name in TARGET_SYSTEM_NAMES]

[toolchain(
    name = "dynamic_cc_runtimes_toolchain_%s" % target_system_name,
    exec_compatible_with = {exec_compatible_with},
    target_compatible_with = [
        "@platforms//os:android",
        CPU_CONSTRAINT[target_system_name],
    ],
    target_settings = ["@@{repository_name}//:use_shared_libcpp_enabled"],
    toolchain = ":dynamic_cc_runtime_%s" % target_system_name,
    toolchain_type = ":cc_runtimes_toolchain_type",
) for target_system_name in TARGET_SYSTEM_NAMES]

[toolchain(
    name = "static_cc_runtimes_toolchain_%s" % target_system_name,
    exec_compatible_with = {exec_compatible_with},
    target_compatible_with = [
        "@platforms//os:android",
        CPU_CONSTRAINT[target_system_name],
    ],
    target_settings = ["@@{repository_name}//:use_shared_libcpp_disabled"],
    toolchain = ":static_cc_runtime_%s" % target_system_name,
    toolchain_type = ":cc_runtimes_toolchain_type",
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
