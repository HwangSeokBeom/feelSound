//
//  Untitled.swift
//  MovingCharacter
//
//  Created by Hwangseokbeom on 5/7/25.
//

import SpriteKit

class GameScene: SKScene {
    private var character: SKSpriteNode!
    private var wheelNode: SKSpriteNode!
    private var food: SKSpriteNode?
    
    private var walkTextures: [SKTexture] = []
    private var noseTextures: [SKTexture] = []
    private var hornTextures: [SKTexture] = []
    private var earTextures: [SKTexture] = []
    private var legTextures: [SKTexture] = []
    private var wheelRunTextures: [SKTexture] = []
    
    private var isEating = false
    private var isRunningWheel = false
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "배경")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = self.size
        background.zPosition = -10
        addChild(background)
        
        loadTextures() // 먼저 텍스처를 로드해야 wheelRunTextures 사용 가능

        // wheelNode 직접 생성 및 할당
        wheelNode = SKSpriteNode(imageNamed: "쳇바퀴")
        wheelNode.size = CGSize(width: 144, height: 187)
        let wheelX = size.width * 0.25
        let wheelY = size.height * (2.0 / 3.0)
        wheelNode.position = CGPoint(x: wheelX, y: wheelY)
        wheelNode.zPosition = -5
        wheelNode.name = "wheel"
        addChild(wheelNode)
        
        character = SKSpriteNode(texture: walkTextures.first)
        character.size = CGSize(width: 80, height: 80)
        character.position = CGPoint(x: size.width / 2, y: size.height / 2)
        character.zPosition = 0
        addChild(character)
        
        runFreeMovement()
    }
    
    private func loadTextures() {
        walkTextures = (1...8).map { SKTexture(imageNamed: "움직임_\($0)") }
        noseTextures = (1...3).map { SKTexture(imageNamed: "코움직임_\($0)") }
        hornTextures = (1...8).map { SKTexture(imageNamed: "뿔움직임_\($0)") }
        earTextures = (1...8).map { SKTexture(imageNamed: "귀 쫑긋_\($0)") }
        legTextures = (1...8).map { SKTexture(imageNamed: "누웠을때 다리를 움직이는_\($0)") }
        wheelRunTextures = (1...8).map { SKTexture(imageNamed: "쳇바퀴_\($0)") }
    }
    
    func spawnFood() {
        guard food == nil else { return }
        
        let foodNode = SKSpriteNode(imageNamed: "사과")
        foodNode.size = CGSize(width: 40, height: 40)
        foodNode.position = CGPoint(
            x: CGFloat.random(in: 50...(size.width - 50)),
            y: CGFloat.random(in: 100...(size.height - 100))
        )
        addChild(foodNode)
        food = foodNode
        
        moveToFood()
    }
    
    private func moveToFood() {
        guard let food = food else { return }

        character.xScale = food.position.x < character.position.x ? -1 : 1

        let move = SKAction.move(to: food.position, duration: 1.0)
        let eat = SKAction.run { [weak self] in
            guard let self = self, let food = self.food else { return }
            self.isEating = true
            self.character.removeAllActions()

            // 사과 즉시 제거
            food.removeFromParent()
            self.food = nil

            // 먹이 먹는 애니메이션 텍스처 (변경된 순서)
            let eatTextures = [
                SKTexture(imageNamed: "냐암"),
                SKTexture(imageNamed: "오"),
                SKTexture(imageNamed: "물"),
                SKTexture(imageNamed: "오"),
                SKTexture(imageNamed: "물"),
                SKTexture(imageNamed: "오"),
                SKTexture(imageNamed: "물"),
                SKTexture(imageNamed: "오"),
                SKTexture(imageNamed: "물")
            ]
            let eatingAction = SKAction.animate(with: eatTextures, timePerFrame: 0.3)

            self.character.run(eatingAction) {
                self.isEating = false
                self.runFreeMovement()
            }
        }

        character.removeAllActions()
        let walkAnimation = SKAction.repeatForever(SKAction.animate(with: walkTextures, timePerFrame: 0.1))
        character.run(walkAnimation, withKey: "walk")
        character.run(SKAction.sequence([move, eat]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)
        
        if tappedNode.name == "wheel" {
            toggleWheelRunning()
        }
    }
    
    private func toggleWheelRunning() {
        let wheelFrontPosition = CGPoint(x: wheelNode.position.x, y: wheelNode.position.y + 10)

        if isRunningWheel {
            // 정지 로직
            wheelNode.removeAllActions()
            wheelNode.texture = SKTexture(imageNamed: "쳇바퀴") // 원래 이미지로 복귀

            character.position = wheelFrontPosition
            character.isHidden = false
            isRunningWheel = false
            runFreeMovement()
        } else {
            // 고슴도치 이동 후 애니메이션 시작
            character.removeAllActions()
            character.xScale = wheelFrontPosition.x < character.position.x ? -1 : 1
            character.run(SKAction.move(to: wheelFrontPosition, duration: 0.6)) { [weak self] in
                guard let self = self else { return }
                self.character.isHidden = true
                let animation = SKAction.repeatForever(
                    SKAction.animate(with: self.wheelRunTextures, timePerFrame: 0.1)
                )
                self.wheelNode.run(animation)
                self.isRunningWheel = true
            }
        }
    }
    
    private func runFreeMovement() {
        guard !isEating else { return }
        
        // 25% 확률로 랜덤 동작 실행
        if Int.random(in: 0..<4) == 0 {
            runRandomAction {
                self.runFreeMovement() // 애니메이션 끝나고 다시 이동
            }
            return
        }
        
        let randomDx = CGFloat.random(in: -100...100)
        let randomDy = CGFloat.random(in: -100...100)
        let newX = max(40, min(character.position.x + randomDx, size.width - 40))
        let newY = max(80, min(character.position.y + randomDy, size.height - 80))
        let destination = CGPoint(x: newX, y: newY)
        
        character.xScale = destination.x < character.position.x ? -1 : 1
        
        let move = SKAction.move(to: destination, duration: 1.0)
        let wait = SKAction.wait(forDuration: 0.5)
        
        character.removeAction(forKey: "walk")
        let walkAnimation = SKAction.repeatForever(SKAction.animate(with: walkTextures, timePerFrame: 0.1))
        character.run(walkAnimation, withKey: "walk")
        
        let sequence = SKAction.sequence([move, wait, SKAction.run { [weak self] in self?.runFreeMovement() }])
        character.run(sequence, withKey: "move")
    }
    
    private func runRandomAction(completion: @escaping () -> Void) {
        let (textures, key) = pickRandomAnimation()
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        let sequence = SKAction.sequence([
            animation,
            SKAction.run(completion)
        ])
        character.removeAllActions()
        character.run(sequence, withKey: key)
    }
    
    private func pickRandomAnimation() -> ([SKTexture], String) {
        switch Int.random(in: 0..<4) {
        case 0: return (legTextures, "leg")
        case 1: return (earTextures, "ear")
        case 2: return (hornTextures, "horn")
        case 3: return (noseTextures, "nose")
        default: return (walkTextures, "walk")
        }
    }
}
