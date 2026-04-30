load("@rules_android//rules:rules.bzl", "android_binary", "android_library")
load("@rules_cc//cc:cc_library.bzl", "cc_library")

android_binary(
    name = "app",
    manifest = "AndroidManifest.xml",
    deps = [
        ":applib",
    ],
)

android_library(
    name = "applib",
    srcs = [
        "Jni.java",
        "MainActivity.java",
    ],
    manifest = "AndroidManifest.xml",
    resource_files = glob(["res/**"]),
    deps = [
        ":jni",
    ],
)

[genrule(
    name = "source_with_long_name_%d" % i,
    outs = ["source_with_long_name_%d.cc" % i],
    cmd = "echo '#define SRC_%d' > $@" % i,
) for i in range(256)]

[cc_library(
    name = "lib_with_long_name_%d" % i,
    srcs = [":source_with_long_name_%d.cc" % i],
) for i in range(256)]

cc_library(
    name = "huge_lib",
    # Tests a large number of dependencies
    deps = [":lib_with_long_name_%d" % i for i in range(256)],
)

cc_library(
    name = "jni",
    srcs = ["jni.cc"],
    # Tests a large number of params
    linkopts = ["-llog"] * 8000,
    deps = [
        ":huge_lib",
        ":jni_dep",
    ],
)

cc_library(
    name = "jni_dep",
    srcs = ["jni_dep.cc"],
    hdrs = ["jni_dep.h"],
    linkopts = ["-llog"],
)
