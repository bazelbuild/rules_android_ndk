To build, run:

    bazel build :all --cpu=arm64-v8a --crosstool_top=@androidndk//:toolchain

in this directory.

Prefer using https://github.com/google/cpu_features instead of the cpu_features
target defined by android_ndk_repository.
