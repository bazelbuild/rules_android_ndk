load(":rules.bzl", "android_ndk_repository")

def _android_ndk_repository_extension_impl(ctx):
  android_ndk_repository(name = "androidndk")

android_ndk_repository_extension = module_extension(
  implementation = _android_ndk_repository_extension_impl,
)
