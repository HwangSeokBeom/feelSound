//
//  SlimeView.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

import SwiftUI
import MetalKit

struct SlimeView: UIViewRepresentable {
    func makeCoordinator() -> SlimeRenderer {
        SlimeRenderer()
    }

    func makeUIView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let view = SlimeMTKView(frame: UIScreen.main.bounds, device: device) // ✅ 사이즈 지정

        view.device = device
        view.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.isMultipleTouchEnabled = true // (추가적으로 중복 보장)

        let renderer = context.coordinator
        renderer.viewSize = view.bounds.size
        renderer.buildGrid()
        view.delegate = renderer
        view.renderer = renderer

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}
}
