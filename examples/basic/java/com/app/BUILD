
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
      "MainActivity.java",
      "Jni.java",
  ],
  resource_files = glob(["res/**"]),
  manifest = "AndroidManifest.xml",
  deps = [
    ":jni",
  ]
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
