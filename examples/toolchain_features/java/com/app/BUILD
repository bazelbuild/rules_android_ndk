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
) for i in range(1024)]

cc_library(
    name = "huge_lib",
    srcs = [":source_with_long_name_%d" % i for i in range(1024)],
    linkopts = ["-llog"] * 1024,
    linkstatic = 1,
)

cc_library(
    name = "jni",
    srcs = ["jni.cc"],
    deps = [
        ":jni_dep",
        ":huge_lib",
    ],
)

cc_library(
    name = "jni_dep",
    srcs = ["jni_dep.cc"],
    hdrs = ["jni_dep.h"],
    linkopts = ["-llog"],
)
