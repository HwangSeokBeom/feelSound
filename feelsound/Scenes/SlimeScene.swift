//
//  SlimeScene.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

import SpriteKit
import AVFoundation

class SlimeScene: SKScene {
    private var slime: SlimeNode!

    override func didMove(to view: SKView) {
        backgroundColor = .white

        let screenSize = view.bounds.size
        let radius = hypot(screenSize.width, screenSize.height) / 2.0  // 대각선 기준

        let texture = SKTexture(imageNamed: "glitter_slime")
        slime = SlimeNode(radius: radius, texture: texture)

        slime.position = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        addChild(slime)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: slime) else { return }
        slime.updateTouchUniform(at: location)     // 🔥 shader에 터치 좌표 전달
        slime.reactToTouch(at: location)           // 기존 슬라임 변형
    }

    // SlimeScene.swift 내 update
    override func update(_ currentTime: TimeInterval) {
        slime.updateElasticity(currentTime: currentTime)

        if let shader = slime.slimeSprite.shader,
           let timeUniform = shader.uniformNamed("u_time") {
            timeUniform.floatValue = Float(currentTime)
        }
    }
}
