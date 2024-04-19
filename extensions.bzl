load(":rules.bzl", "android_ndk_repository", "android_ndk_toolchain")

_toolchain = tag_class(
    attrs = {
        "urls": attr.string_list_dict(
            doc = "URLs to download a prebuilt android ndk where the key is the system name (os_arch) and the value is a list of URLs.",
        ),
        "sha256": attr.string_dict(
            doc = "The expected SHA-256 fo the file downloaded as per the `urls` attribute.",
        ),
        "strip_prefix": attr.string_dict(
            doc = "The prefix to strip from the download archive.",
        ),
        "clang_resource_version": attr.int(mandatory = True),
        "path": attr.string(
            doc = "A path to a local android ndk installation. If this attribute is not specified, the environment " +
                  "variable ANDROID_NDK_HOME will be used instead. Note that hermetic toolchains provided by the `urls` " +
                  "attribute has priority over local paths meaning that this attribute will only be considered if the " +
                  "current exec platform does not have a hermetic specification.",
        ),
        "api_level": attr.int(
            doc = "The android api level to use",
            mandatory = True,
        ),
    },
)

_OS_MAPPING = {
    "darwin": "macos",
}

_CPU_MAPPING = {
    "arm64": "aarch64",
    "amd64": "x86_64",
}

def _normalize(system_name):
    os, cpu = system_name.split("_", 1)

    return "%s_%s" % (_OS_MAPPING[os] if os in _OS_MAPPING else os, _CPU_MAPPING[cpu] if cpu in _CPU_MAPPING else cpu)

def _get_local_system(mctx):
    if "mac" in mctx.os.name:
        return "macos_%s" % mctx.os.arch

    return "linux_%s" % mctx.os.arch

def _impl(mctx):
    if len(mctx.modules) != 1 or not mctx.modules[0].is_root:
        fail("androidsdk is currently only available for the root module")

    if len(mctx.modules[0].tags.toolchain) != 1:
        fail("ndk.toolchain can only be set once")

    toolchain = mctx.modules[0].tags.toolchain[0]

    for system_name, urls in toolchain.urls.items():
        android_ndk_repository(
            name = "androidndk_%s" % system_name,
            api_level = toolchain.api_level,
            urls = urls,
            clang_resource_version = toolchain.clang_resource_version,
            exec_system = system_name,
            sha256 = toolchain.sha256[system_name] if system_name in toolchain.sha256 else "",
            strip_prefix = toolchain.strip_prefix[system_name] if system_name in toolchain.strip_prefix else "",
        )

    local_system = _get_local_system(mctx)

    direct_deps = ["androidndk"] + ["androidndk_" + system_name for system_name in toolchain.urls.keys()]
    exec_system_names = [_normalize(key) for key in toolchain.urls.keys()]

    if not (_normalize(local_system) in [_normalize(key) for key in toolchain.urls.keys()]):
        android_ndk_repository(
            name = "androidndk_local",
            api_level = toolchain.api_level,
            path = toolchain.path,
        )

        direct_deps.append("androidndk_local")
        exec_system_names.append(_normalize(local_system))

    android_ndk_toolchain(
        name = "androidndk",
        exec_system_names = exec_system_names,
    )

    return mctx.extension_metadata(
        root_module_direct_deps = direct_deps,
        root_module_direct_dev_deps = [],
    )

ndk = module_extension(
    implementation = _impl,
    tag_classes = {
        "toolchain": _toolchain,
    },
)
