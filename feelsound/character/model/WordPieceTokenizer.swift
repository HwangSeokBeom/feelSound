import Foundation

class WordPieceTokenizer {
    let vocab: [String: Int]
    private let invVocab: [Int: String]
    private let unkToken = "[UNK]"
    private let maxTokenLength = 100

    init(jsonURL: URL) throws {
        let data = try Data(contentsOf: jsonURL)

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let model = jsonObject["model"] as? [String: Any],
              let vocabDict = model["vocab"] as? [String: Int] else {
            throw NSError(domain: "TokenizerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "❌ tokenizer.json 파싱 실패"])
        }

        self.vocab = vocabDict
        self.invVocab = vocabDict.reduce(into: [:]) { $0[$1.value] = $1.key }
    }

    func tokenize(_ text: String) -> [String] {
        let cleaned = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let words = cleaned.split(separator: " ").map { String($0) } // ✅ Substring → String
        var tokens: [String] = []

        for word in words {
            var subTokens: [String] = []
            var current = word
            var isBad = false

            while !current.isEmpty {
                var found = false
                let maxLen = min(maxTokenLength, current.count)
                for len in (1...maxLen).reversed() {
                    let prefix = String(current.prefix(len))
                    let subword = subTokens.isEmpty ? prefix : "##" + prefix

                    if vocab[subword] != nil {
                        subTokens.append(subword)
                        current = String(current.dropFirst(len))
                        found = true
                        break
                    }
                }
                if !found {
                    isBad = true
                    break
                }
            }

            if isBad {
                tokens.append(unkToken)
            } else {
                tokens.append(contentsOf: subTokens)
            }
        }

        return tokens
    }

    func convertTokensToIds(_ tokens: [String]) -> [Int] {
        return tokens.map { vocab[$0] ?? vocab[unkToken]! }
    }
}
