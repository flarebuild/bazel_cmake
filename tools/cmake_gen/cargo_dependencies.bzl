"""
DO NOT EDIT!

This file is automatically @generated by blackjack.
"""
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def cargo_dependencies():


    http_archive(
        name = "crates_io_itoa_0.4.6",
        url = "https://crates.io/api/v1/crates/itoa/0.4.6/download",
        sha256 = "dc6f3ad7b9d11a0c00842ff8de1b60ee58661048eb8049ed33c73594f359d7e6",
        strip_prefix = "itoa-0.4.6",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "itoa",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "lib",
    deps = [],
    proc_macro_deps = [],
    edition = "2015",
    crate_features = [],
    rustc_flags = ["--cap-lints=allow"] + [],
    visibility = ["//visibility:public"],
)
    """,
    )
    

    http_archive(
        name = "crates_io_pico_args",
        url = "https://crates.io/api/v1/crates/pico-args/0.3.4/download",
        sha256 = "28b9b4df73455c861d7cbf8be42f01d3b373ed7f02e378d55fa84eafc6f638b1",
        strip_prefix = "pico-args-0.3.4",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "pico_args",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "lib",
    deps = [],
    proc_macro_deps = [],
    edition = "2018",
    crate_features = ["default", "eq-separator"],
    rustc_flags = ["--cap-lints=allow"] + [],
    visibility = ["//visibility:public"],
)
    """,
    )
    

    http_archive(
        name = "crates_io_proc_macro2_1.0.24",
        url = "https://crates.io/api/v1/crates/proc-macro2/1.0.24/download",
        sha256 = "1e0704ee1a7e00d7bb417d0770ea303c1bccbabf0ef1667dae92b5967f5f8a71",
        strip_prefix = "proc-macro2-1.0.24",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "proc_macro2",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "lib",
    deps = ["@crates_io_unicode_xid_0.2.1//:unicode_xid"],
    proc_macro_deps = [],
    edition = "2018",
    crate_features = ["default", "proc-macro"],
    rustc_flags = ["--cap-lints=allow"] + ["--cfg=use_proc_macro"],
    visibility = ["//visibility:public"],
)
    """,
    )
    

    http_archive(
        name = "crates_io_quote_1.0.7",
        url = "https://crates.io/api/v1/crates/quote/1.0.7/download",
        sha256 = "aa563d17ecb180e500da1cfd2b028310ac758de548efdd203e18f283af693f37",
        strip_prefix = "quote-1.0.7",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "quote",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "lib",
    deps = ["@crates_io_proc_macro2_1.0.24//:proc_macro2"],
    proc_macro_deps = [],
    edition = "2018",
    crate_features = ["default", "proc-macro"],
    rustc_flags = ["--cap-lints=allow"] + [],
    visibility = ["//visibility:public"],
)
    """,
    )
    

    http_archive(
        name = "crates_io_ryu_1.0.5",
        url = "https://crates.io/api/v1/crates/ryu/1.0.5/download",
        sha256 = "71d301d4193d031abdd79ff7e3dd721168a9572ef3fe51a1517aba235bd8f86e",
        strip_prefix = "ryu-1.0.5",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "ryu",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "lib",
    deps = [],
    proc_macro_deps = [],
    edition = "2018",
    crate_features = [],
    rustc_flags = ["--cap-lints=allow"] + [],
    visibility = ["//visibility:public"],
)
    """,
    )
    

    http_archive(
        name = "crates_io_serde",
        url = "https://crates.io/api/v1/crates/serde/1.0.117/download",
        sha256 = "b88fa983de7720629c9387e9f517353ed404164b1e482c970a90c1a4aaf7dc1a",
        strip_prefix = "serde-1.0.117",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "serde",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "lib",
    deps = [],
    proc_macro_deps = ["@crates_io_serde_derive_1.0.117//:serde_derive"],
    edition = "2015",
    crate_features = ["default", "derive", "serde_derive", "std"],
    rustc_flags = ["--cap-lints=allow"] + [],
    visibility = ["//visibility:public"],
)
    """,
    )
    

    http_archive(
        name = "crates_io_serde_derive_1.0.117",
        url = "https://crates.io/api/v1/crates/serde_derive/1.0.117/download",
        sha256 = "cbd1ae72adb44aab48f325a02444a5fc079349a8d804c1fc922aed3f7454c74e",
        strip_prefix = "serde_derive-1.0.117",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "serde_derive",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "proc-macro",
    deps = ["@crates_io_proc_macro2_1.0.24//:proc_macro2", "@crates_io_quote_1.0.7//:quote", "@crates_io_syn_1.0.46//:syn"],
    proc_macro_deps = [],
    edition = "2015",
    crate_features = ["default"],
    rustc_flags = ["--cap-lints=allow"] + [],
    visibility = ["//visibility:public"],
)
    """,
    )
    

    http_archive(
        name = "crates_io_serde_json",
        url = "https://crates.io/api/v1/crates/serde_json/1.0.59/download",
        sha256 = "dcac07dbffa1c65e7f816ab9eba78eb142c6d44410f4eeba1e26e4f5dfa56b95",
        strip_prefix = "serde_json-1.0.59",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "serde_json",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "lib",
    deps = ["@crates_io_itoa_0.4.6//:itoa", "@crates_io_ryu_1.0.5//:ryu", "@crates_io_serde//:serde"],
    proc_macro_deps = [],
    edition = "2018",
    crate_features = ["default", "std"],
    rustc_flags = ["--cap-lints=allow"] + [],
    visibility = ["//visibility:public"],
)
    """,
    )
    

    http_archive(
        name = "crates_io_syn_1.0.46",
        url = "https://crates.io/api/v1/crates/syn/1.0.46/download",
        sha256 = "5ad5de3220ea04da322618ded2c42233d02baca219d6f160a3e9c87cda16c942",
        strip_prefix = "syn-1.0.46",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "syn",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "lib",
    deps = ["@crates_io_proc_macro2_1.0.24//:proc_macro2", "@crates_io_quote_1.0.7//:quote", "@crates_io_unicode_xid_0.2.1//:unicode_xid"],
    proc_macro_deps = [],
    edition = "2018",
    crate_features = ["clone-impls", "default", "derive", "parsing", "printing", "proc-macro", "quote", "visit"],
    rustc_flags = ["--cap-lints=allow"] + [],
    visibility = ["//visibility:public"],
)
    """,
    )
    

    http_archive(
        name = "crates_io_unicode_xid_0.2.1",
        url = "https://crates.io/api/v1/crates/unicode-xid/0.2.1/download",
        sha256 = "f7fe0bb3479651439c9112f72b6c505038574c9fbb575ed1bf3b797fa39dd564",
        strip_prefix = "unicode-xid-0.2.1",
        type = "tar.gz",
        build_file_content = """
load("@io_bazel_rules_rust//rust:rust.bzl", "rust_library")

rust_library(
    name = "unicode_xid",
    aliases = {},
    srcs = glob(["**/*.rs"]),
    crate_type = "lib",
    deps = [],
    proc_macro_deps = [],
    edition = "2015",
    crate_features = ["default"],
    rustc_flags = ["--cap-lints=allow"] + [],
    visibility = ["//visibility:public"],
)
    """,
    )
    