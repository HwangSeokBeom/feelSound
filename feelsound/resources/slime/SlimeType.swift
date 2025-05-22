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
                elasticity: 0.06,
                damping: 0.89,
                soundProfile: .fudge,
                deformation: SlimeDeformationProfile(waveFreq: 12.0, waveSpeed: 2.0, intensity: 0.03, shapeType: 0)
            )
        case .glitter:
            return SlimeConfig(
                elasticity: 0.07,
                damping: 0.91,
                soundProfile: .glitter,
                deformation: SlimeDeformationProfile(waveFreq: 40.0, waveSpeed: 8.0, intensity: 0.025, shapeType: 1)
            )
        case .bubble:
            return SlimeConfig(
                elasticity: 0.08,
                damping: 0.87,
                soundProfile: .bubble,
                deformation: SlimeDeformationProfile(waveFreq: 15.0, waveSpeed: 3.0, intensity: 0.04, shapeType: 2)
            )
        case .moss:
            return SlimeConfig(
                elasticity: 0.04,
                damping: 0.93,
                soundProfile: .moss,
                deformation: SlimeDeformationProfile(waveFreq: 8.0, waveSpeed: 1.5, intensity: 0.018, shapeType: 3)
            )
        case .metallic:
            return SlimeConfig(
                elasticity: 0.05,
                damping: 0.92,
                soundProfile: .metallic,
                deformation: SlimeDeformationProfile(waveFreq: 25.0, waveSpeed: 5.0, intensity: 0.03, shapeType: 4)
            )
        }
    }
    
    // Description of each slime type for UI or documentation
    var description: String {
        switch self {
        case .fudge:
            return "A thick, gooey slime with slow, smooth movements"
        case .glitter:
            return "A sparkly slime with quick, erratic ripples"
        case .bubble:
            return "A bouncy slime with elastic, bubble-like deformations"
        case .moss:
            return "A dense, soft slime with gentle, subtle movements"
        case .metallic:
            return "A reflective slime with sharp, wave-like deformations"
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
        return DeformationParams(
            waveFreq: waveFreq,
            waveSpeed: waveSpeed,
            intensity: intensity,
            shapeType: shapeType
        )
    }
}
