# Android NDK Bazel Rules

## Overview

This repository contains Starlark rules for integrating Bazel with the
Android NDK. These rules currently work with Android NDK version 25b or later.

The recommended Bazel version for these rules is **7.4.0 or later**.

For use cases where an older NDK or older Bazel version is required, the legacy
Android native rules in Bazel 7 or earlier are a suitable alternative.

## Getting Started

### Bzlmod setup (recommended)

To use the Android NDK rules, add the following to your `MODULE.bazel` file:

```starlark
# Or a later version of the following bazel_dep()s
bazel_dep(name = "platforms", version = "0.0.10")
bazel_dep(name = "rules_cc", version = "0.0.17")
bazel_dep(name = "rules_android_ndk", version = "0.1.2")

android_ndk_repository_extension = use_extension("@rules_android_ndk//:extension.bzl", "android_ndk_repository_extension")
use_repo(android_ndk_repository_extension, "androidndk")

register_toolchains("@androidndk//:all")
```

### Legacy WORKSPACE setup

To use the Android NDK rules, add the following to your `WORKSPACE` file:

```
http_archive(
    name = "rules_android_ndk",
    sha256 = "89bf5012567a5bade4c78eac5ac56c336695c3bfd281a9b0894ff6605328d2d5",
    strip_prefix = "rules_android_ndk-0.1.3",
    url = "https://github.com/bazelbuild/rules_android_ndk/releases/download/v0.1.3/rules_android_ndk-v0.1.3.tar.gz",
)

http_archive(
    name = "rules_android",
    sha256 = "af84b69ab3d16dd1a41056286e6511f147a94ccea995603e13e934c915c1631c",
    strip_prefix = "rules_android-0.6.0",
    url = "https://github.com/bazelbuild/rules_android/releases/download/v0.6.0/rules_android-v0.6.0.tar.gz",
)

# Android rules dependencies
load("@rules_android//:prereqs.bzl", "rules_android_prereqs")

rules_android_prereqs()

##### rules_java setup for rules_android #####
load("@rules_java//java:rules_java_deps.bzl", "rules_java_dependencies")

rules_java_dependencies()

# note that the following line is what is minimally required from protobuf for the java rules
# consider using the protobuf_deps() public API from @com_google_protobuf//:protobuf_deps.bzl
load("@com_google_protobuf//bazel/private:proto_bazel_features.bzl", "proto_bazel_features")  # buildifier: disable=bzl-visibility

proto_bazel_features(name = "proto_bazel_features")

# register toolchains
load("@rules_java//java:repositories.bzl", "rules_java_toolchains")

rules_java_toolchains()

##### rules_jvm_external setup for rules_android #####
load("@rules_jvm_external//:repositories.bzl", "rules_jvm_external_deps")

rules_jvm_external_deps()

load("@rules_jvm_external//:setup.bzl", "rules_jvm_external_setup")

rules_jvm_external_setup()

##### rules_android setup #####
load("@rules_android//:defs.bzl", "rules_android_workspace")

rules_android_workspace()

# Android SDK setup
load("@rules_android//rules:rules.bzl", "android_sdk_repository")

android_sdk_repository(
    name = "androidsdk",
)

register_toolchains(
    "@rules_android//toolchains/android:android_default_toolchain",
    "@rules_android//toolchains/android_sdk:android_sdk_tools",
)

##### rules_cc setup #####
http_archive(
    name = "rules_cc",
    sha256 = "abc605dd850f813bb37004b77db20106a19311a96b2da1c92b789da529d28fe1",
    strip_prefix = "rules_cc-0.0.17",
    urls = ["https://github.com/bazelbuild/rules_cc/releases/download/0.0.17/rules_cc-0.0.17.tar.gz"],
)

load("@rules_android_ndk//:rules.bzl", "android_ndk_repository")

android_ndk_repository(name = "androidndk")

register_toolchains("@androidndk//:all")
```

Then, set the `ANDROID_NDK_HOME` environment variable or the `path` attribute of
`android_ndk_repository` to the path of the local Android NDK installation
directory. If the path starts with `$WORKSPACE_ROOT`, then this string is
replaced with the root path of the Bazel workspace.

The `api_level` attribute can also be used to set the Android API level to build
against.

Finally, when building an Android app with native dependencies (e.g.
`cc_library` targets), add

    --android_platforms=<platforms>

to your Bazel invocation. `<platforms>` is a comma-separated list of the available
platforms. See https://bazel.build/extending/platforms for more details.
Some common platforms can be constructed as follows:

```starlark
platform(
    name = "arm64-v8a",
    constraint_values = [
        "@platforms//cpu:arm64",
        "@platforms//os:android",
    ],
)

platform(
    name = "x86",
    constraint_values = [
        "@platforms//cpu:x86_32",
        "@platforms//os:android",
    ],
)
```

The `--android_platforms` flag may also be added to the your project's
`.bazelrc` file so that it doesn't have to be specified on the command line.

See the example in https://github.com/bazelbuild/rules_android_ndk/tree/main/examples/basic.
