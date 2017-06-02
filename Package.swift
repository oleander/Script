// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Script",
    dependencies: [
    .Package(url: "https://github.com/Quick/Quick.git", "1.1.0"),
    .Package(url: "https://github.com/Quick/Nimble.git", "7.0.0"),
    .Package(url: "https://github.com/kylef/PathKit.git", "0.8.0")
  ]
)
