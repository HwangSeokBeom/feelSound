//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 6/2/25.
//

import Foundation

class SentencePieceTokenizer {
    let vocab: [String: Int]
    private let invVocab: [Int: String]

    init(jsonURL: URL) throws {
        // tokenizer.json 로드 및 vocab 추출
        let data = try Data(contentsOf: jsonURL)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]

        guard
            let model = jsonObject["model"] as? [String: Any],
            let vocabDict = model["vocab"] as? [String: Int]
        else {
            throw NSError(domain: "TokenizerParsing", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ tokenizer.json 구조가 예상과 다릅니다."])
        }

        self.vocab = vocabDict
        self.invVocab = vocabDict.reduce(into: [:]) { $0[$1.value] = $1.key }
    }

    func tokenize(_ text: String) -> [String] {
        // SentencePiece 스타일: 공백을 '▁'로 치환
        let normalized = text.replacingOccurrences(of: " ", with: "▁")

        var tokens: [String] = []
        var index = normalized.startIndex

        while index < normalized.endIndex {
            var matched: String? = nil
            var matchLength = 0

            let remaining = normalized[index..<normalized.endIndex]
            let maxSubLength = min(10, remaining.count)

            for len in (1...maxSubLength).reversed() {
                let end = normalized.index(index, offsetBy: len)
                let piece = String(normalized[index..<end])
                if vocab.keys.contains(piece) {
                    matched = piece
                    matchLength = len
                    break
                }
            }

            if let matched = matched {
                tokens.append(matched)
                index = normalized.index(index, offsetBy: matchLength)
            } else {
                tokens.append("[UNK]")
                index = normalized.index(after: index)
            }
        }

        return tokens
    }

    func convertTokensToIds(_ tokens: [String]) -> [Int] {
        return tokens.map { vocab[$0] ?? vocab["[UNK]"]! }
    }

    func decode(_ ids: [Int]) -> String {
        let tokens = ids.compactMap { invVocab[$0] }
        return tokens.joined().replacingOccurrences(of: "▁", with: " ")
    }
}
