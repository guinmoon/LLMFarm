// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if  os(macOS)

#if (arch(i386) || arch(x86_64))
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
            sources: ["ggml.c", "gptneox/gptneox.cpp","gpt2/gpt2.cpp","common.cpp","gpt_helpers.cpp","gpt_spm.cpp", "llama/llama.cpp"],
            //            sources: ["ggml.c", "gptneox/gptneox.cpp","gptneox/gptneox_new.cpp","gptneox/common.cpp", "llama.cpp"],
            publicHeadersPath: "spm-headers",
            cSettings: [
                .unsafeFlags(["-O3"]),
                .unsafeFlags(["-DNDEBUG"]),
                //                .unsafeFlags(["-march=native"]),
                //                .unsafeFlags(["-mtune=native"]),
                    .unsafeFlags(["-mfma"]),
                .unsafeFlags(["-mavx"]),
                .unsafeFlags(["-mavx2"]),
                .unsafeFlags(["-mf16c"]),
                .unsafeFlags(["-msse3"]),
                .unsafeFlags(["-DGGML_USE_ACCELERATE"]),
                .unsafeFlags(["-w"])    // ignore all warnings
            ]),
    ],
    cLanguageStandard: .gnu11,
    cxxLanguageStandard: .gnucxx20
)
#else
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
            sources: ["ggml.c", "gptneox/gptneox.cpp","gpt2/gpt2.cpp","common.cpp","gpt_helpers.cpp","gpt_spm.cpp", "llama/llama.cpp", ],
            //            sources: ["ggml.c", "gptneox/gptneox.cpp","gptneox/gptneox_new.cpp","gptneox/common.cpp", "llama.cpp"],
            publicHeadersPath: "spm-headers",
            cSettings: [
                .unsafeFlags(["-O3"]),
                .unsafeFlags(["-DNDEBUG"]),
                .unsafeFlags(["-mcpu=native"]),
                .unsafeFlags(["-DGGML_USE_ACCELERATE"]),
                .unsafeFlags(["-w"])    // ignore all warnings
            ]),
    ],
    cLanguageStandard: .gnu11,
    cxxLanguageStandard: .gnucxx20
)
#endif
#endif

#if os(iOS)

let package = Package(
    name: "llmfarm_core.swift",
    platforms: [.iOS(.v15)],
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
            //            sources: ["ggml.c", "gptneox/gptneox.cpp","gptneox/gptneox_new.cpp","gptneox/common.cpp", "llama.cpp"],
            sources: ["ggml.c", "gptneox/gptneox.cpp","gpt2/gpt2.cpp","common.cpp","gpt_helpers.cpp","gpt_spm.cpp", "llama/llama.cpp"],
            publicHeadersPath: "spm-headers",
            cSettings: [
                .unsafeFlags(["-O3"]),
                .unsafeFlags(["-DNDEBUG"]),
                .unsafeFlags(["-mcpu=native"]),
                .unsafeFlags(["-DGGML_USE_ACCELERATE"]),
                .unsafeFlags(["-w"])    // ignore all warnings
            ]),
    ],
    cLanguageStandard: .gnu11,
    cxxLanguageStandard: .gnucxx20
)

#endif
