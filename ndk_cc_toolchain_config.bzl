# Copyright 2022 The Bazel Authors. All rights reserved.
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

"""Toolchain command-line configuration logic."""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", action = "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "feature",
    "feature_set",
    "flag_group",
    "tool",
    "tool_path",
    "variable_with_value",
    "with_feature_set",
    flag_set_ = "flag_set",
)

def ndk_cc_toolchain_config(
        api_level,
        target_system_name,
        tools,
        **config):
    """Implement the arguments to cc_common.create_cc_toolchain_config_info.

    Args:
        api_level: Integer level of the SDK version.
        target_system_name: Argument to the --target flag.
        tools: Dict of (tool_name, tool_path) items.
        **config: Legacy/default arguments.

    Returns:
        A keyword argument dictionary for cc_common.create_cc_toolchain_config_info.

    """
    actions = construct_actions_(action)

    # Construct tool_paths.
    tool_of_tool_name = {
        tool_name: tool(path = path)
        for (tool_name, path) in tools.items()
    }

    tool_paths = [
        tool_path(
            name = tool_name,
            path = path,
        )
        for (tool_name, path) in tools.items()
    ]

    if "gcc" not in tools:
        tool_paths.append(tool_path(name = "gcc", path = tools["clang"]))

    # Construct action configurations.
    action_configs = [
        action_config(
            action_name = action.cpp_link_nodeps_dynamic_library,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.strip,
            enabled = True,
            flag_sets = [
                flag_set(
                    flags = ["--strip-unneeded"],
                    features = ["fully_strip"],
                ),
                flag_set(
                    flags = ["--strip-debug"],
                    not_features = ["fully_strip"],
                ),
                flag_set(
                    flag_groups = [
                        flag_group(flags = ["-p", "-o", "%{output_file}"]),
                        flag_group(
                            flags = " ".join([
                                "-R .gnu.switches.text.quote_paths",
                                "-R .gnu.switches.text.bracket_paths",
                                "-R .gnu.switches.text.system_paths",
                                "-R .gnu.switches.text.cpp_defines",
                                "-R .gnu.switches.text.cpp_includes",
                                "-R .gnu.switches.text.cl_args",
                                "-R .gnu.switches.text.lipo_info",
                                "-R .gnu.switches.text.annotation",
                            ]).split(" "),
                        ),
                        flag_group(
                            flags = ["%{stripopts}"],
                            iterate_over = "stripopts",
                        ),
                        flag_group(flags = ["%{input_file}"]),
                    ],
                ),
            ],
            tools = [tool_of_tool_name["strip"]],
        ),
        action_config(
            action_name = action.cpp_link_dynamic_library,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.cc_flags_make_variable,
            enabled = True,
        ),
        action_config(
            action_name = action.assemble,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.preprocess_assemble,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.cpp_module_compile,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.c_compile,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.cpp_header_parsing,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.cpp_module_codegen,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.cpp_link_static_library,
            enabled = True,
            flag_sets = [
                flag_set(
                    flag_groups = [
                        flag_group(
                            flags = ["rcsD", "%{output_execpath}"],
                            expand_if_available = "output_execpath",
                        ),
                    ],
                ),
                flag_set(
                    flag_groups = [
                        flag_group(
                            iterate_over = "libraries_to_link",
                            flag_groups = [
                                flag_group(
                                    flags = ["%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "object_file",
                                    ),
                                ),
                                flag_group(
                                    flags = ["%{libraries_to_link.object_files}"],
                                    iterate_over = "libraries_to_link.object_files",
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "object_file_group",
                                    ),
                                ),
                            ],
                            expand_if_available = "libraries_to_link",
                        ),
                    ],
                ),
                flag_set(
                    flag_groups = [
                        flag_group(
                            flags = ["@%{linker_param_file}"],
                            expand_if_available = "linker_param_file",
                        ),
                    ],
                ),
            ],
            tools = [tool_of_tool_name["ar"]],
        ),
        action_config(
            action_name = "objcopy_embed_data",
            enabled = True,
            flag_sets = [
                flag_set(
                    flags = {
                        "aarch64-linux-android": "-I binary -B aarch64 -O elf64-littleaarch64",
                        "arm-linux-androideabi": "-I binary -B arm -O elf32-littlearm",
                        "i686-linux-android": "-I binary -B i386 -O elf32-i386",
                        "x86_64-linux-android": "-I binary -B i386 -O elf64-x86-64",
                    }[target_system_name].split(" "),
                ),
            ],
            tools = [tool_of_tool_name["objcopy"]],
        ),
        action_config(
            action_name = action.cpp_compile,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.linkstamp_compile,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.clif_match,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.cpp_link_executable,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.lto_backend,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.lto_index_for_executable,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.lto_index_for_dynamic_library,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
        action_config(
            action_name = action.lto_index_for_nodeps_dynamic_library,
            enabled = True,
            tools = [tool_of_tool_name["clang"]],
        ),
    ]

    # Construct features.
    features = [
        # This set of magic "feature"s are important configuration information for bazel.
        feature(
            name = "no_legacy_features",
            enabled = True,
        ),
        feature(
            name = "has_configured_linker_path",
            enabled = True,
        ),

        # Blaze requests this feature by default, but we don't care.
        feature(name = "dependency_file"),

        # Blaze requests this feature by default, but we don't care.
        feature(name = "random_seed"),

        # Blaze requests this feature if fission is requested
        # Blaze tests if it's supported to see if we support fission.
        feature(name = "per_object_debug_info"),

        # Blaze tests if this feature is supported before setting preprocess_defines.
        feature(name = "preprocessor_defines"),

        # Blaze requests this feature by default.
        # Blaze tests if this feature is supported before setting includes.
        feature(name = "include_paths"),

        # Blaze tests if this feature is enabled in order to create implicit
        # "nodeps" .so outputs from cc_library rules.
        feature(
            name = "supports_dynamic_linker",
            enabled = True,
        ),

        # Blaze requests this feature when linking a cc_binary which is
        # "dynamic" aka linked against nodeps-dynamic-library cc_library
        # outputs.
        feature(name = "dynamic_linking_mode"),
        feature(
            name = "static_link_cpp_runtimes",
            enabled = True,
        ),
        feature(
            name = "supports_start_end_lib",
            enabled = True,
        ),

        # This feature stanza is used by third_party/stl/BUILD to determine
        # which headers to include in the module.
        feature(
            name = "has_cxx17_headers",
            enabled = True,
        ),

        # This feature is used generically to determine which STL is enabled by
        # default. (e.g. for //tools/cpp:standard_library)
        feature(
            name = "has_libcxx",
            enabled = True,
        ),

        # This feature is needed to prevent name mangling during dynamic library links.
        feature(name = "copy_dynamic_libraries_to_binary"),

        #### Configuration features
        feature(
            name = "crosstool_cpu",
            enabled = True,
            implies = [{
                "arm-linux-androideabi": "crosstool_cpu_arm",
                "aarch64-linux-android": "crosstool_cpu_arm64",
                "i686-linux-android": "crosstool_cpu_x86",
                "x86_64-linux-android": "crosstool_cpu_x86_64",
            }[target_system_name]],
        ),
        feature(
            name = "crosstool_cpu_arm",
            provides = ["variant:crosstool_cpu"],
        ),
        feature(
            name = "crosstool_cpu_arm64",
            provides = ["variant:crosstool_cpu"],
        ),
        feature(
            name = "crosstool_cpu_x86",
            provides = ["variant:crosstool_cpu"],
        ),
        feature(
            name = "crosstool_cpu_x86_64",
            provides = ["variant:crosstool_cpu"],
        ),
        feature(
            name = "crosstool_has_neon",
            enabled = api_level >= 23,
        ),
        feature(
            name = "crosstool_needs_stackrealign",
            enabled = api_level < 24,
        ),
        feature(
            name = "do_not_split_linking_cmdline",
        ),
        feature(
            name = "crosstool_needs_memmove_fix",
            enabled = api_level < 21,
        ),
        feature(
            name = "crosstool_linker_gold",
            provides = ["variant:crosstool_linker"],
            enabled = False,
        ),
        feature(
            name = "crosstool_linker_lld",
            provides = ["variant:crosstool_linker"],
            enabled = True,
        ),
        feature(
            name = "proto_force_lite_runtime",
            implies = ["proto_disable_services"],
            enabled = True,
        ),
        feature(
            name = "proto_disable_services",
            enabled = True,
        ),
        feature(
            name = "proto_one_output_per_message",
            implies = ["proto_force_lite_runtime"],
            enabled = True,
            requires = [feature_set(features = ["opt"])],
        ),
        # Allows disabling nolegacy_whole_archive for individual targets. Automatically turned on
        # for cc_proto_library targets, but requires proto_one_output_per_message
        feature(
            name = "disable_whole_archive_for_static_lib",
            requires = [feature_set(features = ["proto_one_output_per_message"])],
        ),
        # These 3 features will be automatically enabled by bazel in the
        # corresponding build mode.
        feature(
            name = "opt",
            provides = ["variant:crosstool_build_mode"],
        ),
        feature(
            name = "dbg",
            provides = ["variant:crosstool_build_mode"],
        ),
        feature(
            name = "fastbuild",
            provides = ["variant:crosstool_build_mode"],
        ),
        # User-settable strip features
        feature(
            # --strip-all for .stripped binaries
            name = "fully_strip",  # --strip-all for strip=always
            enabled = True,
            requires = [feature_set(features = ["opt"])],  # Only fully strip in opt mode.
        ),
        feature(
            # --strip-all for --strip=always
            name = "linker_fully_strip",
            requires = [feature_set(features = ["opt"])],  # Only fully strip in opt mode.
        ),
        feature(name = "lto_unit"),

        # This reduces bitcode compatibility issues.
        feature(
            name = "no_use_lto_indexing_bitcode_file",
            enabled = True,
        ),
        feature(
            name = "thin_lto",
            flag_sets = [
                flag_set(
                    actions = [
                        action.c_compile,
                        action.cpp_compile,
                        action.cpp_link_dynamic_library,
                        action.cpp_link_nodeps_dynamic_library,
                        action.cpp_link_executable,
                    ],
                    flag_groups = [
                        flag_group(flags = ["-flto=thin"]),
                        flag_group(
                            expand_if_available = "lto_indexing_bitcode_file",
                            flags = [
                                "-Xclang",
                                "-fthin-link-bitcode=%{lto_indexing_bitcode_file}",
                            ],
                        ),
                    ],
                ),
                flag_set(
                    actions = [action.c_compile, action.cpp_compile],
                    with_features = [with_feature_set(not_features = ["lto_unit"])],
                    flag_groups = [flag_group(flags = ["-Xclang", "-fno-lto-unit"])],
                ),
                flag_set(
                    actions = [action.linkstamp_compile],
                    flag_groups = [flag_group(flags = ["-DBUILD_LTO_TYPE=thin"])],
                ),
                flag_set(
                    actions = actions.lto_index,
                    flag_groups = [
                        flag_group(flags = [
                            # No need to mark flags for Clang -- this action only runs Clang.
                            "-flto=thin",
                            "-Wl,-plugin-opt,thinlto-index-only%{thinlto_optional_params_file}",
                            "-Wl,-plugin-opt,thinlto-emit-imports-files",
                            "-Wl,-plugin-opt,thinlto-prefix-replace=%{thinlto_prefix_replace}",
                        ]),
                        flag_group(
                            expand_if_available = "thinlto_object_suffix_replace",
                            flags = [
                                "-Wl,-plugin-opt,thinlto-object-suffix-replace=%{thinlto_object_suffix_replace}",
                            ],
                        ),
                        flag_group(
                            expand_if_available = "thinlto_merged_object_file",
                            flags = [
                                "-Wl,-plugin-opt,obj-path=%{thinlto_merged_object_file}",
                            ],
                        ),
                    ],
                ),
                flag_set(
                    actions = [action.lto_backend],
                    flag_groups = [
                        flag_group(flags = [
                            # No need to mark flags for Clang -- this action only runs Clang.
                            "-c",
                            "-fthinlto-index=%{thinlto_index}",
                            "-o",
                            "%{thinlto_output_object_file}",
                            "-x",
                            "ir",
                            "%{thinlto_input_bitcode_file}",
                        ]),
                    ],
                ),
            ],
        ),
        feature(name = "thin_lto_linkstatic_tests_use_shared_nonlto_backends"),
        feature(name = "thin_lto_all_linkstatic_use_shared_nonlto_backends"),

        # User-settable features for sanitizer modes
        feature(name = "asan"),
        feature(
            name = "hwasan",
            enabled = config.get("use_hwasan", False),
        ),
        feature(name = "ubsan"),

        # User-settable features to control optimization level
        feature(
            # -O3 for all compilation actions
            name = "android_optimize_for_speed",
            requires = [feature_set(features = ["opt"])],  # Only use -O3 in opt mode.
        ),

        # By default, we build with unwind tables, but for folks who are not using
        # exceptions, and who are willing to sacrifice stack traces for size, they can
        # disable this feature.
        feature(
            name = "android_unwind_tables",
            enabled = True,
        ),

        # User-settable feature controls warning aggressiveness for compilation.
        feature(name = "warnings_as_errors"),

        # Configure the header parsing and preprocessing. Blaze will test to see if
        # the Crosstool supports it if the cc_toolchain specifies
        # supports_header_parsing = True.
        feature(name = "parse_headers"),

        # We have different features for module consumers and producers:
        # 'header_modules' is enabled for targets that support being compiled as a
        # header module.
        # 'use_header_modules' is enabled for targets that want to use the provided
        # header modules from their transitive closure. We enable this globally and
        # disable it for targets that do not support builds with header modules.
        feature(
            name = "header_modules",
            requires = [
                feature_set(features = ["use_header_modules"]),
            ],
            implies = [
                "header_module_compile",
            ],
        ),
        feature(
            name = "header_module_codegen",
            requires = [
                feature_set(features = ["header_modules"]),
            ],
        ),
        feature(
            name = "header_modules_codegen_functions",
            implies = ["header_module_codegen"],
        ),
        feature(
            name = "header_modules_codegen_debuginfo",
            implies = ["header_module_codegen"],
        ),
        feature(
            name = "header_module_compile",
        ),
        feature(
            name = "use_header_modules",
            implies = ["use_module_maps"],
        ),
        feature(
            name = "use_module_maps",
            requires = [feature_set(features = ["module_maps"])],
        ),
        feature(
            name = "module_maps",
            implies = [
                "module_map_home_cwd",
                "module_map_without_extern_module",
                "generate_submodules",
            ],
        ),
        feature(name = "module_map_home_cwd"),
        feature(name = "module_map_without_extern_module"),

        # Indicate that the crosstool supports submodules.
        feature(name = "generate_submodules"),

        # Configure the strict layering check.
        feature(
            name = "layering_check",
            implies = [
                "use_module_maps",
            ],
        ),

        # Disallow undefined symbols in final shared objects.
        feature(
            name = "no_undefined",
            enabled = True,
        ),

        # The following flag_set list defines the crucial set of flag_sets for primary
        # compilation and linking. Its order is incredibly important.
        feature(
            name = "crosstool_compiler_flags",
            enabled = True,
            flag_sets = [
                # Compile, Link, and CC_FLAGS make variable
                flag_set(
                    actions = actions.all_compile_and_link + actions.cc_flags_make_variable,
                    flags = [
                        "-no-canonical-prefixes",
                        "--target=%s%d" % (target_system_name, api_level),
                    ],
                ),
                # Compile + Link
                flag_set(
                    actions = actions.all_compile_and_link,
                    # This forces color diagnostics even on Forge (where we don't have an
                    # attached terminal).
                    flags = ["-fdiagnostics-color"],
                ),
                # These flags are used to enfore the NX (no execute) security feature
                # in the generated machine code. This adds a special section to the
                # generated shared libraries that instruct the Linux kernel to disable
                # code execution from the stack and the heap.
                flag_set(
                    actions = actions.all_compile,
                    flags = ["-Wa,--noexecstack"],
                ),
                flag_set(
                    actions = actions.all_link,
                    flags = ["-Wl,-z,noexecstack"],
                ),
                flag_set(
                    actions = actions.all_link,
                    flags = ["-Wl,-zseparate-code", "-Wl,--no-rosegment"],
                    features = ["crosstool_linker_lld"],
                ),
                # C++ compiles
                flag_set(
                    actions = actions.all_cpp_compile,
                    flags = [
                        "-std=gnu++17",
                        "-Wc++2a-extensions",
                        "-Woverloaded-virtual",
                        "-Wnon-virtual-dtor",
                        "-Wno-deprecated",
                        "-fshow-overloads=best",
                        "-Wdeprecated-increment-bool",
                        "-Wimplicit-fallthrough",
                        "-Wno-final-dtor-non-final-class",
                        "-Wno-dynamic-exception-spec",
                    ],
                ),
                # All compiles
                flag_set(
                    actions = actions.all_compile,
                    flags = [
                        "-faddrsig",
                        "-faligned-new",
                        "-fdata-sections",
                        "-ffunction-sections",
                        "-funsigned-char",
                        "-fstack-protector",
                        "-g",
                    ],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = [
                        "-funwind-tables",
                    ],
                    features = ["android_unwind_tables"],
                ),

                ## Options for particular compile modes:

                # OPT-specific flags
                flag_set(
                    actions = actions.preprocessor_compile,
                    flags = ["-DNDEBUG"],
                    features = ["opt"],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = [
                        "-fno-strict-aliasing",
                        "-fomit-frame-pointer",
                        "-g0",
                    ],
                    features = ["opt"],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = [
                        "-Oz",
                    ],
                    features = ["opt"],
                    not_features = ["android_optimize_for_speed"],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = [
                        "-O3",
                    ],
                    features = ["opt", "android_optimize_for_speed"],
                ),
                flag_set(
                    actions = actions.all_cpp_compile,
                    flags = ["-fvisibility-inlines-hidden"],
                    features = ["opt"],
                ),

                # DBG-specific flags
                flag_set(
                    actions = actions.all_compile,
                    flags = [
                        "-O0",
                        "-fno-omit-frame-pointer",
                        "-fno-strict-aliasing",
                    ],
                    features = ["dbg"],
                ),

                ## NDK-version specific options
                flag_set(
                    actions = actions.preprocessor_compile,
                    # The clang shipped with NDK r15 is a pre-release Clang 5.0
                    # binary, which has a buggy "clang::xray_log_args" that
                    # doesn't work on the 'implicit this' argument of a class
                    # method. It was fixed in llvm svn r305544.
                    flags = ["-DABSL_NO_XRAY_ATTRIBUTES"],
                    features = ["crosstool_disable_xray"],
                ),

                ## CPU-specific options

                # ARM options
                flag_set(
                    actions = actions.all_compile,
                    flags = ["-march=armv7-a", "-mfloat-abi=softfp"],
                    features = ["crosstool_cpu_arm"],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = ["-mfpu=vfpv3-d16"],
                    features = ["crosstool_cpu_arm"],
                    not_features = ["crosstool_has_neon"],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = ["-mfpu=neon"],
                    features = ["crosstool_cpu_arm", "crosstool_has_neon"],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = ["-mthumb"],
                    features = ["crosstool_cpu_arm", "opt"],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = ["-marm"],
                    features = ["crosstool_cpu_arm", "dbg"],
                ),
                flag_set(
                    actions = actions.all_link,
                    flags = ["-Wl,--fix-cortex-a8", "-march=armv7-a"],
                    features = ["crosstool_cpu_arm"],
                ),
                flag_set(
                    actions = actions.all_link,
                    flags = ["-Wl,-z,max-page-size=4096"],
                    features = ["crosstool_cpu_arm64", "crosstool_linker_lld"],
                ),

                # X86 options
                flag_set(
                    actions = actions.all_compile,
                    flags = ["-mstackrealign"],
                    features = ["crosstool_cpu_x86", "crosstool_needs_stackrealign"],
                ),

                ## Warning flag sets
                flag_set(
                    actions = actions.all_compile,
                    flags = ["-Werror"],
                    features = ["warnings_as_errors"],
                ),

                # Generic warning flag list
                flag_set(
                    actions = actions.all_compile,
                    flags = [
                        "-Wall",
                        "-Wformat-security",
                        "-Wno-char-subscripts",
                        "-Wno-error=deprecated-declarations",
                        "-Wno-maybe-uninitialized",
                        "-Wno-sign-compare",
                        "-Wno-strict-overflow",
                        "-Wno-unused-but-set-variable",
                        "-Wunused-but-set-parameter",
                        "-Wno-unknown-warning-option",
                        "-Wno-unused-command-line-argument",
                        "-Wno-ignored-optimization-argument",

                        # Disable some broken warnings from Clang.
                        "-Wno-ambiguous-member-template",
                        "-Wno-char-subscripts",
                        "-Wno-error=deprecated-declarations",
                        "-Wno-extern-c-compat",
                        "-Wno-gnu-alignof-expression",
                        "-Wno-gnu-variable-sized-type-not-at-end",
                        "-Wno-implicit-int-float-conversion",
                        "-Wno-invalid-source-encoding",
                        "-Wno-mismatched-tags",
                        "-Wno-pointer-sign",
                        "-Wno-private-header",
                        "-Wno-sign-compare",
                        "-Wno-signed-unsigned-wchar",
                        "-Wno-strict-overflow",
                        "-Wno-trigraphs",
                        "-Wno-unknown-pragmas",
                        "-Wno-unused-const-variable",
                        "-Wno-unused-function",
                        "-Wno-unused-private-field",
                        "-Wno-user-defined-warnings",

                        # Low SNR or otherwise not desirable.
                        "-Wno-extern-c-compat",
                        "-Wno-gnu-alignof-expression",
                        "-Wno-gnu-designator",
                        "-Wno-gnu-variable-sized-type-not-at-end",
                        "-Wno-invalid-source-encoding",
                        "-Wno-mismatched-tags",
                        "-Wno-reserved-user-defined-literal",
                        "-Wno-return-type-c-linkage",
                        "-Wno-self-assign-overloaded",
                        "-Wno-tautological-constant-in-range-compare",
                        "-Wno-unknown-pragmas",
                        "-Wfloat-overflow-conversion",
                        "-Wfloat-zero-conversion",
                        "-Wfor-loop-analysis",
                        "-Wgnu-redeclared-enum",
                        "-Winfinite-recursion",
                        "-Wliteral-conversion",
                        "-Wself-assign",
                        "-Wstring-conversion",
                        "-Wtautological-overlap-compare",
                        "-Wunused-comparison",
                        "-Wvla",

                        # Turn on thread safety analysis.
                        "-Wthread-safety-analysis",
                    ],
                ),

                # C++-specific warning flags
                flag_set(
                    actions = actions.all_cpp_compile,
                    flags = [
                        "-Wno-deprecated",
                        "-Wdeprecated-increment-bool",
                        "-Wnon-virtual-dtor",
                        "-Woverloaded-virtual",
                    ],
                ),

                # Defines and Includes and Paths and such
                flag_set(
                    actions = actions.all_compile,
                    flag_groups = [
                        flag_group(flags = ["-fPIC"]),
                    ],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-gsplit-dwarf", "-g"],
                            expand_if_available = "per_object_debug_info_file",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.preprocessor_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-D%{preprocessor_defines}"],
                            iterate_over = "preprocessor_defines",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.preprocessor_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-include", "%{includes}"],
                            iterate_over = "includes",
                            expand_if_available = "includes",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.preprocessor_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-iquote", "%{quote_include_paths}"],
                            iterate_over = "quote_include_paths",
                        ),
                        flag_group(
                            flags = ["-I%{include_paths}"],
                            iterate_over = "include_paths",
                        ),
                        flag_group(
                            flags = ["-isystem", "%{system_include_paths}"],
                            iterate_over = "system_include_paths",
                        ),
                    ],
                ),

                ## Linking options (not libs -- those go last)

                # Generic link options
                flag_set(
                    actions = actions.all_link,
                    flags = [
                        "-Wl,--gc-sections",
                        # Never re-export libgcc.a symbols.
                        "-Wl,--exclude-libs,libgcc.a",
                        "-Wl,--build-id=md5",
                        # Force JNI symbols to be linked.
                        "-Wl,--undefined-glob='Java_*'",
                        "-Wl,--undefined-glob='JNI_*'",
                    ],
                ),
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-Wl,--print-symbol-counts=%{symbol_counts_output}"],
                            expand_if_available = "symbol_counts_output",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-Wl,--gdb-index"],
                            expand_if_available = "is_using_fission",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-Wl,-s"],
                            expand_if_available = "strip_debug_symbols",
                        ),
                    ],
                    with_features = [with_feature_set(features = ["linker_fully_strip"])],
                ),
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-Wl,-S"],
                            expand_if_available = "strip_debug_symbols",
                        ),
                    ],
                    with_features = [with_feature_set(not_features = ["linker_fully_strip"])],
                ),
                flag_set(
                    actions = [action.cpp_link_executable],
                    flags = ["-pie"],
                ),
                flag_set(
                    # Dynamic Link Actions only:
                    actions = [
                        action.cpp_link_dynamic_library,
                        action.cpp_link_nodeps_dynamic_library,
                        action.lto_index_for_dynamic_library,
                        action.lto_index_for_nodeps_dynamic_library,
                    ],
                    # In API >= 23, having a TEXTREL section will stop the system
                    # from loading the so. Catch this at link time.
                    flags = ["-shared", "-Wl,-z,text"],
                ),
                flag_set(
                    actions = actions.all_link,
                    # Never re-export libunwind.a symbols.
                    flags = ["-Wl,--exclude-libs,libunwind.a"],
                ),

                # LLD/Gold specific linking options
                flag_set(
                    actions = actions.all_link,
                    flags = ["-fuse-ld=gold"],
                    features = ["crosstool_linker_gold"],
                ),
                flag_set(
                    actions = actions.all_link,
                    flags = ["-fuse-ld=lld"],
                    features = ["crosstool_linker_lld"],
                ),
                flag_set(
                    actions = actions.all_link,
                    flags = ["-Wl,--icf=safe"],
                    features = ["opt"],
                ),

                # Sanitizer options
                flag_set(
                    actions = actions.all_compile,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-O1",
                                "-gmlt",

                                # All failed checks are fatal.
                                "-fno-sanitize-recover=all",

                                # Disable Heap Checker.
                                "-DHEAPCHECK_DISABLE",
                                "-fno-omit-frame-pointer",
                            ],
                        ),
                    ],
                    with_features = [
                        with_feature_set(features = ["asan"]),
                        with_feature_set(features = ["ubsan"]),
                    ],
                ),
                flag_set(
                    actions = actions.all_link,
                    # Unconditionally link the C++ runtime (even for C-only builds).
                    flag_groups = [flag_group(flags = ["-fsanitize-link-c++-runtime"])],
                    with_features = [
                        with_feature_set(features = ["asan"]),
                        with_feature_set(features = ["ubsan"]),
                    ],
                ),
                flag_set(
                    # For executables only -- link statically.
                    actions = [action.cpp_link_executable],
                    flag_groups = [flag_group(flags = ["-static-libsan"])],
                    with_features = [
                        with_feature_set(features = ["asan"]),
                        with_feature_set(features = ["ubsan"]),
                    ],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = [
                        "-fsanitize=address",

                        # Allow code to detect that it is being run under sanitizer.
                        "-DADDRESS_SANITIZER",
                        "-D_GLIBCXX_ADDRESS_SANITIZER_ANNOTATIONS",
                        "-fsanitize-address-use-after-scope",
                    ],
                    features = ["asan"],
                ),
                flag_set(
                    actions = actions.all_link,
                    flags = ["-fsanitize=address"],
                    features = ["asan"],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flags = [
                        "-fsanitize=undefined",
                        # Due to lack of runtimes in NDK, only operate in TRAP mode.
                        "-fsanitize-trap=undefined",
                        # NDK doesn't support this yet https://github.com/android-ndk/ndk/issues/184
                        "-fno-sanitize=signed-integer-overflow",
                    ],
                    features = ["ubsan"],
                ),
                flag_set(
                    actions = actions.all_link,
                    flags = [
                        "-fsanitize=undefined",
                        # Due to lack of runtimes in NDK, only operate in TRAP mode.
                        "-fsanitize-trap=undefined",
                    ],
                    features = ["ubsan"],
                ),
                flag_set(
                    actions = actions.all_compile_and_link,
                    flags = [
                        "-fsanitize=hwaddress",
                        "-fsanitize-hwaddress-abi=platform",
                    ],
                    features = ["hwasan"],
                ),

                # Linker search paths and objects:
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-L%{library_search_directories}"],
                            iterate_over = "library_search_directories",
                            expand_if_available = "library_search_directories",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            # This is actually a list of object files from the linkstamp steps
                            flags = ["%{linkstamp_paths}"],
                            iterate_over = "linkstamp_paths",
                            expand_if_available = "linkstamp_paths",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-Wl,@%{thinlto_param_file}"],
                            expand_if_available = "libraries_to_link",
                            expand_if_true = "thinlto_param_file",
                        ),
                        flag_group(
                            iterate_over = "libraries_to_link",
                            flag_groups = [
                                flag_group(
                                    flags = ["-Wl,--start-lib"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "object_file_group",
                                    ),
                                    expand_if_false = "libraries_to_link.is_whole_archive",
                                ),
                                flag_group(
                                    flags = ["-Wl,-whole-archive"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "static_library",
                                    ),
                                    expand_if_true = "libraries_to_link.is_whole_archive",
                                ),
                                flag_group(
                                    flags = ["%{libraries_to_link.object_files}"],
                                    iterate_over = "libraries_to_link.object_files",
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "object_file_group",
                                    ),
                                ),
                                flag_group(
                                    flags = ["%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "object_file",
                                    ),
                                ),
                                flag_group(
                                    flags = ["%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "interface_library",
                                    ),
                                ),
                                flag_group(
                                    flags = ["%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "static_library",
                                    ),
                                ),
                                flag_group(
                                    flags = ["-l%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "dynamic_library",
                                    ),
                                ),
                                flag_group(
                                    flags = ["-l:%{libraries_to_link.name}"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "versioned_dynamic_library",
                                    ),
                                ),
                                flag_group(
                                    flags = ["-Wl,-no-whole-archive"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "static_library",
                                    ),
                                    expand_if_true = "libraries_to_link.is_whole_archive",
                                ),
                                flag_group(
                                    flags = ["-Wl,--end-lib"],
                                    expand_if_equal = variable_with_value(
                                        name = "libraries_to_link.type",
                                        value = "object_file_group",
                                    ),
                                    expand_if_false = "libraries_to_link.is_whole_archive",
                                ),
                            ],
                            expand_if_available = "libraries_to_link",
                        ),
                    ],
                ),

                # Configure the header parsing and preprocessing.
                flag_set(
                    actions = [action.cpp_header_parsing],
                    flags = ["-xc++-header", "-fsyntax-only"],
                    features = ["parse_headers"],
                ),

                # Configure header module generation
                flag_set(
                    actions = [action.cpp_module_compile],
                    flags = [
                        "-fmodules-codegen",
                    ],
                    features = ["header_modules_codegen_functions"],
                ),
                flag_set(
                    actions = [action.cpp_module_compile],
                    flags = [
                        "-fmodules-debuginfo",
                    ],
                    features = ["header_modules_codegen_debuginfo"],
                ),
                flag_set(
                    actions = [action.cpp_module_compile],
                    flags = " ".join([
                        "-xc++",
                        "-Xclang -emit-module",
                        "-Xclang -fmodules-embed-all-files",
                        "-Xclang -fmodules-local-submodule-visibility",
                    ]).split(" "),
                    features = ["header_module_compile"],
                ),
                flag_set(
                    actions = [
                        action.cpp_compile,
                        action.cpp_header_parsing,
                        action.cpp_module_compile,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-fmodules",
                                "-fmodule-file-deps",
                                "-fno-implicit-modules",
                                "-fno-implicit-module-maps",
                                "-Wno-modules-ambiguous-internal-linkage",
                                "-Wno-module-import-in-extern-c",
                                "-Wno-modules-import-nested-redundant",
                            ],
                        ),
                        flag_group(
                            flags = ["-fmodule-file=%{module_files}"],
                            iterate_over = "module_files",
                        ),
                    ],
                    features = ["use_header_modules"],
                ),

                # Configure header module consumption.
                flag_set(
                    actions = [
                        action.c_compile,
                        action.cpp_compile,
                        action.cpp_header_parsing,
                        action.cpp_module_compile,
                    ],
                    features = ["module_map_home_cwd"],
                    flags = [
                        "-Xclang",
                        "-fmodule-map-file-home-is-cwd",
                    ],
                ),
                flag_set(
                    actions = [
                        action.c_compile,
                        action.cpp_compile,
                        action.cpp_header_parsing,
                        action.cpp_module_compile,
                    ],
                    features = ["use_module_maps"],
                    flag_groups = [
                        flag_group(
                            flags = ["-fmodule-name=%{module_name}"],
                            expand_if_available = "module_name",
                        ),
                        flag_group(
                            flags = ["-fmodule-map-file=%{module_map_file}"],
                            expand_if_available = "module_map_file",
                        ),
                    ],
                ),
                flag_set(
                    actions = [
                        action.c_compile,
                        action.cpp_compile,
                        action.cpp_header_parsing,
                        action.cpp_module_compile,
                    ],
                    features = ["layering_check"],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-fmodules-strict-decluse",
                                "-Wprivate-header",
                            ],
                        ),
                        flag_group(
                            flags = ["-fmodule-map-file=%{dependent_module_map_files}"],
                            iterate_over = "dependent_module_map_files",
                        ),
                    ],
                ),

                # Note: user compile flags should be nearly last -- you probably
                # don't want to put any more features after this!
                flag_set(
                    actions = actions.all_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["%{user_compile_flags}"],
                            iterate_over = "user_compile_flags",
                            expand_if_available = "user_compile_flags",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["%{user_link_flags}"],
                            iterate_over = "user_link_flags",
                            expand_if_available = "user_link_flags",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["%{legacy_link_flags}"],
                            iterate_over = "legacy_link_flags",
                            expand_if_available = "legacy_link_flags",
                        ),
                    ],
                ),

                ## Options which need to go late -- after all the user options -- go here.
                flag_set(
                    actions = actions.all_link,
                    # Override and turn off icf for ld.gold x86.
                    flags = ["-Wl,--icf=none"],
                    features = ["opt", "crosstool_linker_gold", "crosstool_cpu_x86"],
                ),

                # Hardcoded library link flags.
                flag_set(
                    actions = actions.all_full_link,
                    flags = ["-Wl,--no-undefined"],
                    features = ["no_undefined"],
                ),
                flag_set(
                    # We override memmove() on 32-bit arm targets.
                    # Also refer to README.md for information on how libmemmove.a is constructed.
                    actions = actions.all_link,
                    flags = ["-lmemmove"],
                    features = ["crosstool_cpu_arm", "crosstool_needs_memmove_fix"],
                ),
                flag_set(
                    actions = actions.all_link,
                    flags = ["-lc", "-lm", "-latomic", "-ldl"],
                ),
                # Inputs and outputs
                flag_set(
                    actions = actions.all_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-MD", "-MF", "%{dependency_file}"],
                            expand_if_available = "dependency_file",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-c", "%{source_file}"],
                            expand_if_available = "source_file",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.all_compile,
                    flag_groups = [
                        flag_group(
                            flags = ["-S"],
                            expand_if_available = "output_assembly_file",
                        ),
                        flag_group(
                            flags = ["-E"],
                            expand_if_available = "output_preprocess_file",
                        ),
                        flag_group(
                            flags = ["-o", "%{output_file}"],
                            expand_if_available = "output_file",
                        ),
                    ],
                ),
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["-o", "%{output_execpath}"],
                            expand_if_available = "output_execpath",
                        ),
                    ],
                ),
                # And finally, the params file!
                flag_set(
                    actions = actions.all_link,
                    flag_groups = [
                        flag_group(
                            flags = ["@%{linker_param_file}"],
                            expand_if_available = "linker_param_file",
                        ),
                    ],
                ),
            ],
        ),
    ]

    return dict(
        action_configs = action_configs,
        features = features,
        target_system_name = target_system_name,
        tool_paths = tool_paths,
        **config
    )

### Declare a rule to wrap the crosstool configuration.

def ndk_cc_toolchain_config_rule_implementation(ctx):
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        **ndk_cc_toolchain_config(
            api_level = ctx.attr.api_level,
            target_system_name = ctx.attr.target_system_name,
            tools = {
                "clang": "bin/clang",
                "ar": "bin/llvm-ar",
                "cpp": "bin/clang++",
                "dwp": "bin/llvm-dwp",
                "gcc": "bin/clang",
                "gcov": "bin/gcov",
                "ld": "bin/ld",
                "nm": "bin/llvm-nm",
                "objcopy": "bin/llvm-objcopy",
                "objdump": "bin/llvm-objdump",
                "strip": "bin/llvm-strip",
            },
            cxx_builtin_include_directories = [
                "sysroot/usr/include/c++/v1",
                "sysroot/usr/local/include",
                ctx.attr.clang_resource_directory,
                "sysroot/usr/include/%s" % ctx.attr.target_system_name,
                "sysroot/usr/include",
            ],
            toolchain_identifier = ctx.attr.toolchain_identifier,
            target_cpu = {
                "arm-linux-androideabi": "armeabi-v7a",
                "aarch64-linux-android": "arm64-v8a",
                "i686-linux-android": "x86",
                "x86_64-linux-android": "x86_64",
            }[ctx.attr.target_system_name],
            abi_version = ctx.attr.target_system_name,
            abi_libc_version = "18",
            artifact_name_patterns = [],
            cc_target_os = "android",
            compiler = "llvm-c++",
            make_variables = [],
            target_libc = "bionic",
        )
    )

ndk_cc_toolchain_config_rule = rule(
    implementation = ndk_cc_toolchain_config_rule_implementation,
    attrs = {
        "api_level": attr.int(mandatory = True),
        "clang_resource_directory": attr.string(mandatory = True),
        "target_system_name": attr.string(
            mandatory = True,
            values = [
                "arm-linux-androideabi",
                "aarch64-linux-android",
                "i686-linux-android",
                "x86_64-linux-android",
            ],
        ),
        "toolchain_identifier": attr.string(mandatory = True),
    },
)

### Helper functions.

def construct_actions_(action = action):
    """Return a struct of lists of action names."""
    return struct(
        all_compile = [
            action.c_compile,
            action.cpp_compile,
            action.lto_backend,
            action.linkstamp_compile,
            action.assemble,
            action.preprocess_assemble,
            action.cpp_header_parsing,
            action.cpp_module_compile,
            action.cpp_module_codegen,
            action.clif_match,
        ],
        all_compile_and_link = [
            action.c_compile,
            action.cpp_compile,
            action.lto_backend,
            action.linkstamp_compile,
            action.assemble,
            action.preprocess_assemble,
            action.cpp_header_parsing,
            action.cpp_module_compile,
            action.cpp_module_codegen,
            action.clif_match,
            action.cpp_link_executable,
            action.cpp_link_dynamic_library,
            action.cpp_link_nodeps_dynamic_library,
            action.lto_index_for_executable,
            action.lto_index_for_dynamic_library,
            action.lto_index_for_nodeps_dynamic_library,
        ],
        all_cpp_compile = [
            action.cpp_compile,
            action.lto_backend,
            action.linkstamp_compile,
            action.cpp_header_parsing,
            action.cpp_module_compile,
            action.cpp_module_codegen,
            action.clif_match,
        ],
        all_full_link = [
            action.cpp_link_executable,
            action.cpp_link_dynamic_library,
            action.lto_index_for_executable,
            action.lto_index_for_dynamic_library,
        ],
        all_link = [
            action.cpp_link_executable,
            action.cpp_link_dynamic_library,
            action.cpp_link_nodeps_dynamic_library,
            action.lto_index_for_executable,
            action.lto_index_for_dynamic_library,
            action.lto_index_for_nodeps_dynamic_library,
        ],
        cc_flags_make_variable = [action.cc_flags_make_variable],
        lto_index = [
            action.lto_index_for_executable,
            action.lto_index_for_dynamic_library,
            action.lto_index_for_nodeps_dynamic_library,
        ],
        preprocessor_compile = [
            action.c_compile,
            action.cpp_compile,
            action.linkstamp_compile,
            action.preprocess_assemble,
            action.cpp_header_parsing,
            action.cpp_module_compile,
            action.clif_match,
        ],
    )

def flag_set(flags = None, features = None, not_features = None, **kwargs):
    """Extension to flag_set which allows for a "simple" form.

    The simple form allows specifying flags as a simple list instead of a flag_group
    if enable_if or expand_if semantics are not required.

    Similarly, the simple form allows passing features/not_features if they are a simple
    list of semantically "and" features.
    (i.e. "asan" and "dbg", rather than "asan" or "dbg")

    Args:
      flags: list, set of flags
      features: list, set of features required to be enabled.
      not_features: list, set of features required to not be enabled.
      **kwargs: The rest of the args for flag_set.

    Returns:
      flag_set
    """
    if flags:
        if kwargs.get("flag_groups"):
            fail("Cannot set flags and flag_groups")
        else:
            kwargs["flag_groups"] = [flag_group(flags = flags)]

    if features or not_features:
        if kwargs.get("with_features"):
            fail("Cannot set features/not_feature and with_features")
        kwargs["with_features"] = [with_feature_set(
            features = features or [],
            not_features = not_features or [],
        )]
    return flag_set_(**kwargs)
