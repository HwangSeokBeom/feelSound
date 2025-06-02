//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/30/25.
//

import SwiftUI
import SpriteKit

struct CharacterView1: View {
    let scene = ArcticFoxScene()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SpriteView(scene: scene)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        scene.size = geometry.size
                        scene.scaleMode = .resizeFill

                        // 💡 감정 분석 테스트 실행
                        let analyzer = EmotionAnalyzer()
                        let tester = EmotionTester(analyzer: analyzer)
                        tester.runTest()
                    }
            }
        }
    }
}
