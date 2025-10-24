// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VehicleTrackingApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(
            name: "VehicleTrackingApp",
            targets: ["VehicleTrackingApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
    ],
    targets: [
        .executableTarget(
            name: "VehicleTrackingApp",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: ".",
            exclude: [
                "VehicleTrackingApp/"
            ],
            sources: [
                "App.swift", 
                "ContentView.swift",
                "Models/",
                "Views/",
                "Services/",
                "ViewModels/"
            ],
            resources: [
                .process("GoogleService-Info.plist")
            ]
        ),
    ]
)
