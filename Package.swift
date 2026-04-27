// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "QuickTranslate",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .library(name: "QuickTranslateCore", targets: ["QuickTranslateCore"]),
    .executable(name: "QuickTranslate", targets: ["QuickTranslate"]),
    .executable(name: "QuickTranslateCoreTestRunner", targets: ["QuickTranslateCoreTestRunner"])
  ],
  targets: [
    .target(
      name: "QuickTranslateCore",
      path: "Sources/QuickTranslateCore"
    ),
    .executableTarget(
      name: "QuickTranslate",
      dependencies: ["QuickTranslateCore"],
      path: "Sources/QuickTranslate",
      resources: [.process("Resources")]
    ),
    .executableTarget(
      name: "QuickTranslateCoreTestRunner",
      dependencies: ["QuickTranslateCore"],
      path: "Tests/QuickTranslateCoreTestRunner"
    )
  ]
)
