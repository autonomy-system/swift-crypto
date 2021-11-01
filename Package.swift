// swift-tools-version:5.3
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.md for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// This package contains a vendored copy of BoringSSL. For ease of tracking
// down problems with the copy of BoringSSL in use, we include a copy of the
// commit hash of the revision of BoringSSL included in the given release.
// This is also reproduced in a file called hash.txt in the
// Sources/CCryptoBoringSSL directory. The source repository is at
// https://boringssl.googlesource.com/boringssl.
//
// BoringSSL Commit: 25773430c07075a368416c3646fa4b07daf4968a

import PackageDescription

// To develop this on Apple platforms, set this to true
let development = false

let swiftSettings: [SwiftSetting]
let dependencies: [Target.Dependency]
if development {
    swiftSettings = [
        .define("CRYPTO_IN_SWIFTPM"),
        .define("CRYPTO_IN_SWIFTPM_FORCE_BUILD_API"),
    ]
    dependencies = [
        "CCryptoBoringSSL",
        "CCryptoBoringSSLShims"
    ]
} else {
    swiftSettings = [
        .define("CRYPTO_IN_SWIFTPM"),
    ]
    let platforms: [Platform] = [
        Platform.linux,
        Platform.android,
        Platform.windows,
    ]
    dependencies = [
        .targetItem(name: "CCryptoBoringSSL", condition: .when(platforms: platforms)),
        .targetItem(name: "CCryptoBoringSSLShims", condition: .when(platforms: platforms))
    ]
}

let package = Package(
    name: "swift-crypto",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "Crypto", targets: ["Crypto"]),
        .library(name: "_CryptoExtras", targets: ["_CryptoExtras"]),
        /* This target is used only for symbol mangling. It's added and removed automatically because it emits build warnings. MANGLE_START
            .library(name: "CCryptoBoringSSL", type: .static, targets: ["CCryptoBoringSSL"]),
            MANGLE_END */
    ],
    dependencies: [],
    targets: [
        .target(
          name: "CCryptoBoringSSL",
          cSettings: [
            /*
             * This define is required on Windows, but because we need older
             * versions of SPM, we cannot conditionally define this on Windows
             * only.  Unconditionally define it instead.
             */
            .define("WIN32_LEAN_AND_MEAN"),
          ]
        ),
        .target(name: "CCryptoBoringSSLShims", dependencies: ["CCryptoBoringSSL"]),
        .target(
            name: "Crypto",
            dependencies: dependencies,
            swiftSettings: swiftSettings
        ),
        .target(name: "_CryptoExtras", dependencies: ["CCryptoBoringSSL", "CCryptoBoringSSLShims", "Crypto"]),
        .target(name: "crypto-shasum", dependencies: ["Crypto"]),
        .testTarget(name: "CryptoTests", dependencies: ["Crypto"], swiftSettings: swiftSettings),
        .testTarget(name: "_CryptoExtrasTests", dependencies: ["_CryptoExtras"]),
    ],
    cxxLanguageStandard: .cxx11
)
