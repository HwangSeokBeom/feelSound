//
//  SlimeView.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

import SwiftUI
import SpriteKit

struct SlimeView: View {
    var scene: SKScene {
        let scene = SlimeScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}
