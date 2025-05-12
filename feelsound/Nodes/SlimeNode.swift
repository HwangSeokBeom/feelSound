//
//  SlimeNode.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

import SpriteKit

class SlimeNode: SKShapeNode {
    private var points: [CGPoint] = []
    private var originPoints: [CGPoint] = []

    init(radius: CGFloat, texture: SKTexture) {
        super.init()

        // 점 생성 (12각형)
        for i in 0..<12 {
            let angle = CGFloat(i) / 12 * 2 * .pi
            let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            points.append(point)
            originPoints.append(point)
        }

        updatePath()

        // 텍스처와 컬러 설정
        fillColor = .white
        fillTexture = texture
        strokeColor = .clear
        zPosition = 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reactToTouch(at point: CGPoint) {
        let localPoint = convert(point, from: parent!)
        var closestIndex = 0
        var closestDistance = CGFloat.greatestFiniteMagnitude

        for (i, p) in points.enumerated() {
            let distance = hypot(p.x - localPoint.x, p.y - localPoint.y)
            if distance < closestDistance {
                closestIndex = i
                closestDistance = distance
            }
        }

        deform(at: closestIndex, to: localPoint)
    }

    func deform(at index: Int, to position: CGPoint) {
        guard index < points.count else { return }
        points[index] = position
        updatePath()
    }

    func updateElasticity() {
        let speed: CGFloat = 0.1
        for i in 0..<points.count {
            points[i].x += (originPoints[i].x - points[i].x) * speed
            points[i].y += (originPoints[i].y - points[i].y) * speed
        }
        updatePath()
    }

    private func updatePath() {
        let path = UIBezierPath()
        guard let first = points.first else { return }
        path.move(to: first)
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        path.close()
        self.path = path.cgPath
    }
}
