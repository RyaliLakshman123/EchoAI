//
//  ChatHistoryView.swift
//  Echo AI
//
//  Created by Sameer Nikhil on 03/09/25.
//

import SwiftUI

// MARK: - Chat History Models
struct ChatSession: Identifiable, Codable {
    let id = UUID()
    let title: String
    let preview: String
    let timestamp: Date
    let messages: [EchoMessage]
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Shared Chat History ViewModel
class SharedChatHistoryViewModel: ObservableObject {
    static let shared = SharedChatHistoryViewModel()
    @Published var chatSessions: [ChatSession] = []
    
    private let userDefaults = UserDefaults.standard
    private let chatSessionsKey = "saved_chat_sessions"
    
    private init() {
        loadChatSessions()
    }
    
    func saveChatSession(messages: [EchoMessage]) {
        guard !messages.isEmpty else { return }
        
        let firstUserMessage = messages.first(where: { $0.isUser })?.content ?? "New Chat"
        let lastMessage = messages.last?.content ?? "No messages"
        let preview = String(lastMessage.prefix(100))
        
        let session = ChatSession(
            title: String(firstUserMessage.prefix(50)),
            preview: preview,
            timestamp: Date(),
            messages: messages
        )
        
        chatSessions.insert(session, at: 0)
        saveChatSessions()
        print("Chat session saved: \(session.title)")
    }
    
    func deleteChatSession(_ session: ChatSession) {
        chatSessions.removeAll { $0.id == session.id }
        saveChatSessions()
    }
    
    private func loadChatSessions() {
        guard let data = userDefaults.data(forKey: chatSessionsKey),
              let sessions = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            print("No saved chat sessions found")
            return
        }
        chatSessions = sessions
        print("Loaded \(sessions.count) chat sessions")
    }
    
    private func saveChatSessions() {
        guard let data = try? JSONEncoder().encode(chatSessions) else { return }
        userDefaults.set(data, forKey: chatSessionsKey)
    }
}

// MARK: - Main Chat History View
struct ChatHistoryView: View {
    @StateObject private var viewModel = SharedChatHistoryViewModel.shared
    @Binding var selectedTabIndex: Int
    @ObservedObject var echoAI: EchoAIService
    
    private let backgroundGradient = LinearGradient(
        colors: [Color.black, Color.echoBlack.opacity(0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ChatHistoryHeaderView()
                
                if viewModel.chatSessions.isEmpty {
                    EmptyChatHistoryView()
                } else {
                    ChatHistoryListView(
                        sessions: viewModel.chatSessions,
                        onChatSelected: { session in
                            loadChatInHomeView(session)
                        },
                        onDeleteChat: { session in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.deleteChatSession(session)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func loadChatInHomeView(_ session: ChatSession) {
        print("Loading chat with \(session.messages.count) messages")
        echoAI.loadConversation(session.messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectedTabIndex = 0
            print("Switched to home tab")
        }
    }
}

// MARK: - Header View
private struct ChatHistoryHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chat History")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.echoCyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Your AI conversations")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.echoCyan)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    Circle()
                                        .stroke(Color.echoCyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Empty State View
private struct EmptyChatHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.echoCyan.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "message.circle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.echoCyan)
            }
            
            VStack(spacing: 12) {
                Text("No Chat History Yet")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Start a conversation with Echo AI\nand your chats will appear here")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
    }
}

// MARK: - Chat List View
private struct ChatHistoryListView: View {
    let sessions: [ChatSession]
    let onChatSelected: (ChatSession) -> Void
    let onDeleteChat: (ChatSession) -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(sessions) { session in
                    ChatSessionCard(
                        session: session,
                        onTap: { onChatSelected(session) },
                        onDelete: { onDeleteChat(session) }
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Chat Session Card
private struct ChatSessionCard: View {
    let session: ChatSession
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Chat Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.echoCyan.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: "message.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Chat Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(session.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(session.timeAgo)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Text(session.preview)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Delete Button
            Button(action: { showingDeleteConfirmation = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onTapGesture {
            print("Chat card tapped: \(session.title)")
            onTap()
        }
        .confirmationDialog(
            "Delete Chat",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct ChatHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHistoryView(
            selectedTabIndex: .constant(1),
            echoAI: EchoAIService()
        )
    }
}
