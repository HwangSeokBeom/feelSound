//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/16/25.
//

import SpriteKit

class ArcticFoxScene1: SKScene {

    private var foxNode: SKSpriteNode!
    private var foxState: FoxState = .idle
    private var lastDirection: Direction? = nil

    private var frontTextures: [SKTexture] = []
    private var backTextures: [SKTexture] = []
    private var leftTextures: [SKTexture] = []
    private var rightTextures: [SKTexture] = []
    private var restTexture: SKTexture? = nil

    enum FoxState {
        case idle, walking(Direction), resting
    }

    enum Direction: CaseIterable {
        case front, back, left, right
    }

    override func didMove(to view: SKView) {
        setupBackground()
        loadTextures()
        setupFox()
    }

    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "북극여우_배경")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -10
        background.size = size
        addChild(background)
    }

    private func loadTextures() {
        backTextures = (1...8).map { SKTexture(imageNamed: "뒤쪽_움직임_\($0)") }
        frontTextures = (1...8).map { SKTexture(imageNamed: "앞쪽_움직임_\($0)") }
        leftTextures = (1...8).map { SKTexture(imageNamed: "왼쪽_움직임_\($0)") }
        rightTextures = (1...8).map { SKTexture(imageNamed: "오른쪽_움직임_\($0)") }
        restTexture = SKTexture(imageNamed: "휴식_6") // 👈 6번 프레임 고정 사용
    }

    private func setupFox() {
        foxNode = SKSpriteNode(texture: backTextures.first)
        foxNode.position = CGPoint(x: size.width * 0.5, y: size.height * 0.3)
        foxNode.zPosition = 1
        foxNode.size = CGSize(width: 80, height: 80)
        addChild(foxNode)

        startWalking()
    }

    private func startWalking() {
        let possibleDirections = availableDirections()
        guard let direction = possibleDirections.randomElement() else {
            scheduleNextWalk()
            return
        }

        foxState = .walking(direction)
        foxNode.removeAllActions()

        let textures = texturesFor(direction: direction)
        let walkAnimation = SKAction.repeatForever(
            SKAction.animate(with: textures, timePerFrame: 0.15)
        )
        foxNode.run(walkAnimation, withKey: "walk")

        let moveDistance: CGFloat = 100
        let clampedTargetPosition = CGPoint(
            x: clamp(foxNode.position.x + (direction == .left ? -moveDistance : direction == .right ? moveDistance : 0),
                     min: 40, max: size.width - 40),
            y: clamp(foxNode.position.y + (direction == .front ? -moveDistance : direction == .back ? moveDistance : 0),
                     min: 40, max: size.height - 40)
        )

        let moveAction = SKAction.move(to: clampedTargetPosition, duration: 3.0)
        moveAction.timingMode = .easeInEaseOut

        let stopWalking = SKAction.run {
            self.foxNode.removeAction(forKey: "walk")
            
            let textures = self.texturesFor(direction: direction)
            switch direction {
            case .front, .back:
                self.foxNode.texture = textures.first // 👉 1번 텍스처로 고정
            case .left, .right:
                self.foxNode.texture = textures.last // 👉 8번 텍스처로 고정
            }

            self.foxState = .idle
        }

        let moveAndStop = SKAction.sequence([moveAction, stopWalking])
        foxNode.run(moveAndStop, withKey: "move")

        let wait = SKAction.wait(forDuration: 3.0)
        let decision = SKAction.run {
            if Bool.random(probability: 0.25) {
                self.enterRestingState()
            } else {
                self.scheduleNextWalk()
            }
        }
        run(SKAction.sequence([wait, decision]), withKey: "decision")

        lastDirection = direction
    }

    private func enterRestingState() {
        foxState = .resting
        foxNode.removeAllActions()
        if let rest = restTexture {
            foxNode.texture = rest
        }

        let wait = SKAction.wait(forDuration: 2.0) // 정지 시간 조정 가능
        let resume = SKAction.run { [weak self] in
            self?.scheduleNextWalk()
        }

        foxNode.run(SKAction.sequence([wait, resume]), withKey: "rest")
    }

    private func scheduleNextWalk() {
        let delay = Double.random(in: 2.0...4.0)
        let wait = SKAction.wait(forDuration: delay)
        let start = SKAction.run { [weak self] in self?.startWalking() }
        run(SKAction.sequence([wait, start]), withKey: "nextWalk")
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        return Swift.max(min, Swift.min(value, max))
    }

    private func availableDirections() -> [Direction] {
        var directions: [Direction] = []
        let margin: CGFloat = foxNode.size.width / 2
        let moveDistance: CGFloat = 100
        let x = foxNode.position.x
        let y = foxNode.position.y

        if y + moveDistance + margin <= size.height { directions.append(.back) }
        if y - moveDistance - margin >= 0 { directions.append(.front) }
        if x - moveDistance - margin >= 0 { directions.append(.left) }
        if x + moveDistance + margin <= size.width { directions.append(.right) }

        return directions
    }

    private func texturesFor(direction: Direction) -> [SKTexture] {
        switch direction {
        case .front: return frontTextures
        case .back: return backTextures
        case .left: return leftTextures
        case .right: return rightTextures
        }
    }
}

