# Android NDK Bazel Rules

## Overview

This repository contains Starlark rules for integrating Bazel with the
Android NDK. These rules currently work with Android NDK version 25b.

NOTE: This is a development preview of the Starlark Android NDK Bazel
rules. These rules are not guaranteed to be complete or work for every
NDK use case. Bazel versions up to and including 6.0.0 contain a
built-in ("native") version of `android_ndk_repository` described at
https://bazel.build/reference/be/android#android_ndk_repository. Over
time, these Starlark rules will replace the native version of
`android_ndk_repository`.

## Getting Started

To use the Android NDK rules, add the following to your `WORKSPACE` file:

    # Or a later commit
    RULES_ANDROID_NDK_COMMIT= "81ec8b79dc50ee97e336a25724fdbb28e33b8d41"
    RULES_ANDROID_NDK_SHA = "b29409496439cdcdb50a8e161c4953ca78a548e16d3ee729a1b5cd719ffdacbf"

    load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
    http_archive(
        name = "rules_android_ndk",
        url = "https://github.com/bazelbuild/rules_android_ndk/archive/%s.zip" % RULES_ANDROID_NDK_COMMIT,
        sha256 = RULES_ANDROID_NDK_SHA,
        strip_prefix = "rules_android_ndk-%s" % RULES_ANDROID_NDK_COMMIT,
    )

    load("@rules_android_ndk//:rules.bzl", "android_ndk_repository")
    android_ndk_repository(name = "androidndk", version = "r25c")

    # either register the toolchains, or use `--extra_toolchains` when invoking Bazel
    register_toolchains("@androidndk//:all")

You can also customize the `base_url` attribute if, for example, you mirror the NDK archives
on a private server.

Some sha256 checksums are included in this repository, but these might not be up to date,
if you want to use a version of the NDK that's not included, you can also specify the `sha256sums`
attribute which maps platforms to checksums, like so:

```
android_ndk_repository(
    name = "androidndk",
    version = "r25c"
    sha256sums = {
        "windows": "f70093964f6cbbe19268f9876a20f92d3a593db3ad2037baadd25fd8d71e84e2",
        "darwin": "b01bae969a5d0bfa0da18469f650a1628dc388672f30e0ba231da5c74245bc92",
        "linux": "769ee342ea75f80619d985c2da990c48b3d8eaf45f48783a2d48870d04b46108",
    }
)
```

The `api_level` attribute can also be used to set the Android API level to build
against.

Finally, when building an Android app with native dependencies (e.g.
`cc_library` targets), add

    --fat_apk_cpu=<cpus> --android_crosstool_top=@androidndk//:toolchain

to your Bazel invocation. `<cpus>` is a comma-separated list of the available
CPUs:

    armeabi-v7a
    arm64-v8a
    x86
    x86_64

e.g. `--fat_apk_cpu=arm64-v7a` or `--fat_apk_cpu=arm64-v7a,x86`.

These flags may also be added to the your project's `.bazelrc` file so that they
don't have to be specified on the command line.

See the example in https://github.com/bazelbuild/rules_android_ndk/tree/main/examples/basic.
