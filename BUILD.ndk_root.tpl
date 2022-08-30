"""Top-level aliases."""

package(default_visibility = ["//visibility:public"])

alias(
    name = "toolchain",
    actual = "//{clang_directory}:cc_toolchain_suite",
)
