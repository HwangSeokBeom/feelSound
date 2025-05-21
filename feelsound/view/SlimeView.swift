//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/21/25.
//

// MARK: - SlimeView.swift (SwiftUI wrapper)

import SwiftUI
import MetalKit

struct SlimeView: UIViewRepresentable {
    let renderer: SlimeRenderer

    func makeUIView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let view = MTKView(frame: .zero, device: device)
        view.device = device
        view.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.isMultipleTouchEnabled = true

        renderer.buildGrid(size: view.bounds.size)
        view.delegate = renderer
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}
}
