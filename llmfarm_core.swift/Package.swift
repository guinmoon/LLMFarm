// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//#if os(macOS)
//#if (arch(i386) || arch(x86_64))
let package = Package(
    name: "llmfarm_core.swift",
    platforms: [.macOS(.v11)],
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
            sources: ["ggml.c","k_quants.c", "gptneox/gptneox.cpp","gpt2/gpt2.cpp","replit/replit.cpp","common.cpp","gpt_helpers.cpp","gpt_spm.cpp", "llama/llama.cpp", "llama/ggml-metal.m"],
            publicHeadersPath: "spm-headers",
            cSettings: [
                .unsafeFlags(["-O3"]),
                .unsafeFlags(["-Wno-shorten-64-to-32"]),
                .unsafeFlags(["-DNDEBUG"]),
                //                .unsafeFlags(["-march=native"]),
//                                .unsafeFlags(["-mtune=native"]),
                .unsafeFlags(["-mfma","-mfma","-mavx","-mavx2","-mf16c","-msse3"]),
//                .unsafeFlags(["-mfma"]),
//                .unsafeFlags(["-mavx"]),
//                .unsafeFlags(["-mavx2"]),
//                .unsafeFlags(["-mf16c"]),
//                .unsafeFlags(["-msse3"]),
                .unsafeFlags(["-DGGML_USE_ACCELERATE"]),
                .unsafeFlags(["-DGGML_USE_K_QUANTS"]),
//                .unsafeFlags(["-DGGML_USE_METAL"]),
//                .unsafeFlags(["-DGGML_METAL_NDEBUG"]),
                .unsafeFlags(["-Wall"]),
                .unsafeFlags(["-Wpedantic"]),
                .unsafeFlags(["-Wcast-qual"]),
                .unsafeFlags(["-Wdouble-promotion"]),
                .unsafeFlags(["-Wshadow"]),
                .unsafeFlags(["-Wstrict-prototypes"]),
                .unsafeFlags(["-Wpointer-arith"]),
                .unsafeFlags(["-Wno-unused-function"]),
                .unsafeFlags(["-Wno-multichar"]),
                .unsafeFlags(["-w"])    // ignore all warnings
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
    cLanguageStandard: .gnu18,
    cxxLanguageStandard: .gnucxx20
)

//#else
//let package = Package(
//    name: "llmfarm_core.swift",
//    platforms: [.macOS(.v11)],
//    products: [
//        // Products define the executables and libraries a package produces, and make them visible to other packages.
//        .library(
//            name: "llmfarm_core",
//            targets: ["llmfarm_core"]),
//    ],
//    dependencies: [
//        // Dependencies declare other packages that this package depends on.
//        // .package(url: /* package url */, from: "1.0.0"),
//    ],
//    targets: [
//        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
//        // Targets can depend on other targets in this package, and on products in packages this package depends on.
//        .target(
//            name: "llmfarm_core",
//            sources: ["ggml.c", "gptneox/gptneox.cpp","gpt2/gpt2.cpp","replit/replit.cpp","common.cpp","gpt_helpers.cpp","gpt_spm.cpp", "llama/llama.cpp", ],
//            //            sources: ["ggml.c", "gptneox/gptneox.cpp","gptneox/gptneox_new.cpp","gptneox/common.cpp", "llama.cpp"],
//            publicHeadersPath: "spm-headers",
//            cSettings: [
//                .unsafeFlags(["-O3"]),
//                .unsafeFlags(["-DNDEBUG"]),
//                .unsafeFlags(["-mcpu=native"]),
//                .unsafeFlags(["-Wno-shorten-64-to-32"]),
//                .unsafeFlags(["-DGGML_USE_ACCELERATE"]),
//                .unsafeFlags(["-w"])    // ignore all warnings
//            ]),
//    ],
//    cLanguageStandard: .gnu18,
//    cxxLanguageStandard: .gnucxx20
//)
//#endif

//#elseif os(iOS)
//let package = Package(
//    name: "llmfarm_core.swift",
//    platforms: [.iOS(.v15)],
//    products: [
//        // Products define the executables and libraries a package produces, and make them visible to other packages.
//        .library(
//            name: "llmfarm_core",
//            targets: ["llmfarm_core"]),
//    ],
//    dependencies: [
//        // Dependencies declare other packages that this package depends on.
//        // .package(url: /* package url */, from: "1.0.0"),
//    ],
//    targets: [
//        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
//        // Targets can depend on other targets in this package, and on products in packages this package depends on.
//        .target(
//            name: "llmfarm_core",
//            //            sources: ["ggml.c", "gptneox/gptneox.cpp","gptneox/gptneox_new.cpp","gptneox/common.cpp", "llama.cpp"],
//            exclude: ["llama/ggml-metal.metal","llama/ggml-metal.m"],
//            sources: ["ggml.c", "gptneox/gptneox.cpp","gpt2/gpt2.cpp","replit/replit.cpp","common.cpp","gpt_helpers.cpp","gpt_spm.cpp", "llama/llama.cpp"],
//            publicHeadersPath: "spm-headers",
//            cSettings: [
//                .unsafeFlags(["-O3"]),
//                .unsafeFlags(["-DNDEBUG"]),
//                .unsafeFlags(["-mcpu=native"]),
//                .unsafeFlags(["-Wno-shorten-64-to-32"]),
//                .unsafeFlags(["-msse3"]),
//                .unsafeFlags(["-DGGML_USE_ACCELERATE"]),
//                .unsafeFlags(["-w"])    // ignore all warnings
//            ],
//            linkerSettings: [
//                //Frameworks
//                .linkedFramework("Foundation"),
//                .linkedFramework("Accelerate"),
////                .linkedFramework("Metal"),
////                .linkedFramework("MetalKit"),
////                .linkedFramework("MetalPerformanceShaders"),
//            ]
//
//        ),
//    ],
//    cLanguageStandard: .gnu18,
//    cxxLanguageStandard: .gnucxx20
//)
//
//
