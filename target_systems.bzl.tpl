"""Target systems supported by the NDK rules."""

TARGET_SYSTEM_NAMES = (
    "arm-linux-androideabi",
    "aarch64-linux-android",
    "i686-linux-android",
    "x86_64-linux-android",
)

CPU_CONSTRAINT = {
    "arm-linux-androideabi": "@platforms//cpu:armv7",
    "aarch64-linux-android": "@platforms//cpu:aarch64",
    "i686-linux-android": "@platforms//cpu:x86_32",
    "x86_64-linux-android": "@platforms//cpu:x86_64",
}

_OS_MAPPING = {
    "darwin": "macos",
}

_CPU_MAPPING = {
    "arm64": "aarch64",
}

def get_platform_constraints(system_name):
    os, cpu = system_name.split("_", 1)

    return [
        "@platforms//os:%s" % (_OS_MAPPING[os] if os in _OS_MAPPING else os),
        "@platforms//cpu:%s" % (_CPU_MAPPING[cpu] if cpu in _CPU_MAPPING else cpu),
    ]


def get_clang_directory(exec_system):
    os_name, _ = exec_system.split("_", 1)
    if os_name == "linux":
        clang_directory = "toolchains/llvm/prebuilt/linux-x86_64"
    elif os_name == "mac os x" or os_name == "darwin" or os_name == "macos":
        # Note: darwin-x86_64 does indeed contain fat binaries with arm64 slices, too.
        clang_directory = "toolchains/llvm/prebuilt/darwin-x86_64"
    else:
        fail("Unsupported operating system: " + os_name)

    return clang_directory

