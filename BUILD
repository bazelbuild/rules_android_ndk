# Note that this BUILD file is necessary for `android_ndk_repository` in `rules.bzl`.

load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")

exports_files([
    "LICENSE",
] + glob([
    "*.tpl",
]))

bool_flag(
    name = "use_shared_libcpp",
    build_setting_default = False,
    visibility = ["//visibility:public"],
)

config_setting(
    name = "use_shared_libcpp_enabled",
    flag_values = {
        ":use_shared_libcpp": "true",
    },
    visibility = ["//visibility:public"],
)

config_setting(
    name = "use_shared_libcpp_disabled",
    flag_values = {
        ":use_shared_libcpp": "false",
    },
    visibility = ["//visibility:public"],
)
