//
//  Echo_AIApp.swift
//  Echo AI
//
//  Created by Lakshman Ryali on 24/08/25.
//


import SwiftUI
import RevenueCat

@main
struct YourApp: App {
    
    init() {
        // Configure RevenueCat with your API key
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "REMOVED")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            // the below debug shows whether the app is connected to revenuecat or not
//                .debugRevenueCatOverlay()
                .presentPaywallIfNeeded(requiredEntitlementIdentifier: "MAX")
        }
    }
}
