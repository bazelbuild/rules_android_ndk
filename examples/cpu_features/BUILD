cc_library(
    name = "jni",
    srcs = ["jni.cc"],
    deps = ["@androidndk//:cpufeatures"],
)

# Used for testing cpu features included through "ndk/"-prefixed path.
# Use #include "sources/android/cpufeatures/cpu-features.h" in future
# code. See https://github.com/bazelbuild/rules_android_ndk/issues/32
cc_library(
    name = "jni_cpu_features_compat",
    srcs = ["jni_cpu_features_compat.cc"],
    deps = ["@androidndk//:cpufeatures"],
)
