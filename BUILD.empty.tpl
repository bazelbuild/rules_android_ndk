"""
This module adds no-op repository rules when the Android NDK is not installed.
"""

package(default_visibility = ["//visibility:public"])

load("//:target_systems.bzl", "CPU_CONSTRAINT", "TARGET_SYSTEM_NAMES")

# android_ndk_repository was used without a valid Android NDK being set.
# Either the path attribute of android_ndk_repository or the ANDROID_NDK_HOME
# environment variable must be set.
# This is a minimal BUILD file to allow non-Android builds to continue.

# Loop over TARGET_SYSTEM_NAMES and define all empty toolchain targets.
[toolchain(
    name = "toolchain_%s" % target_system_name,
    toolchain = ":error_message",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    target_compatible_with = [
        "@platforms//os:android",
        CPU_CONSTRAINT[target_system_name],
    ],
) for target_system_name in TARGET_SYSTEM_NAMES]

cc_library(
    name = "cpufeatures",
    data = [":error_message"],
)

genrule(
    name = "invalid_android_ndk_repository_error",
    outs = [
        "error_message",
    ],
    cmd = """echo \
    android_ndk_repository was used without a valid Android NDK being set. \
    Either the path attribute of android_ndk_repository or the ANDROID_NDK_HOME \
    environment variable must be set. ; \
    exit 1 """,
)
