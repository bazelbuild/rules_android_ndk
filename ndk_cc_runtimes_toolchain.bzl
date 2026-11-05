# Copyright 2026 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Rules for exposing Android NDK C++ runtime libraries."""

load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

CcRuntimesInfo = provider(
    doc = "Information about runtime libraries to link into C++ targets.",
    fields = ["runtimes", "copts"],
)

def _ndk_cc_runtime_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    libraries_to_link = [
        cc_common.create_library_to_link(
            actions = ctx.actions,
            static_library = library,
        )
        for library in ctx.files.static_libraries
    ] + [
        cc_common.create_library_to_link(
            actions = ctx.actions,
            cc_toolchain = cc_toolchain,
            dynamic_library = library,
            feature_configuration = feature_configuration,
        )
        for library in ctx.files.shared_libraries
    ]
    cc_info = CcInfo(
        linking_context = cc_common.create_linking_context(
            linker_inputs = depset([
                cc_common.create_linker_input(
                    libraries = depset(libraries_to_link),
                    owner = ctx.label,
                ),
            ]),
        ),
    )

    return [
        DefaultInfo(runfiles = ctx.runfiles(files = ctx.files.shared_libraries)),
        cc_info,
    ]

ndk_cc_runtime = rule(
    implementation = _ndk_cc_runtime_impl,
    attrs = {
        "shared_libraries": attr.label(allow_files = [".so"]),
        "static_libraries": attr.label(allow_files = [".a"]),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)

def _ndk_cc_runtimes_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            cc_runtimes_info = CcRuntimesInfo(
                runtimes = [ctx.attr.runtime],
                copts = [],
            ),
        ),
    ]

ndk_cc_runtimes_toolchain = rule(
    implementation = _ndk_cc_runtimes_toolchain_impl,
    attrs = {
        "runtime": attr.label(
            mandatory = True,
            providers = [CcInfo],
        ),
    },
)
