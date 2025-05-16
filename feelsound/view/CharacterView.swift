//
//  ContentView.swift
//  MovingCharacter
//
//  Created by Hwangseokbeom on 5/7/25.
//

import SwiftUI
import SpriteKit

struct CharacterView: View {
    let scene = ArcticFoxScene()

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.size = UIScreen.main.bounds.size
                    scene.scaleMode = .resizeFill
                }

            VStack {
  
            }
        }
    }
}
