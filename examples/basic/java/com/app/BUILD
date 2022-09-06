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

cc_library(
    name = "jni",
    srcs = ["jni.cc"],
    deps = [":jni_dep"],
)

cc_library(
    name = "jni_dep",
    srcs = ["jni_dep.cc"],
    hdrs = ["jni_dep.h"],
)
