//
//  WordPieceTokenizer.swift
//  feelsound
//
//  Created by Hwangseokbeom on 2025/05/28.
//

import Foundation

class WordPieceTokenizer {
    private let vocab: [String: Int]
    private let unkToken: String = "[UNK]"
    private let maxInputCharsPerWord: Int = 100

    init(vocab: [String: Int]) {
        self.vocab = vocab
    }

    /// 텍스트 전체 문장을 토큰 리스트로 분할
    func tokenize(_ text: String) -> [String] {
        let lowercased = text.lowercased()
        let words = lowercased.components(separatedBy: .whitespacesAndNewlines)
        var tokens: [String] = []

        for word in words {
            guard !word.isEmpty else { continue }
            let subTokens = tokenizeWord(word)
            tokens.append(contentsOf: subTokens)
        }

        return tokens
    }

    /// 단일 단어를 WordPiece 방식으로 분할
    private func tokenizeWord(_ word: String) -> [String] {
        if word.count > maxInputCharsPerWord {
            return [unkToken]
        }

        var subTokens: [String] = []
        var start = word.startIndex

        while start < word.endIndex {
            var end = word.endIndex
            var found = false

            while end > start {
                let substr = word[start..<end]
                let candidate = start == word.startIndex ? String(substr) : "##" + substr

                if vocab[candidate] != nil {
                    subTokens.append(candidate)
                    start = end
                    found = true
                    break
                }

                end = word.index(before: end)
            }

            if !found {
                return [unkToken]
            }
        }

        return subTokens
    }

    /// 토큰 리스트 → 정수 ID 리스트로 변환
    func convertTokensToIds(_ tokens: [String]) -> [Int] {
        return tokens.map { vocab[$0] ?? vocab[unkToken]! }
    }
}
