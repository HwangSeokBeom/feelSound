//
//  SlimeScene.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

import SpriteKit

class SlimeScene: SKScene {
    private var slime: SlimeNode!

    override func didMove(to view: SKView) {
        backgroundColor = .white
        physicsWorld.gravity = .zero
        slime = SlimeNode(radius: 80)
        slime.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(slime)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        slime.reactToTouch(at: location) 
    }
    
    override func update(_ currentTime: TimeInterval) {
        slime.updateElasticity()
    }
}
