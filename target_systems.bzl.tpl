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

