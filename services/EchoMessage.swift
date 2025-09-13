//
//  EchoMessage.swift
//  Echo AI
//
//  Created by Sameer Nikhil on 24/08/25.
//

import Foundation

struct EchoMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let modelUsed: String
    var isStreaming: Bool
    
    init(content: String, isUser: Bool, timestamp: Date, modelUsed: String = "Geo", isStreaming: Bool = false) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.modelUsed = modelUsed
        self.isStreaming = isStreaming
    }
}

// MARK: - Date Extensions for News
extension String {
    var iso8601Display: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: self) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .short
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        return ""
    }
}
