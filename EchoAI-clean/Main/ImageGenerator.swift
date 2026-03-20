//
//  ImageGenerator.swift
//  Echo AI
//
//  Created by Sameer Nikhil on 26/08/25.
//  Premium Pollinations AI version
//

import SwiftUI
import Photos
import UIKit

// MARK: - Constants & Helpers
private enum UIConstants {
    static let cornerRadius: CGFloat = 20
    static let largeCornerRadius: CGFloat = 28
    static let cardHeight: CGFloat = 420
    static let styleButtonSize: CGFloat = 80
    static let headerHeight: CGFloat = 120
}

private let neonGradient = LinearGradient(
    colors: [Color.echoCyan, Color.cyan],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

private let backgroundGradient = LinearGradient(
    colors: [Color.black, Color(white: 0.03)],
    startPoint: .top,
    endPoint: .bottom
)

private let premiumGradient = LinearGradient(
    colors: [/*Color.green.opacity(0.8),*/ Color.cyan.opacity(0.6), Color.blue.opacity(0.4)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - ViewModel
final class ViewModel: ObservableObject {
    @Published var generatedImages: [GeneratedImage] = []

    // Add this to your ViewModel's setup() method
    func setup() {
        print("Image ViewModel ready ✅ (Pollinations AI - Premium)")
        
        // DEBUG: Check if Info.plist keys are loaded
        if let photoAddUsage = Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryAddUsageDescription") as? String {
            print("✅ Found NSPhotoLibraryAddUsageDescription: \(photoAddUsage)")
        } else {
            print("❌ NSPhotoLibraryAddUsageDescription NOT FOUND in bundle")
        }
        
        if let photoUsage = Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") as? String {
            print("✅ Found NSPhotoLibraryUsageDescription: \(photoUsage)")
        } else {
            print("❌ NSPhotoLibraryUsageDescription NOT FOUND in bundle")
        }
    }

    /// Generate an image using Pollinations AI - UPDATED WITH BETTER ERROR HANDLING
    func generateImageWithPollinations(prompt: String, style: ImageStyle) async -> UIImage? {
        let styledPrompt = "\(style.promptPrefix) \(prompt)"
        let encodedPrompt = styledPrompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let url = URL(string: "https://image.pollinations.ai/prompt/\(encodedPrompt)?width=1024&height=1024&model=flux&seed=\(Int.random(in: 1...1000))") else {
            print("❌ Invalid Pollinations URL")
            return nil
        }
        
        do {
            print("🎨 Starting image generation...")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    print("❌ HTTP Error: \(httpResponse.statusCode)")
                    return nil
                }
            }
            
            guard let uiImage = UIImage(data: data) else {
                print("❌ Failed to convert data to UIImage")
                return nil
            }
            
            print("✅ Image generated successfully")
            
            // Ensure UI update happens on main thread
            let generated = GeneratedImage(image: uiImage, prompt: prompt, style: style, timestamp: Date())
            await MainActor.run {
                self.generatedImages.insert(generated, at: 0)
                print("✅ Image added to gallery")
            }
            
            return uiImage
            
        } catch {
            await MainActor.run {
                print("❌ Pollinations request failed: \(error.localizedDescription)")
            }
            return nil
        }
    }

    // UPDATED SAVE METHOD - MODERN PHOTOS FRAMEWORK
    func saveImageToLibrary(_ image: UIImage) {
        print("💾 Attempting to save image...")
        
        // Check current authorization status first
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            print("✅ Already authorized - proceeding to save")
            performSaveImage(image)
            
        case .notDetermined:
            print("🔒 Requesting photo library permission...")
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        print("✅ Permission granted - saving image")
                        self.performSaveImage(image)
                    } else {
                        print("❌ Permission denied - cannot save image")
                        // You could show an alert here explaining why the permission is needed
                    }
                }
            }
            
        case .denied, .restricted:
            print("❌ Photo library access denied or restricted")
            // You could show an alert directing user to Settings
            
        @unknown default:
            print("⚠️ Unknown authorization status")
        }
    }

    private func performSaveImage(_ image: UIImage) {
        print("💾 Performing save operation...")
        
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            request.location = nil // Optional: remove location data
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Image saved successfully to Photos")
                    // You could show a success message to the user here
                } else if let error = error {
                    print("❌ Error saving image: \(error.localizedDescription)")
                    // You could show an error alert here
                } else {
                    print("❌ Unknown error occurred while saving image")
                }
            }
        }
    }
}

// MARK: - Models
struct GeneratedImage: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let prompt: String
    let style: ImageStyle
    let timestamp: Date

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: GeneratedImage, rhs: GeneratedImage) -> Bool { lhs.id == rhs.id }
}

enum ImageStyle: String, CaseIterable, Hashable {
    case realistic = "Realistic"
    case artistic = "Artistic"
    case cartoon = "Cartoon"
    case anime = "Anime"
    case watercolor = "Watercolor"
    case oilPainting = "Oil Painting"
    case sketch = "Sketch"
    case cyberpunk = "Cyberpunk"

    var promptPrefix: String {
        switch self {
        case .realistic:   return "Photorealistic, ultra high quality:"
        case .artistic:    return "Artistic, creative masterpiece:"
        case .cartoon:     return "Cartoon style, vibrant, playful:"
        case .anime:       return "Anime style, manga inspired:"
        case .watercolor:  return "Watercolor painting, dreamy and soft:"
        case .oilPainting: return "Oil painting, textured canvas style:"
        case .sketch:      return "Pencil sketch, detailed drawing:"
        case .cyberpunk:   return "Cyberpunk style, neon, futuristic sci-fi:"
        }
    }

    var iconName: String {
        switch self {
        case .realistic: return "camera.fill"
        case .artistic: return "paintbrush.fill"
        case .cartoon: return "face.smiling.fill"
        case .anime: return "sparkles"
        case .watercolor: return "drop.fill"
        case .oilPainting: return "paintpalette.fill"
        case .sketch: return "pencil"
        case .cyberpunk: return "cpu.fill"
        }
    }
}

// MARK: - Main View - UPDATED WITH KEYBOARD DISMISSAL
struct ImageGenerator: View {
    @StateObject private var viewModel = ViewModel()
    @State private var promptText: String = ""
    @State private var currentImage: UIImage?
    @State private var isGenerating: Bool = false
    @State private var selectedStyle: ImageStyle = .realistic
    @State private var showingGallery: Bool = false

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Premium Navigation Header
                PremiumHeaderView(onGalleryTap: { showingGallery = true }, imageCount: viewModel.generatedImages.count)
                
                // Main Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ImageCardView(image: currentImage, isGenerating: isGenerating)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                        StylePickerView(selectedStyle: $selectedStyle)
                        PromptInputView(text: $promptText)

                        ActionButtonsView(
                            isGenerating: $isGenerating,
                            promptText: $promptText,
                            onGenerate: {
                                hideKeyboard()  // DISMISS KEYBOARD WHEN GENERATING
                                generateButtonTapped()
                            }
                        )
                    }
                    .padding(.bottom, 30)
                }
                .padding(.top, -65)
            }
        }
        // KEYBOARD DISMISSAL: Tap anywhere to hide keyboard
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear { viewModel.setup() }
        .sheet(isPresented: $showingGallery) {
            PremiumGalleryView(images: viewModel.generatedImages) { image in
                viewModel.saveImageToLibrary(image)
            }
        }
        .preferredColorScheme(.dark)
    }

    // KEYBOARD DISMISSAL HELPER FUNCTION
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // UPDATED GENERATE FUNCTION WITH PROPER ERROR HANDLING
    private func generateButtonTapped() {
        guard !isGenerating else {
            print("⚠️ Already generating, ignoring tap")
            return
        }
        
        let prompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            print("⚠️ Empty prompt, cannot generate")
            return
        }

        print("🚀 Starting image generation process...")
        isGenerating = true
        currentImage = nil
        hideKeyboard() // Dismiss keyboard when generating

        Task {
            do {
                print("🎨 Calling Pollinations API...")
                
                if let image = await viewModel.generateImageWithPollinations(prompt: prompt, style: selectedStyle) {
                    await MainActor.run {
                        print("✅ Image generation completed successfully")
                        self.currentImage = image
                        self.isGenerating = false
                    }
                } else {
                    await MainActor.run {
                        print("❌ Failed to generate image - no image returned")
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Error in generation process: \(error.localizedDescription)")
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - Premium Header View (UNCHANGED)
private struct PremiumHeaderView: View {
    let onGalleryTap: () -> Void
    let imageCount: Int
    
    var body: some View {
        ZStack {
            // Header Background with blur effect
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.black.opacity(0.9))
                .background(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [Color.green.opacity(0.1), Color.cyan.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            HStack {
                // Left Side - Logo & Title
                HStack(spacing: 12) {
                    // Premium Logo
                    ZStack {
                        Circle()
                            .fill(premiumGradient)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Echo AI Studio")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.cyan.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Premium Edition")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.echoCyan.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.echoCyan.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.cyan.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                    }
                }
                
                Spacer()
                
                // Right Side - Gallery Button
                Button(action: onGalleryTap) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(neonGradient, lineWidth: 1)
                                )
                            
                            Image(systemName: "photo.stack")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        if imageCount > 0 {
                            Text("\(imageCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(neonGradient)
                                        .shadow(color: Color.green.opacity(0.4), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .padding(.bottom, 20)
        }
        .frame(height: UIConstants.headerHeight)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Enhanced Image Card View (UNCHANGED)
private struct ImageCardView: View {
    let image: UIImage?
    let isGenerating: Bool

    var body: some View {
        ZStack {
            // Main Card
            RoundedRectangle(cornerRadius: UIConstants.largeCornerRadius)
                .fill(Color.black.opacity(0.7))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.largeCornerRadius)
                        .stroke(neonGradient, lineWidth: 1.5)
                )
                .shadow(color: Color.green.opacity(0.2), radius: 25, x: 0, y: 15)
                .shadow(color: Color.cyan.opacity(0.1), radius: 40, x: 0, y: 20)

            Group {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                        .padding(16)
                        .transition(.scale.combined(with: .opacity))
                } else if isGenerating {
                    EnhancedGeneratingView()
                } else {
                    PremiumPlaceholderView()
                }
            }
        }
        .frame(height: UIConstants.cardHeight)
    }
}

// MARK: - Premium Placeholder (UNCHANGED)
private struct PremiumPlaceholderView: View {
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(premiumGradient.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    .cornerRadius(10)
                
                Image(systemName: "photo.artframe")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(neonGradient)
            }
            
            VStack(spacing: 8) {
                Text("Create Your Masterpiece")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Enter a prompt and watch AI bring your imagination to life")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.65))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding()
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Enhanced Generating View (UNCHANGED)
private struct EnhancedGeneratingView: View {
    @State private var progress: Double = 0.0
    @State private var rotation: Double = 0.0
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 2)
                    .frame(width: 150, height: 150)
                    .cornerRadius(10)
                
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                    .frame(width: 130, height: 130)
                    .cornerRadius(10)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(neonGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 130, height: 130)
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Rotating sparkles
               Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.cyan.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotation)
                
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(neonGradient)
                    
                    Text("Generating")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(neonGradient)
                }
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                progress += 0.015
                if progress >= 1.0 {
                    progress = 0.0
                }
                progress = min(max(progress, 0.0), 1.0)
            }
        }
        .onAppear {
            progress = 0.0
            rotation = 360.0
        }
    }
}

// MARK: - Enhanced Style Picker (UNCHANGED)
private struct StylePickerView: View {
    @Binding var selectedStyle: ImageStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Style")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ImageStyle.allCases, id: \.self) { style in
                        EnhancedStyleButton(style: style, isSelected: style == selectedStyle) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedStyle = style
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 12)
        }
    }
}

private struct EnhancedStyleButton: View {
    let style: ImageStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Rectangle()
                        .fill(isSelected ? Color.echoCyan : Color.black.opacity(0.6))
                        .frame(width: 50, height: 50)
                        .cornerRadius(15)
                        .overlay(
                            Rectangle()
                                .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Color.green.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                        .cornerRadius(15)
                    
                    Image(systemName: style.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text(style.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(white: 0.7))
                    .lineLimit(1)
            }
            .frame(width: 80)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - UPDATED PROMPT INPUT WITH KEYBOARD DISMISSAL
private struct PromptInputView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Prompt")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                
                Text("\(text.count)/500")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(white: 0.6))
            }
            .padding(.horizontal, 20)
            
            TextField("Describe your vision in detail...", text: $text, axis: .vertical)
                .focused($isFocused)
                .lineLimit(4...8)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isFocused ? Color.echoCyan : Color.white.opacity(0.1), lineWidth: isFocused ? 1.5 : 1)
                        )
                        .shadow(color: Color.green.opacity(0.2), radius: 25, x: 0, y: 15)
                        .shadow(color: Color.green.opacity(0.1), radius: 40, x: 0, y: 20)
                )
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 20)
                .onSubmit {
                    // DISMISS KEYBOARD WHEN USER PRESSES RETURN
                    isFocused = false
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                        }
                    }
                }
        }
    }
}

// MARK: - Enhanced Action Buttons (UNCHANGED)
private struct ActionButtonsView: View {
    @Binding var isGenerating: Bool
    @Binding var promptText: String
    let onGenerate: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Button(action: onGenerate) {
                HStack(spacing: 12) {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .medium))
                        Text("Generate Artwork")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(neonGradient)
                        .shadow(color: Color.echoCyan.opacity(0.4), radius: 15, x: 0, y: 8)
                )
                .foregroundColor(.white)
                .scaleEffect(isGenerating ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isGenerating)
            }
            .disabled(isGenerating || promptText.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 20)
            .opacity(promptText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
        }
    }
}

// MARK: - Keep existing PremiumGalleryView and GalleryCell unchanged
private struct PremiumGalleryView: View {
    let images: [GeneratedImage]
    let onSave: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                if images.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(Color(white: 0.6))
                        Text("No images generated yet")
                            .foregroundColor(Color(white: 0.7))
                            .font(.headline)
                        Text("Create your first masterpiece!")
                            .foregroundColor(Color(white: 0.5))
                            .font(.subheadline)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(images, id: \.self) { generated in
                                GalleryCell(generated: generated, onSave: onSave)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct GalleryCell: View {
    let generated: GeneratedImage
    let onSave: (UIImage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(uiImage: generated.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)

            Text(generated.prompt)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack {
                Text(generated.style.rawValue)
                    .font(.caption2)
                    .foregroundColor(Color.green)
                Spacer()
                Button(action: { onSave(generated.image) }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(neonGradient, lineWidth: 0.6))
    }
}

// MARK: - Preview
struct ImageGenerator_Previews: PreviewProvider {
    static var previews: some View {
        ImageGenerator()
            .previewDevice("iPhone 15")
    }
}
