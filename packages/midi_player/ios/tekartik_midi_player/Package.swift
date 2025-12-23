// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tekartik_midi_player",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        // If the plugin name contains "_", replace with "-" for the library name.
        .library(name: "tekartik-midi-player", targets: ["tekartik_midi_player"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "tekartik_midi_player",
            dependencies: [],
            resources: [
                // TODO: If your plugin requires a privacy manifest
                // (e.g. if it uses any required reason APIs), update the PrivacyInfo.xcprivacy file
                // to describe your plugin's privacy impact, and then uncomment this line.
                // For more information, see:
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),
                .process("Resources"),
                .process("Assets"),

                // TODO: If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ],
            cSettings: [
                // TODO: Update your plugin name.
                .headerSearchPath("include/tekartik_midi_player")
            ]
        )
    ]
)
