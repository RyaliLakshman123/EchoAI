//
//  ExtensionColor.swift
//  Echo AI
//
//  Created by Sameer Nikhil on 24/08/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Hex Support
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#") // Skip #
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Echo AI Palette
extension Color {
    static let echoCyan = Color(hex: "#06B6D4")   // Premium cyan
    static let echoWhite = Color(hex: "#FFFFFF")  // Clean white
    static let echoBlack = Color(hex: "#111111")  // Premium dark
    static let echoGold = Color(hex: "#FFD700")   // Premium accent
    static let echoPurple = Color(hex: "#9333EA") // Modern purple
    static let echoGray = Color(hex: "#E5E7EB")   // Light gray
}



// Extension to get average color from UIImage
extension UIImage {
    func averageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extent = inputImage.extent
        let context = CIContext()

        let filter = CIFilter.areaAverage()
        filter.inputImage = inputImage
        filter.extent = extent

        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())

        return UIColor(
            red: CGFloat(bitmap[0]) / 255.0,
            green: CGFloat(bitmap[1]) / 255.0,
            blue: CGFloat(bitmap[2]) / 255.0,
            alpha: 1
        )
    }
}
