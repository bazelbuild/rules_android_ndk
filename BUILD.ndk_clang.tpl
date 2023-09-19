"""Declarations for the NDK's Clang directory."""

load("@{repository_name}//:ndk_cc_toolchain_config.bzl", "ndk_cc_toolchain_config_rule")
load("//:target_systems.bzl", "TARGET_SYSTEM_NAMES")

package(default_visibility = ["//visibility:public"])

cc_toolchain_suite(
    name = "cc_toolchain_suite",
    toolchains = {
        "armeabi-v7a": ":cc_toolchain_arm-linux-androideabi",
        "arm64-v8a": ":cc_toolchain_aarch64-linux-android",
        "x86": ":cc_toolchain_i686-linux-android",
        "x86_64": ":cc_toolchain_x86_64-linux-android",
    },
)

[cc_toolchain(
    name = "cc_toolchain_%s" % target_system_name,
    all_files = ":all_files",
    ar_files = ":ar_files",
    as_files = ":as_files",
    compiler_files = ":compiler_files_%s" % target_system_name,
    coverage_files = ":coverage_files",
    dwp_files = ":dwp_files",
    dynamic_runtime_lib = ":dynamic_runtime_lib_%s" % target_system_name,
    libc_top = ":libc_top_%s" % target_system_name,
    linker_files = ":linker_files_%s" % target_system_name,
    objcopy_files = ":objcopy_files",
    static_runtime_lib = "static_runtime_lib_%s" % target_system_name,
    strip_files = ":strip_files",
    supports_header_parsing = 0,
    toolchain_config = ":toolchain_config_%s" % target_system_name,
    toolchain_identifier = "toolchain_identifier_%s" % target_system_name,
) for target_system_name in TARGET_SYSTEM_NAMES]

[ndk_cc_toolchain_config_rule(
    name = "toolchain_config_%s" % target_system_name,
    api_level = {api_level},
    clang_resource_directory = "{clang_resource_directory}",
    target_system_name = target_system_name,
    toolchain_identifier = "toolchain_identifier_%s" % target_system_name,
) for target_system_name in TARGET_SYSTEM_NAMES]

filegroup(
    name = "all_binaries",
    srcs = glob([
      "bin/*",
      "lib64/**/*",
      "lib/**/*",
    ]),
)

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]) + ["//{sysroot_directory}:all_files"],
)

filegroup(
    name = "ar_files",
    srcs = [":all_binaries"],
    output_licenses = ["unencumbered"],
)

filegroup(
    name = "as_files",
    srcs = [":all_binaries"],
    output_licenses = ["unencumbered"],
)


[filegroup(
    name = "compiler_files_%s" % target_system_name,
    srcs = [
        "bin/clang",
        ":ar_files",
        ":as_files",
        ":objcopy_files",
        "//{sysroot_directory}:sysroot_includes",
    ] + glob([
        "prebuilt_include/**",
        "include/**",
        "lib/gcc/%s/**" % target_system_name,
        "lib64/**/*",
        "lib/**/*",
    ], allow_empty = True),
    output_licenses = ["unencumbered"],
) for target_system_name in TARGET_SYSTEM_NAMES]


filegroup(
    name = "coverage_files",
    srcs = [":all_binaries"],
    output_licenses = ["unencumbered"],
)


filegroup(
    name = "dwp_files",
    srcs = [":all_binaries"],
    output_licenses = ["unencumbered"],
)

[filegroup(
    name = "dynamic_runtime_lib_%s" % target_system_name,
    srcs = ["//{sysroot_directory}:dynamic_runtime_lib_%s" % target_system_name],
) for target_system_name in TARGET_SYSTEM_NAMES]

[filegroup(
    name = "libc_top_%s" % target_system_name,
    srcs = ["//{sysroot_directory}:libc_top_%s" % target_system_name],
) for target_system_name in TARGET_SYSTEM_NAMES]

[filegroup(
    name = "linker_files_%s" % target_system_name,
    srcs = [
        ":all_binaries",
        ":static_runtime_lib_%s" % target_system_name,
    ] + glob([
        "lib/gcc/%s/**" % target_system_name,
        "lib64/**",
        "lib/**",
    ], allow_empty = True),
) for target_system_name in TARGET_SYSTEM_NAMES]

filegroup(
    name = "objcopy_files",
    srcs = [":all_binaries"],
    output_licenses = ["unencumbered"],
)

[filegroup(
    name = "static_runtime_lib_%s" % target_system_name,
    srcs = ["//{sysroot_directory}:static_runtime_lib_%s" % target_system_name],
) for target_system_name in TARGET_SYSTEM_NAMES]

filegroup(
    name = "strip_files",
    srcs = [":all_files"],
    output_licenses = ["unencumbered"],
)
