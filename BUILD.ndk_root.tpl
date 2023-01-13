"""Top-level aliases."""

package(default_visibility = ["//visibility:public"])

load("//:target_systems.bzl", "CPU_CONSTRAINT", "TARGET_SYSTEM_NAMES")

exports_files(["target_systems.bzl"])

alias(
    name = "toolchain",
    actual = "//{clang_directory}:cc_toolchain_suite",
)

# Loop over TARGET_SYSTEM_NAMES and define all toolchain targets.
[toolchain(
    name = "toolchain_%s" % target_system_name,
    toolchain = "//{clang_directory}:cc_toolchain_%s" % target_system_name,
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    target_compatible_with = [
        "@platforms//os:android",
        CPU_CONSTRAINT[target_system_name],
    ],
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
