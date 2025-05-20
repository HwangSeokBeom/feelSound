//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/15/25.
//

import Foundation

enum SlimeType: CaseIterable {
    case fudge, glitter, bubble, moss, metallic

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
            return SlimeConfig(
                elasticity: 0.05,
                damping: 0.88,
                soundProfile: .fudge,
                deformation: SlimeDeformationProfile(waveFreq: 25, waveSpeed: 4, intensity: 0.015, shapeType: 0)
            )
        case .glitter:
            return SlimeConfig(
                elasticity: 0.06,
                damping: 0.90,
                soundProfile: .glitter,
                deformation: SlimeDeformationProfile(waveFreq: 50, waveSpeed: 8, intensity: 0.01, shapeType: 1)
            )
        case .bubble:
            return SlimeConfig(
                elasticity: 0.07,
                damping: 0.85,
                soundProfile: .bubble,
                deformation: SlimeDeformationProfile(waveFreq: 10, waveSpeed: 3, intensity: 0.02, shapeType: 2)
            )
        case .moss:
            return SlimeConfig(
                elasticity: 0.03,
                damping: 0.95,
                soundProfile: .moss,
                deformation: SlimeDeformationProfile(waveFreq: 15, waveSpeed: 2, intensity: 0.008, shapeType: 3)
            )
        case .metallic:
            return SlimeConfig(
                elasticity: 0.06,
                damping: 0.92,
                soundProfile: .metallic,
                deformation: SlimeDeformationProfile(waveFreq: 35, waveSpeed: 6, intensity: 0.012, shapeType: 4)
            )
        }
    }
}

struct SlimeConfig {
    let elasticity: Float
    let damping: Float
    let soundProfile: SlimeSoundProfile
    let deformation: SlimeDeformationProfile
}

struct SlimeDeformationProfile {
    let waveFreq: Float
    let waveSpeed: Float
    let intensity: Float
    let shapeType: Int32

    func toMetalStruct() -> DeformationParams {
        return DeformationParams(waveFreq: waveFreq, waveSpeed: waveSpeed, intensity: intensity, shapeType: shapeType)
    }
}
