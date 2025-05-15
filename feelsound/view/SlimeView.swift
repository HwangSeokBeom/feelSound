//
//  SlimeView.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

//
//  SlimeView.swift
//  feelsound
//

import SwiftUI
import MetalKit

struct SlimeView: UIViewRepresentable {
    let renderer: SlimeRenderer

    func makeUIView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let view = SlimeMTKView(frame: UIScreen.main.bounds, device: device)

        view.device = device
        view.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.isMultipleTouchEnabled = true

        renderer.viewSize = view.bounds.size
        renderer.buildGrid()
        view.delegate = renderer
        view.renderer = renderer

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // 업데이트 필요 없음 (전체 교체 방식 사용)
    }
}
