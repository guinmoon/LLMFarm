// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "llmfarm_core.swift",
    platforms: [.macOS(.v11),.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "llmfarm_core",
            targets: ["llmfarm_core"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "llmfarm_core",
            sources: ["ggml.c","llama/ggml-metal.m","k_quants.c", "gptneox/gptneox.cpp","gpt2/gpt2.cpp","replit/replit.cpp","common.cpp","gpt_helpers.cpp","gpt_spm.cpp", "llama/llama.cpp"],
            publicHeadersPath: "spm-headers",
//            I'm not sure about some of the flags, please correct it's wrong.
            cSettings: [
                .unsafeFlags(["-Ofast"]),
                .unsafeFlags(["-Wno-shorten-64-to-32"]),
                .unsafeFlags(["-DNDEBUG"]),
                //                .unsafeFlags(["-march=native"]),
//                                .unsafeFlags(["-mtune=native"]),
//                .unsafeFlags(["-mcpu=native"]),
                .unsafeFlags(["-mfma","-mfma","-mavx","-mavx2","-mf16c","-msse3"]),
                .unsafeFlags(["-DGGML_USE_K_QUANTS"]),
                //                .unsafeFlags(["-DGGML_QKK_64"]),
                .unsafeFlags(["-DGGML_USE_ACCELERATE"]),
                .unsafeFlags(["-DGGML_USE_METAL"]),
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
                //Frameworks
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

