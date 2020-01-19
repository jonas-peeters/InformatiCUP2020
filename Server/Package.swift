// swift-tools-version:4.2

import PackageDescription

let package = Package(
	name: "InformatiCUP-2020",
	products: [
		.executable(name: "InformatiCUP", targets: ["InformatiCUP"])
	],
	dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.8.0")
	],
	targets: [
		.target(name: "InformatiCUP", dependencies: ["Kitura"])
	]
)
