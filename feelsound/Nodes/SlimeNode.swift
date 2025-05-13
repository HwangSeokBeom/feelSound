//  SlimeNode.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.

import SpriteKit
import simd

class SlimeNode: SKCropNode {
    private var shapeMask: SKShapeNode = SKShapeNode()
    let slimeSprite: SKSpriteNode
    private var controlPoints: [CGPoint] = []
    private var originPoints: [CGPoint] = []
    private var velocities: [CGVector] = []

    init(radius: CGFloat, texture: SKTexture) {
        // 1. 슬라임 텍스처 sprite 생성
        slimeSprite = SKSpriteNode(texture: texture, color: .clear, size: CGSize(width: radius * 2, height: radius * 2))
        slimeSprite.zPosition = 0

        super.init()

        // 2. 셰이더 부착 (TeasEar 스타일 파동 추가)
        let shaderSource = """
        void main() {
            vec2 uv = v_tex_coord;

            vec2 center = u_touch;
            float dist = distance(uv, center);

            float ripple = sin((dist * 40.0 - u_time * 6.0)) * 0.015 / (dist * 40.0 + 1.0);
            uv.x += ripple;
            uv.y += ripple * 0.6;

            uv.x += sin((uv.y + u_time * 1.5) * 15.0) * 0.01;

            gl_FragColor = texture2D(u_texture, uv);
        }
        """

        let shader = SKShader(source: shaderSource)
        shader.uniforms = [
            SKUniform(name: "u_time", float: 0.0),
            SKUniform(name: "u_touch", vectorFloat2: vector_float2(0.5, 0.5))
        ]
        slimeSprite.shader = shader

        // 3. 곡선 마스크 생성
        shapeMask.fillColor = .white
        shapeMask.strokeColor = .clear
        shapeMask.zPosition = 1

        addChild(slimeSprite)
        maskNode = shapeMask

        generateCirclePoints(radius: radius)
        updateMaskPath()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reactToTouch(at point: CGPoint) {
        for i in 0..<controlPoints.count {
            let dist = hypot(controlPoints[i].x - point.x, controlPoints[i].y - point.y)
            if dist < 100 {
                let offset = CGVector(dx: point.x - controlPoints[i].x,
                                      dy: point.y - controlPoints[i].y)
                velocities[i].dx += offset.dx * 0.4
                velocities[i].dy += offset.dy * 0.4
            }
        }
    }

    func updateElasticity(currentTime: TimeInterval) {
        for i in 0..<controlPoints.count {
            let spring = CGVector(dx: originPoints[i].x - controlPoints[i].x,
                                  dy: originPoints[i].y - controlPoints[i].y)
            velocities[i].dx += spring.dx * 0.1
            velocities[i].dy += spring.dy * 0.1
            velocities[i].dx *= 0.85
            velocities[i].dy *= 0.85

            controlPoints[i].x += velocities[i].dx
            controlPoints[i].y += velocities[i].dy
        }
        updateMaskPath()

        // shader 시간 업데이트
        if let shader = slimeSprite.shader,
           let timeUniform = shader.uniformNamed("u_time") {
            timeUniform.floatValue = Float(currentTime)
        }
    }

    func updateTouchUniform(at point: CGPoint) {
        let size = slimeSprite.size
        let normalized = vector_float2(
            Float((point.x + size.width / 2) / size.width),
            Float((point.y + size.height / 2) / size.height)
        )

        if let shader = slimeSprite.shader,
           let touchUniform = shader.uniformNamed("u_touch") {
            touchUniform.vectorFloat2Value = normalized
        }
    }

    private func updateMaskPath() {
        let path = UIBezierPath()
        guard controlPoints.count > 1 else { return }

        for i in 0..<controlPoints.count {
            let current = controlPoints[i]
            let next = controlPoints[(i + 1) % controlPoints.count]
            let mid = CGPoint(x: (current.x + next.x) / 2, y: (current.y + next.y) / 2)

            if i == 0 {
                path.move(to: mid)
            }
            path.addQuadCurve(to: mid, controlPoint: current)
        }
        path.close()
        shapeMask.path = path.cgPath
    }

    private func generateCirclePoints(radius: CGFloat) {
        controlPoints.removeAll()
        originPoints.removeAll()
        velocities.removeAll()

        let count = 24
        for i in 0..<count {
            let angle = CGFloat(i) / CGFloat(count) * .pi * 2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            controlPoints.append(point)
            originPoints.append(point)
            velocities.append(.zero)
        }
    }
}
