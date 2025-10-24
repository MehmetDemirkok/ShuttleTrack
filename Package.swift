// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VehicleTrackingApp",
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
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
        .package(url: "https://github.com/googlemaps/google-maps-ios-utils", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "VehicleTrackingApp",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "GoogleMaps", package: "google-maps-ios-utils"),
                .product(name: "GoogleMapsUtils", package: "google-maps-ios-utils")
            ],
            path: ".",
            sources: [
                "App.swift", 
                "ContentView.swift",
                "Models/",
                "Views/",
                "Services/",
                "ViewModels/"
            ]
        ),
    ]
)
