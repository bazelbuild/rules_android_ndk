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
