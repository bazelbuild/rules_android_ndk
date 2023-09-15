"""Declarations for the NDK's Clang sysroot directory."""

package(default_visibility = ["//visibility:public"])

load("//:target_systems.bzl", "TARGET_SYSTEM_NAMES")

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
    visibility = ["//visibility:public"],
)

[filegroup(
    name = "libc_top_%s" % target_system_name,
    srcs = glob([
        "usr/lib/{target_system_name}/{api_level}/*".format(
            target_system_name = target_system_name,
        ),
    ]),
) for target_system_name in TARGET_SYSTEM_NAMES]

[filegroup(
    name = "dynamic_runtime_lib_%s" % target_system_name,
    srcs = glob([
        # "usr/lib/%s/**/*.so" % target_system_name,
        # "usr/lib/%s/**/*.a" % target_system_name,
    ], allow_empty = True),
) for target_system_name in TARGET_SYSTEM_NAMES]

[filegroup(
    name = "static_runtime_lib_%s" % target_system_name,
    srcs = [
        "usr/lib/%s/libc++_static.a" % target_system_name,
        "usr/lib/%s/libc++abi.a" % target_system_name,
    ] + {
        # libandroid_support was removed in NDK 26, so use a glob
        # for backward compatibility.
        "arm-linux-androideabi": glob([
            "usr/lib/arm-linux-androideabi/libandroid_support.a",
        ], allow_empty = True),
        "i686-linux-android": glob([
            "usr/lib/i686-linux-android/libandroid_support.a",
        ], allow_empty = True),
    }.get(
        target_system_name,
        [],
    ),
) for target_system_name in TARGET_SYSTEM_NAMES]

filegroup(
    name = "sysroot_includes",
    srcs = glob([
        "**/include/**/*",
    ]),
)
