//
//  ContentView.swift
//  MovingCharacter
//
//  Created by Hwangseokbeom on 5/7/25.
//

import SwiftUI
import SpriteKit

struct CharacterView: View {
    let scene = GameScene()

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.size = UIScreen.main.bounds.size
                    scene.scaleMode = .resizeFill
                }

            VStack {
                Spacer()
                Button("🍎 먹이 주기") {
                    scene.spawnFood()
                }
                .padding()
            }
        }
    }
}
