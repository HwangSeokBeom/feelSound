//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/28/25.
//

import Foundation

/// WordPiece 기반 토크나이저 구현체
class WordPieceTokenizer {
    private let vocab: [String: Int]
    private let unkToken: String

    init(vocab: [String: Int], unkToken: String = "[UNK]") {
        self.vocab = vocab
        self.unkToken = unkToken
    }

    /// 텍스트를 WordPiece 토큰으로 분해
    func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []

        let words = text.components(separatedBy: .whitespaces)

        for word in words {
            if vocab[word] != nil {
                tokens.append(word)
                continue
            }

            let chars = Array(word)
            var isBad = false
            var start = 0
            var subTokens: [String] = []

            while start < chars.count {
                var end = chars.count
                var curSub: String? = nil

                while start < end {
                    let substr = String(chars[start..<end])
                    let candidate = (start > 0 ? "##" : "") + substr

                    if vocab[candidate] != nil {
                        curSub = candidate
                        break
                    }

                    end -= 1
                }

                if curSub == nil {
                    isBad = true
                    break
                }

                subTokens.append(curSub!)
                start = end
            }

            tokens.append(contentsOf: isBad ? [unkToken] : subTokens)
        }

        return tokens
    }

    /// WordPiece 토큰들을 ID 시퀀스로 변환
    func convertToIDs(tokens: [String]) -> [Int] {
        return tokens.map { vocab[$0] ?? vocab[unkToken]! }
    }
}

/// JSON 기반 vocab 로더
func loadTokenizerVocab(from path: String) -> [String: Int]? {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
    do {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Int]
        return json
    } catch {
        print("❌ Vocab JSON 파싱 실패: \(error)")
        return nil
    }
}
