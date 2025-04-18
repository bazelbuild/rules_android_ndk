This is a copy of the basic NDK app, except this example showcases the `disable_fallback_native_deps_linking` feature. After building the app, you should see multiple .so files in your compiled APK.

To build, run:

    bazel build java/com/app --android_platforms=//:arm64-v8a,//:x86 --features=disable_fallback_native_deps_linking

in this directory.

Default behavior:
```bash
$ unzip -l bazel-bin/java/com/app/app.apk | grep "\.so"
     7896  2010-01-01 00:00   lib/arm64-v8a/libapp.so
     6512  2010-01-01 00:00   lib/x86/libapp.so
```
