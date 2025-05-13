//
//  SlimeView.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

//import SwiftUI
//import SpriteKit
//
//struct SlimeView: View {
//    var scene: SKScene {
//        let scene = SlimeScene(size: UIScreen.main.bounds.size)
//        scene.scaleMode = .resizeFill
//        return scene
//    }
//
//    var body: some View {
//        SpriteView(scene: scene)
//            .ignoresSafeArea()
//    }
//}

import SwiftUI
import MetalKit

struct SlimeView: UIViewRepresentable {
    func makeCoordinator() -> SlimeRenderer {
        SlimeRenderer()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        view.delegate = context.coordinator
        view.isPaused = false
        view.enableSetNeedsDisplay = false

        let gesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        view.addGestureRecognizer(gesture)

        context.coordinator.viewSize = view.bounds.size
        context.coordinator.buildGrid()

        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}
}
