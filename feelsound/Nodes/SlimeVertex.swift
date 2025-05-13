//
//  SlimeVertex.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/13/25.
//

import simd

struct SlimeVertex {
    var position: SIMD2<Float>
    var uv: SIMD2<Float>
    var velocity: SIMD2<Float> = .zero
    var original: SIMD2<Float> = .zero
}
