//
//  LiquidDrop.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI

// MARK: - 액체 방울 모델
struct LiquidDrop: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var velocity: CGPoint = .zero
    var color: Color
    var opacity: Double
    var lastCollisionTime: Double = 0
}
