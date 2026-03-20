//
//  EchoAIService.swift
//  Echo AI
//
//  Created by Sameer Nikhil on 24/08/25.
//

import Foundation
import Combine

// MARK: - AI Model Enum
enum AIModel: String, CaseIterable {
    case geo = "Echo"
    case echoAPI = "Echo Pro"
    
    var displayName: String { self.rawValue }
    var icon: String {
        switch self {
        case .geo: return "globe"
        case .echoAPI: return "cpu.fill"
        }
    }
}

// MARK: - News Models
struct NewsArticle: Identifiable, Codable, Equatable {
    let id = UUID()
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let source: Source
    let publishedAt: String?
    
    struct Source: Codable, Equatable {
        let name: String
    }
}

struct NewsResponse: Codable {
    let articles: [NewsArticle]
    let status: String
    let totalResults: Int?
}

@MainActor
class EchoAIService: ObservableObject {
    // MARK: - Chat Properties
    @Published var messages: [EchoMessage] = []
    @Published var selectedAIModel: AIModel = .geo
    @Published var isLoading = false
    
    // API Keys
    private let groqApiKey = ""//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
    private let echoAPIKey = ""//AIzaSyBuZhHkEli_gnd2JwN-HBLzQiaIPzMpVT8
    
    // MARK: - News Properties
    @Published var articles: [NewsArticle] = []
    @Published var selectedCategory = "general"
    
    private let newsApiKey = ""//996df1022efc420f816029a1291ac4bc
    private var page = 1
    
    private let categories: [(label: String, key: String)] = [
        ("For You", "general"),
        ("Top Stories", "business"),
        ("Tech & Science", "technology"),
        ("Sports", "sports"),
        ("Entertainment", "entertainment"),
        ("Health", "health"),
        ("Automobile", "automobile"),
        ("Movies", "movies")
    ]
    
    var categoriesList: [(label: String, key: String)] {
        return categories
    }
    
    // MARK: - AI Model Selection
    func selectAIModel(_ model: AIModel) {
        selectedAIModel = model
    }
    
    // MARK: - Chat Methods
    func sendMessage(_ text: String, using model: AIModel) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        selectedAIModel = model
        
        messages.append(EchoMessage(content: trimmed, isUser: true, timestamp: Date(), modelUsed: model.rawValue))
        
        let streamingMessage = EchoMessage(
            content: "",
            isUser: false,
            timestamp: Date(),
            modelUsed: model.rawValue,
            isStreaming: true
        )
        messages.append(streamingMessage)
        
        isLoading = true
        
        Task {
            switch model {
            case .geo:
                await fetchGroqResponse(for: trimmed)
            case .echoAPI:
                await fetchEchoAPIResponse(for: trimmed)
            }
        }
    }
    
    func sendMessage(_ text: String) {
        sendMessage(text, using: selectedAIModel)
    }
    
    // MARK: - Groq API (Geo Model)
    private func fetchGroqResponse(for query: String) async {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            handleError("Invalid API URL", modelUsed: "Geo")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(groqApiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                ["role": "system", "content": "You are Geo AI, a helpful assistant with geographic and general knowledge."],
                ["role": "user", "content": query]
            ],
            "temperature": 0.7
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let serverMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                handleError("Error \(http.statusCode): \(serverMsg)", modelUsed: "Geo")
                return
            }

            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let choices = json["choices"] as? [[String: Any]],
                let first = choices.first,
                let message = first["message"] as? [String: Any],
                let content = message["content"] as? String
            else {
                handleError("Could not parse Geo AI response.", modelUsed: "Geo")
                return
            }

            updateLastMessage(with: content.trimmingCharacters(in: .whitespacesAndNewlines), modelUsed: "Geo")
        } catch {
            handleError("Network error: \(error.localizedDescription)", modelUsed: "Geo")
        }
    }
    
    // MARK: - Echo API
    private func fetchEchoAPIResponse(for query: String) async {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(echoAPIKey)") else {
            handleError("Invalid Echo API URL", modelUsed: "Echo API")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": query]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "maxOutputTokens": 1000
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let serverMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                handleError("Echo API Error \(http.statusCode): \(serverMsg)", modelUsed: "Echo API")
                return
            }
            
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let candidates = json["candidates"] as? [[String: Any]],
                let first = candidates.first,
                let content = first["content"] as? [String: Any],
                let parts = content["parts"] as? [[String: Any]],
                let firstPart = parts.first,
                let text = firstPart["text"] as? String
            else {
                handleError("Could not parse Echo API response.", modelUsed: "Echo API")
                return
            }
            
            updateLastMessage(with: text.trimmingCharacters(in: .whitespacesAndNewlines), modelUsed: "Echo API")
        } catch {
            handleError("Echo API Network error: \(error.localizedDescription)", modelUsed: "Echo API")
        }
    }
    
    // MARK: - Helper Methods
    private func updateLastMessage(with content: String, modelUsed: String) {
        guard !messages.isEmpty else { return }
        
        let lastIndex = messages.count - 1
        messages[lastIndex] = EchoMessage(
            content: content,
            isUser: false,
            timestamp: Date(),
            modelUsed: modelUsed,
            isStreaming: false
        )
        isLoading = false
        
        // Save the conversation after each AI response
        SharedChatHistoryViewModel.shared.saveChatSession(messages: messages)
    }
    
    private func handleError(_ message: String, modelUsed: String) {
        isLoading = false
        
        if let lastMessage = messages.last, lastMessage.isStreaming {
            messages.removeLast()
        }
        
        messages.append(EchoMessage(
            content: message,
            isUser: false,
            timestamp: Date(),
            modelUsed: modelUsed
        ))
    }
    
    // MARK: - News Methods
    func resetNews() {
        page = 1
        articles.removeAll()
    }
    
    func fetchNews(category: String, reset shouldReset: Bool = false) {
        guard !isLoading else { return }
        isLoading = true
        selectedCategory = category
        
        if shouldReset { resetNews() }
        
        let urlString: String
        switch category {
        case "automobile":
            let query = "(automobile OR automotive OR cars OR EV OR Tesla OR BMW OR Mercedes)"
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "automobile"
            urlString = "https://newsapi.org/v2/everything?q=\(encoded)&language=en&sortBy=publishedAt&page=\(page)&pageSize=10&apiKey=\(newsApiKey)"
            
        case "movies":
            let query = "(movies OR film OR cinema OR Bollywood OR Hollywood)"
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "movies"
            urlString = "https://newsapi.org/v2/everything?q=\(encoded)&language=en&sortBy=publishedAt&page=\(page)&pageSize=10&apiKey=\(newsApiKey)"
            
        default:
            urlString = "https://newsapi.org/v2/top-headlines?country=us&category=\(category)&page=\(page)&pageSize=10&apiKey=\(newsApiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            defer {
                Task { @MainActor in self.isLoading = false }
            }
            
            guard let data = data,
                  let newsResponse = try? JSONDecoder().decode(NewsResponse.self, from: data) else {
                return
            }
            
            Task { @MainActor in
                self.articles.append(contentsOf: newsResponse.articles)
                self.page += 1
            }
        }.resume()
    }
    
    func uniqueSourceCount() -> Int {
        return max(Set(articles.map { $0.source.name }).count, 12)
    }
    
    func relatedArticles(to article: NewsArticle, max: Int = 10) -> [NewsArticle] {
        let tokens = Set(article.title
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count > 3 })
        
        let scored = articles.filter { $0 != article }.map { candidate -> (NewsArticle, Int) in
            let candidateTokens = Set(candidate.title
                .lowercased()
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
                .filter { $0.count > 3 })
            return (candidate, tokens.intersection(candidateTokens).count)
        }
        .sorted { $0.1 > $1.1 }
        
        return scored.prefix(max).map { $0.0 }
    }
}

// MARK: - Conversation Management Extensions
extension EchoAIService {
    func loadConversation(_ messages: [EchoMessage]) {
        self.isLoading = false
        self.messages = messages
        print("Loaded conversation with \(messages.count) messages")
        objectWillChange.send()
    }
    
    func saveCurrentConversation() -> [EchoMessage] {
        return self.messages
    }
    
    func clearConversation() {
        self.messages = []
        self.isLoading = false
        print("Conversation cleared")
        objectWillChange.send()
    }
}
