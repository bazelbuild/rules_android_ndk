"""
This module adds no-op repository rules when the Android NDK is not installed.
"""

package(default_visibility = ["//visibility:public"])

load(":dummy_cc_toolchain.bzl", "dummy_cc_config", "dummy_cc_toolchain")
load("//:target_systems.bzl", "CPU_CONSTRAINT", "TARGET_SYSTEM_NAMES")

# android_ndk_repository was used without a valid Android NDK being set.
# Either the path attribute of android_ndk_repository or the ANDROID_NDK_HOME
# environment variable must be set.
# This is a minimal BUILD file to allow non-Android builds to continue.

# Loop over TARGET_SYSTEM_NAMES and define all empty toolchain targets.
[toolchain(
    name = "toolchain_%s" % target_system_name,
    toolchain = ":dummy_android_ndk_toolchain_cc",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    target_compatible_with = [
        "@platforms//os:android",
        CPU_CONSTRAINT[target_system_name],
    ],
) for target_system_name in TARGET_SYSTEM_NAMES]

cc_toolchain(
    name = "dummy_android_ndk_toolchain_cc",
    all_files = ":invalid_android_ndk_repository_error",
    compiler_files = ":invalid_android_ndk_repository_error",
    dwp_files = ":invalid_android_ndk_repository_error",
    linker_files = ":invalid_android_ndk_repository_error",
    objcopy_files = ":invalid_android_ndk_repository_error",
    strip_files = ":invalid_android_ndk_repository_error",
    supports_param_files = 0,
    toolchain_config = ":cc_toolchain_config",
    toolchain_identifier = "dummy_wasm32_cc",
)

dummy_cc_config(
    name = "cc_toolchain_config",
)

cc_library(
    name = "cpufeatures",
    data = [":error_message"],
)

genrule(
    name = "invalid_android_ndk_repository_error",
    outs = [
        "error_message",
    ],
    cmd = """echo
    echo rules_android_ndk was used without a valid Android NDK being set: \
    either the path attribute of android_ndk_repository or the ANDROID_NDK_HOME environment variable must be set.
    echo
    exit 1""",
)
