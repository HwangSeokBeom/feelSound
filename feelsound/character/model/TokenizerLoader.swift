//
//  TokenizerLoader.swift
//  feelsound
//
//  Created by Hwangseokbeom on 2025/05/28.
//

import Foundation

// tokenizer.json의 구조에 맞는 모델
struct TokenizerModel: Codable {
    struct Model: Codable {
        let type: String
        let vocab: [String: Int]
        let unkToken: String

        enum CodingKeys: String, CodingKey {
            case type
            case vocab
            case unkToken = "unk_token"
        }
    }

    let model: Model
}

class TokenizerLoader {
    static func loadTokenizer(from fileURL: URL) throws -> [String: Int] {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let tokenizer = try decoder.decode(TokenizerModel.self, from: data)
        return tokenizer.model.vocab
    }
}
