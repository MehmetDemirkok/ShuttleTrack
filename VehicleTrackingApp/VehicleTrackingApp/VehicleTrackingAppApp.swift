//
//  VehicleTrackingAppApp.swift
//  VehicleTrackingApp
//
//  Created by Mehmet Demirkök on 24.10.2025.
//

import SwiftUI
import FirebaseCore

@main
struct VehicleTrackingAppApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if appViewModel.isAuthenticated {
                DashboardView()
            } else {
                LoginView()
            }
        }
    }
}
