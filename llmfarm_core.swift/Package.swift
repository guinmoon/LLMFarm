// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "llmfarm_core.swift",
    platforms: [.macOS(.v11),.iOS(.v15)],
    products: [
        .library(
            name: "llmfarm_core",
            targets: ["llmfarm_core"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "llmfarm_core",
            sources: ["ggml.c","ggml-metal.m","k_quants.c", "gptneox/gptneox.cpp","gpt2/gpt2.cpp","replit/replit.cpp","starcoder/starcoder.cpp","common.cpp","gpt_helpers.cpp","gpt_spm.cpp", "llama/llama.cpp"],
            publicHeadersPath: "spm-headers",
//            I'm not sure about some of the flags, please correct it's wrong.
            cSettings: [
                .unsafeFlags(["-Ofast"]), //comment this if you need to Debug llama
                .unsafeFlags(["-DNDEBUG"]),
                //                .unsafeFlags(["-march=native"]),
//                                .unsafeFlags(["-mtune=native"]),
//                .unsafeFlags(["-mcpu=native"]),
                .unsafeFlags(["-mfma","-mfma","-mavx","-mavx2","-mf16c","-msse3"]),
                .unsafeFlags(["-DGGML_USE_K_QUANTS"]),
//                .unsafeFlags(["-DGGML_QKK_64"]),
                .unsafeFlags(["-DGGML_USE_ACCELERATE"]),
                .unsafeFlags(["-DGGML_USE_METAL"]),
//                .unsafeFlags(["-DExternalMetal"]),
                .unsafeFlags(["-DGGML_METAL_NDEBUG"]),
                .unsafeFlags(["-pthread"]),
                .unsafeFlags(["-w"])    // ignore all warnings
            ],
            cxxSettings: [
                .unsafeFlags(["-Ofast"]),
                .unsafeFlags(["-mfma","-mfma","-mavx","-mavx2","-mf16c","-msse3"]),
                .unsafeFlags(["-pthread"]),
                .unsafeFlags(["-w"])
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("MetalPerformanceShaders"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx20
)

