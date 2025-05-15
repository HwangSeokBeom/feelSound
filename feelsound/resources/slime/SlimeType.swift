//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/15/25.
//

import Foundation

enum SlimeType: CaseIterable {
    case fudge
    case glitter
    case bubble
    case moss
    case metallic

    var textureName: String {
        switch self {
        case .fudge: return "fudge_slime"
        case .glitter: return "glitter_slime"
        case .bubble: return "bubble_slime"
        case .moss: return "moss_slime"
        case .metallic: return "metallic_slime"
        }
    }

    var previewImage: String {
        return textureName
    }

    var config: SlimeConfig {
        switch self {
        case .fudge:
            return SlimeConfig(elasticity: 0.05, damping: 0.88, soundProfile: .fudge)
        case .glitter:
            return SlimeConfig(elasticity: 0.06, damping: 0.90, soundProfile: .glitter)
        case .bubble:
            return SlimeConfig(elasticity: 0.07, damping: 0.85, soundProfile: .bubble)
        case .moss:
            return SlimeConfig(elasticity: 0.03, damping: 0.95, soundProfile: .moss)
        case .metallic:
            return SlimeConfig(elasticity: 0.06, damping: 0.92, soundProfile: .metallic)
        }
    }
}
