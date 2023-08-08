// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "llmfarm_core",
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
              dependencies: ["llmfarm_core_cpp"],
              path: "Sources/llmfarm_core"),
        .target(
            name: "llmfarm_core_cpp",
            sources: ["ggml.c","ggml_old.c","ggml-metal.m","k_quants.c","common.cpp","gpt_helpers.cpp","gpt_spm.cpp","package_helper.m",
                      "gptneox/gptneox.cpp","gpt2/gpt2.cpp","replit/replit.cpp","starcoder/starcoder.cpp", "llama/llama.cpp","rwkv/rwkv.cpp",
                      ],
            resources: [
                .copy("tokenizers")
            ],
            publicHeadersPath: "spm-headers",
            //            I'm not sure about some of the flags, please correct it's wrong.
            cSettings: [
                .unsafeFlags(["-Ofast"]), //comment this if you need to Debug llama_cpp
                .unsafeFlags(["-DNDEBUG"]),
                .unsafeFlags(["-mfma","-mfma","-mavx","-mavx2","-mf16c","-msse3"]), //for Intel CPU
                .unsafeFlags(["-DGGML_METAL_NDEBUG"]),
                .unsafeFlags(["-DGGML_USE_ACCELERATE"]),
                .unsafeFlags(["-DGGML_USE_METAL"]),
                .unsafeFlags(["-DGGML_USE_K_QUANTS"]),
                .unsafeFlags(["-pthread"]),
                .unsafeFlags(["-w"]),    // ignore all warnings
                //                .unsafeFlags(["-DGGML_QKK_64"]), // Dont forget to comment this if you dont use QKK_64
                //                .unsafeFlags(["-DExternalMetal"]), // this flag for ModelTest with Metal
                
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

