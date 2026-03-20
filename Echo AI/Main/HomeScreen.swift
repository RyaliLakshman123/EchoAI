//
//  HomeScreen.swift
//  Echo
//
//  Created by Lakshman Ryali on 23/08/25.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct HomeView: View {
    @State private var query: String = ""
    @State private var showModelPicker = false
    @State private var showPaywall = false
    @State private var customerInfo: CustomerInfo?
    @State private var showPromoCard = true
    @State private var offerings: Offerings?
    @State private var isLoadingOfferings = false
    @ObservedObject var echoAI = EchoAIService()
    
    // In HomeView, add this state variable:
    @State private var refreshID = UUID()

    // Then modify your main ZStack:
    var body: some View {
        ZStack {
            backgroundView
            mainContentView
        }
        .id(refreshID) // Add this line
        .sheet(isPresented: $showPaywall) {
            PaywallViewWrapper(offerings: offerings)
        }
        .onAppear {
            loadCustomerInfo()
            loadOfferings()
        }
    }
    
    // MARK: - Center Content
    private var centerContentView: some View {
        VStack {
            if echoAI.messages.isEmpty {
                taglineView
            } else {
                // Add this debug text temporarily
                Text("Showing \(echoAI.messages.count) messages")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            messagesView
        }
    }
    
    // MARK: - RevenueCat Loading Functions
    private func loadCustomerInfo() {
        Purchases.shared.getCustomerInfo { info, error in
            DispatchQueue.main.async {
                if let info = info {
                    self.customerInfo = info
                    print("✅ Customer info loaded")
                } else if let error = error {
                    print("❌ Customer info error: \(error)")
                }
            }
        }
    }
    
    private func loadOfferings() {
        isLoadingOfferings = true
        Purchases.shared.getOfferings { offerings, error in
            DispatchQueue.main.async {
                self.isLoadingOfferings = false
                
                if let offerings = offerings {
                    self.offerings = offerings
                    print("✅ Offerings loaded successfully")
                    print("📦 Total offerings: \(offerings.all.count)")
                    
                    if let current = offerings.current {
                        print("📦 Current offering ID: \(current.identifier)")
                        print("📦 Available packages: \(current.availablePackages.count)")
                        for package in current.availablePackages {
                            print("  - Package: \(package.identifier)")
                            print("  - Product: \(package.storeProduct.productIdentifier)")
                            print("  - Price: \(package.storeProduct.localizedPriceString)")
                        }
                    } else {
                        print("⚠️ No current offering found")
                    }
                } else if let error = error {
                    print("❌ Error loading offerings: \(error)")
                }
            }
        }
    }
    
    private var shouldShowPromoCard: Bool {
        guard let customerInfo = customerInfo else { return showPromoCard }
        // Replace "pro" with your actual entitlement identifier
        let hasPremium = customerInfo.entitlements.active.keys.contains("pro")
        return !hasPremium && showPromoCard
    }
    
    // MARK: - Background Components
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.echoBlack.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            animatedDiamondBackground
        }
    }
    
    private var animatedDiamondBackground: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            GeometryReader { geo in
                Canvas { context, size in
                    let step: CGFloat = 140
                    var diamondPath = Path()
                    let offset = CGFloat(sin(time * 0.25)) * 20
                    
                    for x in stride(from: -step, through: size.width + step, by: step) {
                        for y in stride(from: -step, through: size.height + step, by: step) {
                            let center = CGPoint(x: x + offset, y: y + offset)
                            let diamond = Path { path in
                                path.move(to: CGPoint(x: center.x, y: center.y - step / 2))
                                path.addLine(to: CGPoint(x: center.x + step / 2, y: center.y))
                                path.addLine(to: CGPoint(x: center.x, y: center.y + step / 2))
                                path.addLine(to: CGPoint(x: center.x - step / 2, y: center.y))
                                path.closeSubpath()
                            }
                            diamondPath.addPath(diamond)
                        }
                    }
                    
                    let gradient = Gradient(colors: [
                        Color.cyan.opacity(0.25),
                        Color.purple.opacity(0.15)
                    ])
                    
                    context.stroke(
                        diamondPath,
                        with: .linearGradient(
                            gradient,
                            startPoint: .zero,
                            endPoint: CGPoint(x: size.width, y: size.height)
                        ),
                        lineWidth: 0.8
                    )
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack {
            topBarView
            Spacer()
            centerContentView
            if echoAI.messages.isEmpty && shouldShowPromoCard {
                promoCardView
            }
            Spacer()
            searchBarView
        }
    }
    
    // MARK: - Top Bar
    private var topBarView: some View {
        HStack {
            Button(action: {
                // Profile action
            }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            // New Chat button
            Button(action: {
                echoAI.clearConversation()
            }) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            modelSelectorButton
            Spacer()
            
            Button(action: {
                // Share action
            }) {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .frame(width: 20, height: 22)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    private var modelSelectorButton: some View {
        Button(action: { showModelPicker.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: echoAI.selectedAIModel.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(modelColor)
                
                Text(echoAI.selectedAIModel.displayName)
                    .font(.caption.weight(.semibold))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(modelGradient)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(modelSelectorBackground)
        }
        .popover(isPresented: $showModelPicker) {
            AIModelPickerView(echoAI: echoAI, isPresented: $showModelPicker)
        }
    }
    
    private var modelColor: Color {
        echoAI.selectedAIModel == .geo ? .blue : .purple
    }
    
    private var modelGradient: LinearGradient {
        LinearGradient(
            colors: [.white, modelColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var modelSelectorBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule().stroke(
                    LinearGradient(
                        colors: [modelColor.opacity(0.4), modelColor.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
            )
    }
    
    
    
    private var taglineView: some View {
        VStack(spacing: 8) {
            Text("Your Ideas, Amplified.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.echoCyan.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            
            HStack(spacing: 6) {
                Image(systemName: echoAI.selectedAIModel.icon)
                    .foregroundColor(modelColor)
                    .font(.caption.weight(.semibold))
                Text("Powered by \(echoAI.selectedAIModel.displayName)")
                    .foregroundColor(Color.echoGray.opacity(0.6))
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(taglineBackground)
        }
        .padding(.bottom, 40)
    }
    
    private var taglineBackground: some View {
        Capsule()
            .fill(modelColor.opacity(0.1))
            .overlay(
                Capsule()
                    .stroke(modelColor.opacity(0.3), lineWidth: 0.8)
            )
    }
    
    // MARK: - Messages
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(echoAI.messages) { message in
                        MessageRowView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: echoAI.messages.count) { count in
                if count > 0, let lastMessage = echoAI.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    
    
    // MARK: - Promo Card with Enhanced RevenueCat Integration
    private var promoCardView: some View {
        HStack {
            Button(action: {
                print("🔘 Promo card tapped")
                
                // If offerings are already loaded, show paywall immediately
                if offerings != nil {
                    showPaywall = true
                } else {
                    // Force reload offerings and then show paywall
                    print("📡 Reloading offerings before showing paywall...")
                    Purchases.shared.getOfferings { loadedOfferings, error in
                        DispatchQueue.main.async {
                            if let loadedOfferings = loadedOfferings {
                                self.offerings = loadedOfferings
                                print("✅ Offerings reloaded, showing paywall")
                                self.showPaywall = true
                            } else if let error = error {
                                print("❌ Failed to reload offerings: \(error)")
                                // Show paywall anyway - let RevenueCat handle the error
                                self.showPaywall = true
                            }
                        }
                    }
                }
            }) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "sparkles")
                                .foregroundStyle(.orange)
                                .font(.system(size: 20, weight: .semibold))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Introducing Echo Max")
                            .foregroundColor(Color.echoWhite)
                            .font(.footnote.weight(.semibold))
                        Text("Early access to advanced features and unlimited queries")
                            .foregroundColor(Color.echoGray.opacity(0.8))
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(.orange.opacity(0.8))
                        .font(.system(size: 18))
                }
                .padding()
                .background(Color.echoBlack.opacity(0.8))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.orange.opacity(0.4), .orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoadingOfferings)
            .opacity(isLoadingOfferings ? 0.6 : 1.0)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPromoCard = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 18))
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack {
            searchIcon
            searchTextField
            sendButton
        }
        .background(searchBarBackground)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var searchIcon: some View {
        Image(systemName: echoAI.selectedAIModel.icon)
            .foregroundStyle(searchIconGradient)
            .font(.system(size: 18, weight: .semibold))
            .padding(.leading, 12)
    }
    
    private var searchIconGradient: LinearGradient {
        LinearGradient(
            colors: [modelColor, modelColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var searchTextField: some View {
        TextField("", text: $query)
            .placeholder(when: query.isEmpty) {
                Text("Ask \(echoAI.selectedAIModel.displayName)...")
                    .foregroundColor(.white.opacity(0.5))
                    .italic()
            }
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .disabled(echoAI.isLoading)
            .onSubmit {
                sendMessage()
            }
    }
    
    private var sendButton: some View {
        Button(action: sendMessage) {
            sendButtonContent
                .frame(width: 20, height: 20)
                .padding(10)
                .background(sendButtonBackground)
        }
        .disabled(echoAI.isLoading || query.isEmpty)
        .padding(.trailing, 6)
    }
    
    private var sendButtonContent: some View {
        Group {
            if echoAI.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                Image(systemName: "square.and.arrow.up.on.square.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
    
    private var sendButtonBackground: some View {
        Circle()
            .fill(LinearGradient(colors: [modelColor], startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(color: modelColor.opacity(0.6), radius: 6, x: 0, y: 3)
    }
    
    private var searchBarBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule().stroke(
                    LinearGradient(
                        colors: [modelColor.opacity(0.6), modelColor.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.2
                )
            )
            .shadow(color: modelColor.opacity(0.4), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard !query.isEmpty else { return }
        echoAI.sendMessage(query, using: echoAI.selectedAIModel)
        query = ""
    }
}

// MARK: - Enhanced Paywall Wrapper
struct PaywallViewWrapper: View {
    let offerings: Offerings?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Paywall Content
                Group {
                    if let offerings = offerings {
                        if let currentOffering = offerings.current {
                            // Show your custom paywall from RevenueCat dashboard
                            PaywallView(offering: currentOffering)
                                .onPurchaseCompleted { customerInfo in
                                    print("✅ Purchase completed successfully!")
                                    print("Active entitlements: \(customerInfo.entitlements.active.keys)")
                                    
                                    // Update UI and dismiss
                                    DispatchQueue.main.async {
                                        dismiss()
                                    }
                                }
                                .onRestoreCompleted { customerInfo in
                                    print("✅ Restore completed successfully!")
                                    print("Active entitlements: \(customerInfo.entitlements.active.keys)")
                                    
                                    // Update UI and dismiss
                                    DispatchQueue.main.async {
                                        dismiss()
                                    }
                                }
                                .onPurchaseCancelled {
                                    print("🚫 Purchase was cancelled")
                                }
                        } else if let firstOffering = offerings.all.values.first {
                            // Fallback to first available offering
                            PaywallView(offering: firstOffering)
                                .onPurchaseCompleted { customerInfo in
                                    print("✅ Purchase completed (fallback offering)!")
                                    dismiss()
                                }
                                .onRestoreCompleted { customerInfo in
                                    print("✅ Restore completed (fallback offering)!")
                                    dismiss()
                                }
                        } else {
                            // No offerings available
                            PaywallErrorView(message: "No subscription plans available at the moment.")
                        }
                    } else {
                        // Offerings not loaded yet or failed to load
                        PaywallLoadingView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Paywall Loading View
struct PaywallLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text("Loading subscription options...")
                .foregroundColor(.white)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Paywall Error View
struct PaywallErrorView: View {
    let message: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Subscription Unavailable")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                // Retry loading offerings
                Purchases.shared.getOfferings { _, _ in }
            }
            .padding()
            .frame(maxWidth: 200)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
            
            Button("Close") {
                dismiss()
            }
            .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Message Row View (unchanged)
struct MessageRowView: View {
    let message: EchoMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                userMessageView
            } else {
                aiMessageView
                Spacer()
            }
        }
    }
    
    private var userMessageView: some View {
        Text(message.content)
            .foregroundColor(.white)
            .padding(12)
            .background(userMessageBackground)
            .cornerRadius(16)
            .shadow(color: .cyan.opacity(0.5), radius: 8, x: 0, y: 4)
    }
    
    private var userMessageBackground: some View {
        LinearGradient(
            colors: [.cyan, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var aiMessageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            aiModelBadge
            
            if !message.content.isEmpty {
                aiMessageContent
            }
        }
    }
    
    private var aiModelBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: message.modelUsed == "Geo" ? "globe" : "cpu.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(message.modelUsed == "Geo" ? .blue : .purple)
            
            Text(message.modelUsed)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            if message.isStreaming {
                streamingIndicator
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(aiModelBadgeBackground)
    }
    
    private var aiModelBadgeBackground: some View {
        Capsule()
            .fill((message.modelUsed == "Geo" ? Color.blue : Color.purple).opacity(0.15))
    }
    
    private var streamingIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 3, height: 3)
                    .foregroundColor(.white.opacity(0.4))
                    .scaleEffect(message.isStreaming ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: message.isStreaming
                    )
            }
        }
    }
    
    private var aiMessageContent: some View {
        Text(message.content)
            .foregroundColor(.white.opacity(0.9))
            .padding(12)
            .background(aiMessageContentBackground)
            .cornerRadius(16)
            .shadow(color: aiMessageShadowColor, radius: 5, x: 0, y: 3)
    }
    
    private var aiMessageContentBackground: some View {
        Color.white.opacity(0.08)
    }
    
    private var aiMessageShadowColor: Color {
        (message.modelUsed == "Geo" ? Color.blue : Color.purple).opacity(0.3)
    }
}

// MARK: - AI Model Picker View (unchanged)
struct AIModelPickerView: View {
    @ObservedObject var echoAI: EchoAIService
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            pickerHeader
            Divider()
            modelOptionsList
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .frame(width: 300, height: 180)
    }
    
    private var pickerHeader: some View {
        HStack {
            Text("Select AI Model")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            Spacer()
            Button("Done") {
                isPresented = false
            }
            .font(.system(size: 14, weight: .semibold))
        }
        .padding()
    }
    
    private var modelOptionsList: some View {
        ForEach(AIModel.allCases, id: \.self) { model in
            VStack(spacing: 0) {
                ModelOptionRow(model: model, echoAI: echoAI, isPresented: $isPresented)
                
                if model != AIModel.allCases.last {
                    Divider()
                        .padding(.leading, 50)
                }
            }
        }
    }
}

struct ModelOptionRow: View {
    let model: AIModel
    @ObservedObject var echoAI: EchoAIService
    @Binding var isPresented: Bool
    
    var body: some View {
        Button(action: selectModel) {
            HStack(spacing: 12) {
                Image(systemName: model.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(model == .geo ? .blue : .purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(model == .geo ? "Geographic & General Intelligence" : "Advanced AI Processing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if echoAI.selectedAIModel == model {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(model == .geo ? .blue : .purple)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func selectModel() {
        echoAI.selectAIModel(model)
        isPresented = false
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

/// 🔹 Custom Placeholder Modifier
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}


