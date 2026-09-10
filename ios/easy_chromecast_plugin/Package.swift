// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "easy_chromecast_plugin",
    platforms: [
        .iOS(.v14) // Chromecast vereist minimaal iOS 14
    ],
    products: [
        .library(name: "easy-chromecast-plugin", targets: ["easy_chromecast_plugin"])
    ],
    dependencies: [
        // 1. DE ESSENTIËLE FLUTTER KOPPELING (Kopieer van de werkende test-plugin)
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        
        // 2. DE VOLLEDIGE EN CORRECTE GOOGLE CAST SDK LINK
        .package(url: "https://github.com", from: "4.8.0")
    ],
    targets: [
        .targets
            name: "easy_chromecast_plugin",
            dependencies: [
                // Koppel de plugin aan de Flutter engine
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                // Koppel de plugin aan de Google Cast SDK
                .product(name: "GoogleCast", package: "google-cast-sdk-ios-no-atv")
            ],
            path: "easy_chromecast_plugin/Sources/easy_chromecast_plugin"
        )
    ]
)
