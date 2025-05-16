//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/16/25.
//

import SpriteKit

class ArcticFoxScene: SKScene {

    private var foxNode: SKSpriteNode!
    private var foxState: FoxState = .idle
    private var lastDirection: Direction? = nil

    private var frontTextures: [SKTexture] = []
    private var backTextures: [SKTexture] = []
    private var leftTextures: [SKTexture] = []
    private var rightTextures: [SKTexture] = []
    private var restTextures: [SKTexture] = []

    private var turnFromRightToFrontTextures: [SKTexture] = []
    private var turnFromLeftToFrontTextures: [SKTexture] = []
    private var turnFromFrontToRightTextures: [SKTexture] = []
    private var turnFromFrontToLeftTextures: [SKTexture] = []

    enum FoxState {
        case idle, walking(Direction), resting(Int)
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
        restTextures = (1...6).map { SKTexture(imageNamed: "휴식_\($0)") }

        turnFromRightToFrontTextures = (1...6).map { SKTexture(imageNamed: "오른쪽으로_걷다가_정면_보기_\($0)") }
        turnFromLeftToFrontTextures = (1...6).map { SKTexture(imageNamed: "왼쪽으로_걷다가_정면_보기_\($0)") }

        // 역순으로 재생하기 위한 시퀀스
        turnFromFrontToRightTextures = turnFromRightToFrontTextures.reversed()
        turnFromFrontToLeftTextures = turnFromLeftToFrontTextures.reversed()
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

        let continueWalk = { [weak self] in
            guard let self = self else { return }
            self.foxState = .walking(direction)
            self.foxNode.removeAllActions()

            let textures = self.texturesFor(direction: direction)
            let walkAnimation = SKAction.repeatForever(
                SKAction.animate(with: textures, timePerFrame: 0.15)
            )
            self.foxNode.run(walkAnimation, withKey: "walk")

            let moveDistance: CGFloat = 100
            let clampedTargetPosition = CGPoint(
                x: self.clamp(self.foxNode.position.x + (direction == .left ? -moveDistance : direction == .right ? moveDistance : 0),
                              min: 40, max: self.size.width - 40),
                y: self.clamp(self.foxNode.position.y + (direction == .front ? -moveDistance : direction == .back ? moveDistance : 0),
                              min: 40, max: self.size.height - 40)
            )

            let moveAction = SKAction.move(to: clampedTargetPosition, duration: 3.0)
            moveAction.timingMode = .easeInEaseOut

            let stopWalking = SKAction.run {
                self.foxNode.removeAction(forKey: "walk")

                let textures = self.texturesFor(direction: direction)
                switch direction {
                case .front, .back:
                    self.foxNode.texture = textures.first
                case .left, .right:
                    self.foxNode.texture = textures.last
                }

                self.foxState = .idle
            }

            let moveAndStop = SKAction.sequence([moveAction, stopWalking])
            self.foxNode.run(moveAndStop, withKey: "move")

            let wait = SKAction.wait(forDuration: 3.0)
            let next = SKAction.run {
                if Bool.random(probability: 0.25) {
                    self.enterRestingState()
                } else {
                    self.scheduleNextWalk()
                }
            }
            self.run(SKAction.sequence([wait, next]), withKey: "decision")

            self.lastDirection = direction
        }
        
        if let previous = lastDirection {
            playTurnAnimation(from: previous, to: direction, completion: continueWalk)
        } else {
            continueWalk()
        }
    }

    private func playTurnAnimation(from old: Direction, to new: Direction, completion: @escaping () -> Void) {
        foxNode.removeAllActions()

        let textures: [SKTexture]
        switch (old, new) {
        case (.right, .front): textures = turnFromRightToFrontTextures
        case (.left, .front): textures = turnFromLeftToFrontTextures
        case (.front, .right): textures = turnFromFrontToRightTextures
        case (.front, .left): textures = turnFromFrontToLeftTextures
        default:
            completion()
            return
        }

        let turnAnimation = SKAction.animate(with: textures, timePerFrame: 0.12)
        let wait = SKAction.wait(forDuration: 0.3)
        let resume = SKAction.run(completion)
        foxNode.run(SKAction.sequence([turnAnimation, wait, resume]), withKey: "turning")
    }

    private func enterRestingState() {
        foxState = .resting(0)
        foxNode.removeAllActions()

        let forward = SKAction.animate(with: restTextures, timePerFrame: 0.12)
        let pauseAtEnd = SKAction.wait(forDuration: 0.5)
        let backward = SKAction.animate(with: restTextures.dropLast().reversed(), timePerFrame: 0.12)
        let setFirstTexture = SKAction.run { [weak self] in
            self?.foxNode.texture = self?.restTextures.first
        }
        let wait = SKAction.wait(forDuration: 1.5)
        let resume = SKAction.run { [weak self] in
            self?.scheduleNextWalk()
        }

        let restSequence = SKAction.sequence([
            forward,
            pauseAtEnd,
            backward,
            setFirstTexture,
            wait,
            resume
        ])

        foxNode.run(restSequence, withKey: "resting")
    }

    private func scheduleNextWalk() {
        let delay = Double.random(in: 2.0...4.0)
        let wait = SKAction.wait(forDuration: delay)
        let start = SKAction.run { [weak self] in self?.startWalking() }
        run(SKAction.sequence([wait, start]), withKey: "nextWalk")
    }

    private func moveFoxSafely(by vector: CGVector) {
        let newPosition = CGPoint(
            x: clamp(foxNode.position.x + vector.dx, min: 40, max: size.width - 40),
            y: clamp(foxNode.position.y + vector.dy, min: 40, max: size.height - 40)
        )
        foxNode.position = newPosition
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

// 확률 기반 Bool 생성
extension Bool {
    static func random(probability: Double) -> Bool {
        return Double.random(in: 0...1) < probability
    }
}

// 안전한 인덱싱을 위한 확장
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
