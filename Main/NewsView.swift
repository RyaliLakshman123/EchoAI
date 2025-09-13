//
//  NewsView.swift
//  Echo AI
//
//  Created by Sameer Nikhil on 25/08/25.
//

import SwiftUI

// MARK: - Article Card Component
struct NewsArticleCard: View {
    let article: NewsArticle
    let sourcesCount: Int
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Article Image
            Group {
                if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                            //.aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .clipped()
                                .scaledToFit()
                        case .empty:
                            Color.gray.opacity(0.3)
                                .frame(height: 200)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                )
                        case .failure(_):
                            Color.gray.opacity(0.4)
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white.opacity(0.6))
                                        .font(.title)
                                )
                        @unknown default:
                            Color.gray.opacity(0.3).frame(height: 240)
                        }
                    }
                } else {
                    Color.gray.opacity(0.3)
                        .frame(height: 240)
                        .overlay(
                            Image(systemName: "newspaper")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.title)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Article Title
            Text(article.title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Sources and metadata
            HStack(spacing: 8) {
                // Source indicators (colored circles)
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 16, height: 16)
                    Circle().fill(Color.blue).frame(width: 16, height: 16)
                    Circle().fill(Color.green).frame(width: 16, height: 16)
                }
                
                Text("\(sourcesCount) sources")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Heart and more options
                HStack(spacing: 16) {
                    Image(systemName: "heart")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16))
                    
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - News Detail Sheet
struct NewsDetailSheet: View {
    let article: NewsArticle
    let sourcesCount: Int
    let relatedArticles: [NewsArticle]
    @Environment(\.dismiss) private var dismiss
    @State private var dominantColor: Color = .black
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    
                    // Header with close button
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(article.title)
                                .font(.title.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            
                            HStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    Circle().fill(Color.orange).frame(width: 10, height: 10)
                                    Circle().fill(Color.red).frame(width: 10, height: 10)
                                    Circle().fill(Color.cyan).frame(width: 10, height: 10)
                                    Text("\(sourcesCount) sources")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white.opacity(0.15)))
                                
                                if let publishedAt = article.publishedAt {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock").font(.caption)
                                        Text(publishedAt.iso8601Display).font(.caption)
                                    }
                                    .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Spacer()
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                    
                    // Main Image
                    if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 370)
                                    .frame(height: 240)
                                    //.clipped()
                                    .cornerRadius(20)
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 240)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    )
                            case .failure(_):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 240)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.white.opacity(0.6))
                                            .font(.title)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 240)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        
                        Text(article.description ?? "No summary available for this article.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Why it matters
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why it matters")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        
                        Text("This article is trending across multiple publishers (\(sourcesCount)+ sources). It highlights important developments being covered by major news outlets.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Keep Reading
                    if !relatedArticles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Keep Reading")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(relatedArticles) { relatedArticle in
                                        RelatedArticleCard(article: relatedArticle)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                    
                    // Full Article Button
                    Button {
                        if let url = URL(string: article.url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Read full article")
                                .font(.headline)
                                .foregroundColor(.black)
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.echoCyan))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom + 20, 40))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.echoBlack.ignoresSafeArea(.all))
    }
}

// Helper view for related articles
struct RelatedArticleCard: View {
    let article: NewsArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Color.gray.opacity(0.4)
                    }
                }
            } else {
                Color.gray.opacity(0.4)
            }
        }
        .frame(width: 220, height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            VStack {
                Spacer()
                Text(article.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .onTapGesture {
            if let url = URL(string: article.url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Main News View
struct NewsView: View {
    @StateObject private var newsService = EchoAIService()
    @State private var selectedArticle: NewsArticle?
    @State private var showDetailSheet = false
    
    var body: some View {
        ZStack {
            Color.echoBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Text("Discover")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.echoCyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Spacer()
                    
                    Image(systemName: "heart")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Category Selection Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(newsService.categoriesList, id: \.key) { category in
                            Button {
                                newsService.fetchNews(category: category.key, reset: true)
                            } label: {
                                Text(category.label)
                                    .font(.subheadline.bold())
                                    .foregroundColor(newsService.selectedCategory == category.key ? .black : .white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(newsService.selectedCategory == category.key ? Color.echoCyan : Color.white.opacity(0.12))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                
                // News Articles Feed
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(newsService.articles) { article in
                            NewsArticleCard(
                                article: article,
                                sourcesCount: newsService.uniqueSourceCount(),
                                onTap: {
                                    selectedArticle = article
                                    showDetailSheet = true
                                }
                            )
                            .padding(.horizontal, 16)
                            .onAppear {
                                // Load more articles when reaching the last item
                                if article.id == newsService.articles.last?.id {
                                    newsService.fetchNews(category: newsService.selectedCategory, reset: false)
                                }
                            }
                        }
                        
                        // Loading indicator
                        if newsService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.vertical, 20)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .refreshable {
                    newsService.fetchNews(category: newsService.selectedCategory, reset: true)
                }
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            if let article = selectedArticle {
                NewsDetailSheet(
                    article: article,
                    sourcesCount: newsService.uniqueSourceCount(),
                    relatedArticles: newsService.relatedArticles(to: article)
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
            }
        }
        .onAppear {
            newsService.fetchNews(category: "general", reset: true)
        }
    }
}

// MARK: - Preview
struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView()
            .preferredColorScheme(.dark)
    }
}
