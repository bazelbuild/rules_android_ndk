"""Top-level aliases."""

package(default_visibility = ["//visibility:public"])

load("//:target_systems.bzl", "CPU_CONSTRAINT", "TARGET_SYSTEM_NAMES", "get_platform_constraints")

exports_files(["target_systems.bzl"])

EXEC_SYSTEM_NAMES = {exec_system_names}

[
    toolchain(
        name = "toolchain_%s_%s" % (exec_system_name, target_system_name),
        exec_compatible_with = get_platform_constraints(exec_system_name),
        target_compatible_with = [
            "@platforms//os:android",
            CPU_CONSTRAINT[target_system_name],
        ],
        toolchain = "@@{repository_name}_%s//{clang_directory}:cc_toolchain_%s" % (exec_system_name, target_system_name),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )
    for target_system_name in TARGET_SYSTEM_NAMES
    for exec_system_name in EXEC_SYSTEM_NAMES
]
