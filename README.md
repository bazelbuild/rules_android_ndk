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
    android_ndk_repository(name = "androidndk")

Then, set the `ANDROID_NDK_HOME` environment variable or the `path` attribute of
`android_ndk_repository` to the path of the local Android NDK installation
directory.

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
