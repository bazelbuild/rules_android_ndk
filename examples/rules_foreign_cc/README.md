To build, run:

    bazel build java/com/app --fat_apk_cpu=arm64-v8a,x86 --android_crosstool_top=@androidndk//:toolchain

in this directory.
