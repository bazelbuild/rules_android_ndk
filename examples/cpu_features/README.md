To build, run:

    bazel build :jni --platforms=//:arm64-v8a

in this directory.

NOTE: Prefer using https://github.com/google/cpu_features instead of the cpu_features
target defined by android_ndk_repository.
