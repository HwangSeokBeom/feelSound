//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/16/25.
//

import SpriteKit
import AVFoundation

class ArcticFoxScene: SKScene {
    
    private var foxAudioEngine: AVAudioEngine?
    private var audioPlayer: AVAudioPlayerNode!
    private var footstepBuffer: AVAudioPCMBuffer?
    
    private var foxNode: SKSpriteNode!
    private var foxState: FoxState = .idle
    private var lastDirection: Direction? = nil
    
    enum FoxState {
        case idle, walking(Direction), resting(Int)
    }
    
    enum Direction: CaseIterable {
        case front, back, left, right
    }
    
    enum CharacterFacingState {
        case normal     // 정면
        case left
        case right
        case resting
    }
    
    // MARK: - Texture Groups
    private struct FoxTextures {
        var tail: [SKTexture] = []
        var sniff: [SKTexture] = []
        var sniffLeft: [SKTexture] = []
        var sniffRight: [SKTexture] = []
        var sniffWhileResting: [SKTexture] = []
        var blink: [SKTexture] = []
        var blinkLeft: [SKTexture] = []
        var blinkRight: [SKTexture] = []
        var blinkResting: [SKTexture] = []
        var jump: [SKTexture] = []
        var front: [SKTexture] = []
        var back: [SKTexture] = []
        var left: [SKTexture] = []
        var right: [SKTexture] = []
        var rest: [SKTexture] = []
        var turnRightToFront: [SKTexture] = []
        var turnLeftToFront: [SKTexture] = []
        var turnFrontToRight: [SKTexture] = []
        var turnFrontToLeft: [SKTexture] = []
    }
    
    private var textures = FoxTextures()
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        setupBackground()
        loadTextures()
        setupFox()
        setupAudio()
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ AVAudioSession 설정 실패: \(error)")
        }

        foxAudioEngine = AVAudioEngine()
        audioPlayer = AVAudioPlayerNode()
        foxAudioEngine!.attach(audioPlayer)

        guard let url = Bundle.main.url(forResource: "walking-through-leaves", withExtension: "wav"),
              let file = try? AVAudioFile(forReading: url) else {
            print("❌ 사운드 파일을 찾을 수 없습니다.")
            return
        }

        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)

        footstepBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        try? file.read(into: footstepBuffer!)

        // 🔄 outputNode로 연결
        foxAudioEngine!.connect(audioPlayer, to: foxAudioEngine!.outputNode, format: format)

        audioPlayer.volume = 1.0

        do {
            try foxAudioEngine!.start()
            print("✅ 오디오 엔진 시작됨")
        } catch {
            print("❌ 오디오 엔진 시작 실패: \(error)")
        }

        if let buffer = footstepBuffer {
            let duration = Double(buffer.frameLength) / buffer.format.sampleRate
            print("🎧 발소리 길이: \(duration)초")
        }
    }
    
    private func playFootstepSound() {
        guard let buffer = footstepBuffer else { return }

        print("🔊 발소리 재생 시도")

        if !audioPlayer.isPlaying {
            audioPlayer.play()
        }

        audioPlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: {
            print("🔁 발소리 재생 완료")
        })
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "북극여우_배경")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -10
        background.size = size
        addChild(background)
    }
    
    private func loadTextures() {
        textures.back = loadSequence("뒤쪽_움직임_", count: 8)
        textures.front = loadSequence("앞쪽_움직임_", count: 8)
        textures.left = loadSequence("왼쪽_움직임_", count: 8)
        textures.right = loadSequence("오른쪽_움직임_", count: 8)
        textures.rest = loadSequence("휴식_", count: 6)
        textures.turnRightToFront = loadSequence("오른쪽으로_걷다가_정면_보기_", count: 6)
        textures.turnLeftToFront = loadSequence("왼쪽으로_걷다가_정면_보기_", count: 6)
        textures.turnFrontToRight = textures.turnRightToFront.reversed()
        textures.turnFrontToLeft = textures.turnLeftToFront.reversed()
        textures.tail = loadSequence("꼬리흔들기_", count: 6)
        textures.sniff = loadSequence("코_냄새_맡기_", count: 2)
        textures.sniffLeft = loadSequence("왼쪽으로_걷다가_코_냄새맡기_", count: 2)
        textures.sniffRight = loadSequence("오른쪽으로_걷다가_코_냄새맡기_", count: 2)
        textures.sniffWhileResting = loadSequence("휴식중_코_냄새맡기_", count: 2)
        textures.blink = loadSequence("눈_깜빡이기_", count: 2)
        textures.blinkLeft = loadSequence("왼쪽으로_걷다가_눈_깜빡이기_", count: 2)
        textures.blinkRight = loadSequence("오른쪽으로_걷다가_눈_깜빡이기_", count: 2)
        textures.blinkResting = loadSequence("휴식중_눈_깜빡이기_", count: 2)
        textures.jump = loadSequence("점프_", count: 6)
    }
    
    private func loadSequence(_ prefix: String, count: Int) -> [SKTexture] {
        return (1...count).map { SKTexture(imageNamed: "\(prefix)\($0)") }
    }
    
    private func setupFox() {
        foxNode = SKSpriteNode(texture: textures.back.first)
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

            let walkTextures = self.texturesFor(direction: direction)
            let walkAnimation = SKAction.animate(with: walkTextures, timePerFrame: 0.1)
            walkAnimation.timingFunction = { pow($0, 0.8) }
            let walkLoop = SKAction.repeatForever(walkAnimation)

            let tiltLoop = SKAction.repeatForever(SKAction.sequence([
                SKAction.rotate(toAngle: 0.005, duration: 0.25, shortestUnitArc: true),
                SKAction.rotate(toAngle: -0.005, duration: 0.25, shortestUnitArc: true)
            ]))

            self.foxNode.run(.group([walkLoop, tiltLoop]), withKey: "walk")
            
            // 🔈 걷기 사운드 타이밍 맞춰 반복 재생
            let walkFrameDuration: TimeInterval = 0.1
            let footstepInterval = SKAction.wait(forDuration: walkFrameDuration * 2) // 약 0.2초마다
            let playFootstep = SKAction.run { [weak self] in
                self?.playFootstepSound()
            }
            let soundLoop = SKAction.repeatForever(SKAction.sequence([footstepInterval, playFootstep]))
            self.foxNode.run(soundLoop, withKey: "footstep")

            let moveDistance: CGFloat = 100
            let clampedTarget = CGPoint(
                x: self.clamp(self.foxNode.position.x + (direction == .left ? -moveDistance : direction == .right ? moveDistance : 0),
                              min: 40, max: self.size.width - 40),
                y: self.clamp(self.foxNode.position.y + (direction == .front ? -moveDistance : direction == .back ? moveDistance : 0),
                              min: 40, max: self.size.height - 40)
            )

            let move = SKAction.move(to: clampedTarget, duration: 2.5)
            move.timingMode = .easeInEaseOut

            let stop = SKAction.run {
                self.foxNode.removeAllActions()
                self.audioPlayer.stop() // 🔇 걷기 중 발소리도 정지
                self.foxNode.texture = (direction == .left || direction == .right)
                    ? walkTextures.last
                    : walkTextures.first
                self.foxNode.zRotation = 0
                self.foxState = .idle
            }

            self.foxNode.run(.sequence([move, stop]), withKey: "move")

            let wait = SKAction.wait(forDuration: 3.0)
            let decideNext = SKAction.run {
                self.lastDirection = direction

                // 👃 확률 기반 냄새 맡기 (왼쪽/오른쪽 방향 한정)
                if direction == .left, .random(probability: 0.3) {
                    self.enterSniffingState(for: .left)
                    return
                }
                if direction == .right, .random(probability: 0.3) {
                    self.enterSniffingState(for: .right)
                    return
                }

                // 👁 확률 기반 눈 깜빡이기 (걷는 방향에 따라 전용 텍스처 사용)
                if direction == .left, .random(probability: 0.3) {
                    self.enterBlinkingState(for: .left)
                    return
                }
                if direction == .right, .random(probability: 0.3) {
                    self.enterBlinkingState(for: .right)
                    return
                }

                // 🎲 랜덤 행동 결정
                let rand = Double.random(in: 0...1)
                switch rand {
                case 0..<0.15:
                    self.enterRestingState()              // 15%
                case 0.15..<0.30:
                    self.enterTailWaggingState()          // 15%
                case 0.30..<0.45:
                    self.enterSniffingState(for: .normal) // 15%
                case 0.45..<0.60:
                    self.enterBlinkingState(for: .normal) // 15%
                case 0.60..<0.75:
                    self.enterJumpingState()              // 15%
                default:
                    self.scheduleNextWalk()               // 나머지 25%
                }
            }

            self.run(.sequence([wait, decideNext]), withKey: "decision")
        }

        if let prev = lastDirection {
            playTurnAnimation(from: prev, to: direction, completion: continueWalk)
        } else {
            continueWalk()
        }
    }
    
    private func playTurnAnimation(from old: Direction, to new: Direction, completion: @escaping () -> Void) {
        let sequence: [SKAction] = {
            switch (old, new) {
            case (.right, .front):
                return [SKAction.animate(with: textures.turnRightToFront, timePerFrame: 0.1)]
            case (.left, .front):
                return [SKAction.animate(with: textures.turnLeftToFront, timePerFrame: 0.1)]
            case (.front, .right):
                return [SKAction.animate(with: textures.turnFrontToRight, timePerFrame: 0.1)]
            case (.front, .left):
                return [SKAction.animate(with: textures.turnFrontToLeft, timePerFrame: 0.1)]
            case (.left, .right):
                return [
                    SKAction.animate(with: textures.turnLeftToFront, timePerFrame: 0.1),
                    SKAction.wait(forDuration: 0.1),
                    SKAction.animate(with: textures.turnFrontToRight, timePerFrame: 0.1)
                ]
            case (.right, .left):
                return [
                    SKAction.animate(with: textures.turnRightToFront, timePerFrame: 0.1),
                    SKAction.wait(forDuration: 0.1),
                    SKAction.animate(with: textures.turnFrontToLeft, timePerFrame: 0.1)
                ]
            default:
                return []
            }
        }()

        guard !sequence.isEmpty else {
            completion()
            return
        }

        let fullSequence = SKAction.sequence(sequence + [.wait(forDuration: 0.3), .run(completion)])
        foxNode.run(fullSequence, withKey: "turning")
    }
    
    private func playLoopAnimation(textures: [SKTexture], repeatCount: Int = 1, resetTo texture: SKTexture? = nil, timePerFrame: TimeInterval = 0.1, waitAfter: TimeInterval = 1.0, key: String, completion: (() -> Void)? = nil) {
        let forward = SKAction.animate(with: textures, timePerFrame: timePerFrame)
        let reverse = SKAction.animate(with: textures.reversed(), timePerFrame: timePerFrame)
        let cycle = SKAction.sequence([forward, reverse])
        let repeated = SKAction.repeat(cycle, count: repeatCount)
        
        var actions: [SKAction] = [repeated]
        if let texture = texture {
            actions.append(.run { [weak self] in self?.foxNode.texture = texture })
        }
        actions.append(.wait(forDuration: waitAfter))
        if let completion = completion {
            actions.append(.run(completion))
        }
        
        foxNode.run(.sequence(actions), withKey: key)
    }
    
    private func enterBlinkingState(for state: CharacterFacingState) {
        let (tex, key): ([SKTexture], String) = {
            switch state {
            case .left: return (textures.blinkLeft, "blinkLeft")
            case .right: return (textures.blinkRight, "blinkRight")
            case .resting: return (textures.blinkResting, "blinkResting")
            case .normal: return (textures.blink, "blink")
            }
        }()
        
        playLoopAnimation(textures: tex, key: key) {
            self.scheduleNextWalk()
        }
    }
    
    private func enterSniffingState(for type: CharacterFacingState) {
        let (tex, key, resetTex): ([SKTexture], String, SKTexture?) = {
            switch type {
            case .left: return (textures.sniffLeft, "sniffingLeft", textures.sniffLeft.first)
            case .right: return (textures.sniffRight, "sniffingRight", textures.sniffRight.first)
            case .resting: return (textures.sniffWhileResting, "sniffWhileResting", textures.rest.first)
            case .normal: return (textures.sniff, "sniffing", textures.sniff.first)
            }
        }()

        foxState = .resting(100 + type.hashValue) // 단순 식별용 숫자, 의미 없음
        foxNode.removeAllActions()
        playLoopAnimation(
            textures: tex,
            repeatCount: 2,
            resetTo: resetTex,
            timePerFrame: 0.25,
            waitAfter: 1.0,
            key: key
        ) {
            self.scheduleNextWalk()
        }
    }
    
    private func enterTailWaggingState() {
        foxState = .resting(1)
        foxNode.removeAllActions()
        
        let wag = SKAction.animate(with: textures.tail, timePerFrame: 0.15)
        let loop = SKAction.sequence([.repeat(wag, count: 2), .wait(forDuration: 0.3)])
        foxNode.run(.sequence([loop, .run { self.foxNode.texture = self.textures.tail.first }, .run(scheduleNextWalk)]), withKey: "tailWagOnly")
    }
    
    private func enterRestingState() {
        foxState = .resting(0)
        foxNode.removeAllActions()

        let restIn = SKAction.animate(with: textures.rest, timePerFrame: 0.1)
        let wait = SKAction.wait(forDuration: 0.5)
        let restOut = SKAction.animate(with: textures.rest.reversed(), timePerFrame: 0.1)
        let resetToFirst = SKAction.run { self.foxNode.texture = self.textures.rest.first }
        let delay = SKAction.wait(forDuration: 3.0)

        let decide = SKAction.run {
            if .random(probability: 0.3) {
                // 💡 rest → sniff 흐름 자연스럽게 이어주기
                self.playRestingSniffTransition()
            } else if .random(probability: 0.3) {
                self.playRestingBlinkTransition()
            } else {
                self.scheduleNextWalk()
            }
        }

        foxNode.run(.sequence([
            restIn, wait, restOut, resetToFirst, delay, decide
        ]), withKey: "resting")
    }
    
    private func playRestingSniffTransition() {
        let restIn = SKAction.animate(with: textures.rest, timePerFrame: 0.1)
        let sniff = SKAction.animate(with: textures.sniffWhileResting, timePerFrame: 0.25)
        let sniffBack = SKAction.animate(with: textures.sniffWhileResting.reversed(), timePerFrame: 0.25)
        let reset = SKAction.run { self.foxNode.texture = self.textures.rest.first }

        let wait = SKAction.wait(forDuration: 1.0)
        let done = SKAction.run { self.scheduleNextWalk() }

        foxNode.run(.sequence([restIn, sniff, sniffBack, reset, wait, done]), withKey: "sniffWhileResting")
    }

    private func playRestingBlinkTransition() {
        let restIn = SKAction.animate(with: textures.rest, timePerFrame: 0.1)
        let blink = SKAction.animate(with: textures.blinkResting, timePerFrame: 0.25)
        let blinkBack = SKAction.animate(with: textures.blinkResting.reversed(), timePerFrame: 0.25)
        let reset = SKAction.run { self.foxNode.texture = self.textures.rest.first }

        let wait = SKAction.wait(forDuration: 1.0)
        let done = SKAction.run { self.scheduleNextWalk() }

        foxNode.run(.sequence([restIn, blink, blinkBack, reset, wait, done]), withKey: "blinkResting")
    }
    
    private func enterJumpingState() {
        foxState = .resting(2)
        foxNode.removeAllActions()

        let jumpTextures = textures.jump
        let jumpAnimation = SKAction.animate(with: jumpTextures, timePerFrame: 0.08)

        // 점프 높이와 시간 설정
        let jumpUp = SKAction.moveBy(x: 0, y: 40, duration: 0.2)
        jumpUp.timingMode = .easeOut

        let fallDown = SKAction.moveBy(x: 0, y: -40, duration: 0.2)
        fallDown.timingMode = .easeIn

        let jumpMotion = SKAction.sequence([jumpUp, fallDown])
        let group = SKAction.group([jumpAnimation, jumpMotion])

        let reset = SKAction.run { [weak self] in
            self?.foxNode.texture = self?.textures.jump.last
        }

        let wait = SKAction.wait(forDuration: 0.01)
        let next = SKAction.run { [weak self] in
            self?.scheduleNextWalk()
        }

        foxNode.run(.sequence([group, reset, wait, next]), withKey: "jump")
    }
    
    private func scheduleNextWalk() {
        run(.sequence([
            .wait(forDuration: .random(in: 0.5...2.0)),
            .run { self.startWalking() }
        ]), withKey: "nextWalk")
    }
    
    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        return Swift.max(min, Swift.min(value, max))
    }
    
    private func texturesFor(direction: Direction) -> [SKTexture] {
        switch direction {
        case .front: return textures.front
        case .back: return textures.back
        case .left: return textures.left
        case .right: return textures.right
        }
    }
    
    private func availableDirections() -> [Direction] {
        let x = foxNode.position.x
        let y = foxNode.position.y
        let margin: CGFloat = foxNode.size.width / 2
        let distance: CGFloat = 100
        var dirs: [Direction] = []
        
        if y + distance + margin <= size.height { dirs.append(.back) }
        if y - distance - margin >= 0 { dirs.append(.front) }
        if x - distance - margin >= 0 { dirs.append(.left) }
        if x + distance + margin <= size.width { dirs.append(.right) }
        return dirs
    }
}

extension Bool {
    static func random(probability: Double) -> Bool {
        return Double.random(in: 0...1) < probability
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
