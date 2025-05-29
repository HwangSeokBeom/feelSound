//
//  HandwritingListView.swift
//  feelsound
//
//  Created by 안준경 on 5/29/25.
//

import SwiftUI
import Foundation

// MARK: - 데이터 모델
struct Quote: Codable, Identifiable {
    let id = UUID()
    let quoteText: String
    let quoteAuthor: String?
    
    private enum CodingKeys: String, CodingKey {
        case quoteText, quoteAuthor
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        quoteText = try container.decode(String.self, forKey: .quoteText)
        quoteAuthor = try container.decodeIfPresent(String.self, forKey: .quoteAuthor)
    }
}

// MARK: - JSON 로더 클래스 (디버깅 개선)
class QuoteLoader: ObservableObject {
    @Published var quotes: [Quote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadQuotes() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "quotes-kr", withExtension: "json") else {
            DispatchQueue.main.async {
                self.errorMessage = "JSON 파일을 찾을 수 없습니다."
                self.isLoading = false
            }
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            let decodedQuotes = try JSONDecoder().decode([Quote].self, from: data)
            DispatchQueue.main.async {
                self.quotes = decodedQuotes
                self.isLoading = false
            }
        } catch let decodingError as DecodingError {
            DispatchQueue.main.async {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    self.errorMessage = "타입 불일치: \(type), 위치: \(context.debugDescription)"
                case .valueNotFound(let type, let context):
                    self.errorMessage = "값을 찾을 수 없음: \(type), 위치: \(context.debugDescription)"
                case .keyNotFound(let key, let context):
                    self.errorMessage = "키를 찾을 수 없음: \(key), 위치: \(context.debugDescription)"
                case .dataCorrupted(let context):
                    self.errorMessage = "데이터 손상: \(context.debugDescription)"
                @unknown default:
                    self.errorMessage = "알 수 없는 디코딩 오류: \(decodingError.localizedDescription)"
                }
                self.isLoading = false
                print("디코딩 오류 상세: \(decodingError)")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "JSON 파싱 오류: \(error.localizedDescription)"
                self.isLoading = false
                print("일반 오류: \(error)")
            }
        }
    }
}

// MARK: - 개별 명언 카드 뷰
struct QuoteCardView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(quote.quoteText)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            
            // 수정된 부분: 안전한 author 체크
            if let author = quote.quoteAuthor, !author.isEmpty {
                HStack {
                    Spacer()
                    Text("- \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - 메인 뷰
struct HandwritingListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var quoteLoader = QuoteLoader()
    @State private var searchText = ""
    
    var filteredQuotes: [Quote] {
        if searchText.isEmpty {
            return quoteLoader.quotes
        } else {
            return quoteLoader.quotes.filter { quote in
                quote.quoteText.localizedCaseInsensitiveContains(searchText) ||
                (quote.quoteAuthor?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        // NavigationStack 제거하고 기본 View로 변경
        VStack(spacing: 0) {
            // 커스텀 헤더
            ZStack {
                // 배경색 추가
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .top)
                
                HStack {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "arrow.left")
                            .resizable()
                            .frame(width: 28, height: 22)
                            .foregroundColor(.primary) // 색상 변경
                    })
                    
                    Spacer()
                    
                    Text("명언 모음")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 균형을 위한 투명한 버튼
                    Image(systemName: "arrow.left")
                        .resizable()
                        .frame(width: 28, height: 22)
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
            }
            .frame(height: 80)
            
            // 검색바
            HStack {
                TextField("명언 검색...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            
            // 메인 콘텐츠
            if quoteLoader.isLoading {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = quoteLoader.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("다시 시도") {
                        quoteLoader.loadQuotes()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(filteredQuotes.enumerated()), id: \.element.id) { index, quote in
                        NavigationLink(destination: HandwritingView(inputText: quote.quoteText)) {
                            QuoteCardView(quote: quote)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if quoteLoader.quotes.isEmpty {
                quoteLoader.loadQuotes()
            }
        }
        .refreshable {
            quoteLoader.loadQuotes()
        }
    }
}
