//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/13/25.
//

// SlimeEffectsScene.swift
// SpriteKit-based demo for various slime effects

import SpriteKit

class SlimeEffectsScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        physicsWorld.gravity = .zero

        // 각 효과를 보여줄 슬라임 노드들을 배치
        createJellySlime(at: CGPoint(x: 100, y: 600))
        createGlitterSlime(at: CGPoint(x: 300, y: 600))
        createWaterSlime(at: CGPoint(x: 100, y: 400))
        createBubbleSlime(at: CGPoint(x: 300, y: 400))
        createElasticSlime(at: CGPoint(x: 100, y: 200))
        createCrawlingSlime(at: CGPoint(x: 300, y: 200))
        createMagneticSlime(at: CGPoint(x: 500, y: 400))
        createMeltingSlime(at: CGPoint(x: 500, y: 200))
    }

    // 1. Jelly Slime
    func createJellySlime(at position: CGPoint) {
        let node = SKShapeNode(circleOfRadius: 40)
        node.position = position
        node.fillColor = .green
        node.physicsBody = SKPhysicsBody(circleOfRadius: 40)
        node.physicsBody?.restitution = 0.8
        addChild(node)
    }

    // 2. Glitter Slime
    func createGlitterSlime(at position: CGPoint) {
        let texture = SKTexture(imageNamed: "glitter_texture")
        let node = SKSpriteNode(texture: texture, size: CGSize(width: 80, height: 80))
        node.position = position
        node.shader = SKShader(source: """
            void main() {
                vec2 uv = v_tex_coord;
                vec4 color = texture2D(u_texture, uv);
                float glitter = step(0.95, fract(sin(dot(uv * 100.0, vec2(12.9898, 78.233))) * 43758.5453));
                gl_FragColor = vec4(color.rgb + glitter * 0.3, color.a);
            }
        """)
        addChild(node)
    }

    // 3. Water Slime (flowing)
    func createWaterSlime(at position: CGPoint) {
        let node = SKShapeNode(circleOfRadius: 40)
        node.position = position
        node.fillColor = .cyan
        node.alpha = 0.7
        node.physicsBody = SKPhysicsBody(circleOfRadius: 40)
        node.physicsBody?.affectedByGravity = true
        addChild(node)
    }

    // 4. Bubble Slime
    func createBubbleSlime(at position: CGPoint) {
        guard let emitter = SKEmitterNode(fileNamed: "Bubble.sks") else {
            print("❗️[ERROR] Bubble.sks 파일을 찾을 수 없습니다.")
            return
        }
        emitter.position = position
        addChild(emitter)
    }

    // 5. Elastic Bounce Slime
    func createElasticSlime(at position: CGPoint) {
        let node = SKShapeNode(circleOfRadius: 40)
        node.position = position
        node.fillColor = .magenta
        node.physicsBody = SKPhysicsBody(circleOfRadius: 40)
        node.physicsBody?.restitution = 1.0
        node.physicsBody?.linearDamping = 0.2
        node.physicsBody?.applyImpulse(CGVector(dx: 10, dy: 100))
        addChild(node)
    }

    // 6. Crawling Slime
    func createCrawlingSlime(at position: CGPoint) {
        let node = SKShapeNode(rectOf: CGSize(width: 80, height: 20), cornerRadius: 10)
        node.position = position
        node.fillColor = .orange
        addChild(node)

        let crawl = SKAction.sequence([
            SKAction.moveBy(x: 40, y: 0, duration: 1),
            SKAction.moveBy(x: -40, y: 0, duration: 1)
        ])
        node.run(SKAction.repeatForever(crawl))
    }

    // 7. Magnetic Slime
    func createMagneticSlime(at position: CGPoint) {
        let node = SKShapeNode(circleOfRadius: 40)
        node.position = position
        node.fillColor = .blue
        node.physicsBody = SKPhysicsBody(circleOfRadius: 40)
        addChild(node)

        let field = SKFieldNode.radialGravityField()
        field.position = CGPoint(x: position.x, y: position.y + 100)
        field.strength = 5
        field.falloff = 1
        addChild(field)
    }

    // 8. Melting Slime
    func createMeltingSlime(at position: CGPoint) {
        let node = SKShapeNode(circleOfRadius: 40)
        node.position = position
        node.fillColor = .yellow
        addChild(node)

        let melt = SKAction.sequence([
            SKAction.scaleY(to: 0.1, duration: 2),
            SKAction.fadeAlpha(to: 0, duration: 1),
            SKAction.removeFromParent()
        ])
        node.run(melt)
    }
}
