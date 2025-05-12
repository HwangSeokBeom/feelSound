//
//  SlimeNode.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

import SpriteKit

class SlimeNode: SKShapeNode {
    private let baseRadius: CGFloat = 80

    override init() {
        super.init()
        path = CGPath(ellipseIn: CGRect(x: -baseRadius, y: -baseRadius, width: baseRadius * 2, height: baseRadius * 2), transform: nil)
        fillColor = .green
        strokeColor = .clear
        physicsBody = SKPhysicsBody(circleOfRadius: baseRadius)
        physicsBody?.isDynamic = true
        physicsBody?.restitution = 0.6
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reactToTouch(at point: CGPoint) {
        let dx = point.x - position.x
        let dy = point.y - position.y
        let vector = CGVector(dx: dx * 0.1, dy: dy * 0.1)
        physicsBody?.applyForce(vector)
    }
}
