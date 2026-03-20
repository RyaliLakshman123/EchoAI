//
//  ContentView.swift
//  Echo AI
//
//  Created by Sameer Nikhil on 24/08/25.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var echoAI = EchoAIService()
    
    init() {
        // Configure RevenueCat - Replace with your actual API key
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "REMOVED")
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .environmentObject(echoAI)
                .tabItem {
                    premiumTabIcon("magnifyingglass", isSelected: selectedTab == 0)
                }
                .tag(0)
            
            // News Tab
            NewsView()
                .tabItem {
                    premiumTabIcon("globe", isSelected: selectedTab == 1)
                }
                .tag(1)
            
            // Image Generator Tab
            ImageGenerator()
                .tabItem {
                    premiumTabIcon("sparkles", isSelected: selectedTab == 2)
                }
                .tag(2)
            
            // Books Tab (placeholder for now)
            ChatHistoryView(selectedTabIndex: $selectedTab, echoAI: echoAI)
                           .tabItem {
                               premiumTabIcon("checkmark.message", isSelected: selectedTab == 3)
                           }
                           .tag(3)
            
        }
        .accentColor(.cyan)
        .preferredColorScheme(.dark)
        .onAppear {
            // Customize tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.9)
            
            // Selected item color
            tabBarAppearance.selectionIndicatorTintColor = UIColor.cyan
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    private func premiumTabIcon(_ systemName: String, isSelected: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: isSelected ? [.echoWhite, .echoCyan] : [.echoWhite.opacity(0.5), .echoCyan.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(
                color: isSelected ? .echoCyan.opacity(0.6) : .clear,
                radius: isSelected ? 6 : 0,
                x: 0,
                y: isSelected ? 3 : 0
            )
    }
}

// Placeholder view for Books tab
struct BooksView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.echoBlack.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Text("Books")
                    .foregroundColor(.white)
                    .font(.largeTitle.weight(.bold))
                Text("Coming Soon")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
    }
}

#Preview {
    ContentView()
}
