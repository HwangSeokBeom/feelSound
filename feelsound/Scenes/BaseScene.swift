//
//  BaseScene.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

// BaseScene.swift
// 공통 Scene 기능 정의

import SpriteKit

class BaseScene: SKScene {
    var character: SKSpriteNode!
    var wheelNode: SKSpriteNode!
    var feedButton: SKSpriteNode!
    var cleanButton: SKSpriteNode!
    var poopTexture: SKTexture!
    var foods: [SKSpriteNode] = []
    
    var walkTextures: [SKTexture] = []
    var noseTextures: [SKTexture] = []
    var hornTextures: [SKTexture] = []
    var earTextures: [SKTexture] = []
    var legTextures: [SKTexture] = []
    var wheelRunTextures: [SKTexture] = []
    
    var isEating = false
    var isRunningWheel = false
    
    enum CharacterAction {
        case idle, movingToFood, eating, runningOnWheel
    }
    var currentAction: CharacterAction = .idle
    
    enum WheelType: String {
        case indoor = "쳇바퀴"
        case outdoor = "쳇바퀴_야외"
    }
    
    var wheelType: WheelType { .indoor }
    
    var wheelIdleTextureName: String {
        return wheelType.rawValue
    }
    
    override func didMove(to view: SKView) {
        setupScene()
    }
    
    func setupScene() {
        loadTextures()
        setupBackground()
        setupButtons()
        setupCharacter()
        setupWheel()
        setupEnvironment()
        runFreeMovement()
    }
    
    func setupBackground() {}
    func setupEnvironment() {} // override 필요
    func setupWheel() {}       // override 필요
    
    func presentScene(scene: SKScene, transition: SKTransition = .fade(withDuration: 1.0)) {
        scene.scaleMode = .resizeFill
        self.view?.presentScene(scene, transition: transition)
    }
    
    func loadTextures() {
        walkTextures = loadTextureArray(prefix: "움직임_", count: 8)
        noseTextures = loadTextureArray(prefix: "코움직임_", count: 3)
        earTextures = loadTextureArray(prefix: "귀 쫑긋_", count: 8)
        wheelRunTextures = loadTextureArray(prefix: "쳇바퀴_", count: 8)
        poopTexture = SKTexture(imageNamed: "임시똥")
    }
    
    func loadTextureArray(prefix: String, count: Int) -> [SKTexture] {
        return (1...count).map { SKTexture(imageNamed: "\(prefix)\($0)") }
    }
    
    func setupCharacter() {
        character = SKSpriteNode(texture: walkTextures.first)
        character.size = CGSize(width: 80, height: 80)
        character.position = CGPoint(x: size.width / 2, y: size.height / 2)
        character.zPosition = 0
        addChild(character)
    }
    
    func setupButtons() {
        let buttonSize = CGSize(width: 80, height: 80)
        
        feedButton = SKSpriteNode(imageNamed: "먹이주기")
        feedButton.name = "feed"
        feedButton.size = buttonSize
        feedButton.position = CGPoint(x: 60, y: 100)
        feedButton.zPosition = 10
        addChild(feedButton)
        
        cleanButton = SKSpriteNode(imageNamed: "청소하기")
        cleanButton.name = "clean"
        cleanButton.size = buttonSize
        cleanButton.position = CGPoint(x: 65, y: 180)
        cleanButton.zPosition = 10
        addChild(cleanButton)
    }
    
    func runFreeMovement() {
        guard !isEating, currentAction == .idle else { return }
        
        if Int.random(in: 0..<4) == 0 {
            runRandomAction { self.runFreeMovement() }
            return
        }
        
        if Int.random(in: 0..<20) == 0 {
            dropPoop()
        }
        
        let bounds = actionAreaBounds(for: size)
        let halfWidth = character.size.width / 2
        let halfHeight = character.size.height / 2
        
        let randomDx = CGFloat.random(in: -80...80)
        let randomDy = CGFloat.random(in: -80...80)
        
        let newX = max(bounds.minX + halfWidth, min(character.position.x + randomDx, bounds.maxX - halfWidth))
        let newY = max(bounds.minY + halfHeight, min(character.position.y + randomDy, bounds.maxY - halfHeight))
        let destination = CGPoint(x: newX, y: newY)
        
        character.xScale = destination.x < character.position.x ? -1 : 1
        
        let move = SKAction.move(to: destination, duration: 2.0)
        let wait = SKAction.wait(forDuration: 0.5)
        
        character.removeAction(forKey: "walk")
        let walkAnimation = SKAction.repeatForever(SKAction.animate(with: walkTextures, timePerFrame: 0.1))
        character.run(walkAnimation, withKey: "walk")
        
        let sequence = SKAction.sequence([move, wait, SKAction.run { [weak self] in self?.runFreeMovement() }])
        character.run(sequence, withKey: "move")
    }
    
    func spawnFood() {
        let bounds = actionAreaBounds(for: size)
        let halfFoodWidth: CGFloat = 20
        let halfFoodHeight: CGFloat = 20
        
        let minX = bounds.minX + halfFoodWidth
        let maxX = bounds.maxX - halfFoodWidth
        let minY = bounds.minY + halfFoodHeight
        let maxY = bounds.maxY - halfFoodHeight
        
        let foodNode = SKSpriteNode(imageNamed: "사과")
        foodNode.size = CGSize(width: 40, height: 40)
        foodNode.position = CGPoint(x: CGFloat.random(in: minX...maxX), y: CGFloat.random(in: minY...maxY))
        foodNode.name = "food"
        foodNode.zPosition = 1
        addChild(foodNode)
        foods.append(foodNode)
        
        if currentAction == .idle {
            moveToFood()
        }
    }
    
    func moveToFood() {
        guard !foods.isEmpty, currentAction == .idle else { return }
        
        guard let nearestFood = foods.min(by: {
            $0.position.distance(to: character.position) < $1.position.distance(to: character.position)
        }) else { return }
        
        currentAction = .movingToFood
        character.xScale = nearestFood.position.x < character.position.x ? -1 : 1
        
        let move = SKAction.move(to: nearestFood.position, duration: 2.0)
        let eat = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isEating = true
            self.character.removeAllActions()
            
            nearestFood.removeFromParent()
            self.foods.removeAll { $0 == nearestFood }
            self.currentAction = .eating
            
            let eatTextures = ["냐암", "오", "물", "오", "물"].flatMap { name in
                [SKTexture(imageNamed: name), SKTexture(imageNamed: name)]
            }
            let eatingAction = SKAction.animate(with: eatTextures, timePerFrame: 0.3)
            
            self.character.run(eatingAction) {
                self.isEating = false
                self.currentAction = .idle
                self.runFreeMovement()
                if !self.foods.isEmpty {
                    self.moveToFood()
                }
            }
        }
        
        character.removeAllActions()
        let walkAnimation = SKAction.repeatForever(SKAction.animate(with: walkTextures, timePerFrame: 0.1))
        character.run(walkAnimation, withKey: "walk")
        character.run(SKAction.sequence([move, eat]))
    }

    func toggleWheelRunning() {
        let wheelFrontPosition = CGPoint(x: wheelNode.position.x, y: wheelNode.position.y + 10)
        
        if isRunningWheel {
            wheelNode.removeAllActions()
            wheelNode.texture = SKTexture(imageNamed: self.wheelIdleTextureName) // ✅ 수정된 부분
            character.position = wheelFrontPosition
            character.isHidden = false
            isRunningWheel = false
            currentAction = .idle
            runFreeMovement()
        } else {
            currentAction = .runningOnWheel
            character.removeAllActions()
            character.xScale = wheelFrontPosition.x < character.position.x ? -1 : 1
            character.run(SKAction.move(to: wheelFrontPosition, duration: 0.6)) { [weak self] in
                guard let self = self else { return }
                self.character.isHidden = true
                let animation = SKAction.repeatForever(SKAction.animate(with: self.wheelRunTextures, timePerFrame: 0.1))
                self.wheelNode.run(animation)
                self.isRunningWheel = true
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)
        
        if let nodeName = tappedNode.name {
            handleTouch(named: nodeName)
        } else if tappedNode == character {
            runLegOrHornAnimation { self.runFreeMovement() }
        }
    }
    
    func handleTouch(named name: String) {
        switch name {
        case ButtonName.wheel:
            if currentAction == .idle || currentAction == .runningOnWheel {
                toggleWheelRunning()
            }
        case ButtonName.feed:
            spawnFood()
        case ButtonName.clean:
            runCleanAction()
        default:
            break
        }
    }
    
    func runCleanAction() {
        guard let poopNode = children.first(where: { $0.name == "poop" }) else { return }
        
        let broom = SKSpriteNode(imageNamed: "빗자루")
        broom.size = CGSize(width: 80, height: 80)
        broom.position = poopNode.position
        broom.zPosition = 11
        addChild(broom)
        
        let move = SKAction.moveBy(x: 40, y: 0, duration: 0.2)
        let moveBack = SKAction.moveBy(x: -40, y: 0, duration: 0.2)
        let sequence = SKAction.sequence([move, moveBack])
        let repeatSweep = SKAction.repeat(sequence, count: 3)
        
        broom.run(repeatSweep) { [weak self] in
            broom.removeFromParent()
            poopNode.removeFromParent()
        }
    }
    
    func runLegOrHornAnimation(completion: @escaping () -> Void) {
        let textures: [SKTexture]
        let key: String
        
        if Bool.random() {
            textures = legTextures
            key = "leg"
        } else {
            textures = hornTextures
            key = "horn"
        }
        
        character.removeAllActions()
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        let sequence = SKAction.sequence([
            animation,
            SKAction.run(completion)
        ])
        character.run(sequence, withKey: key)
    }
    
    func dropPoop() {
        let poop = SKSpriteNode(texture: poopTexture)
        poop.size = CGSize(width: 30, height: 30)
        poop.position = CGPoint(x: character.position.x, y: character.position.y - character.size.height / 2 - 10)
        poop.zPosition = -1
        poop.name = "poop"
        addChild(poop)
    }
    
    func actionAreaBounds(for size: CGSize) -> CGRect {
        let horizontalMargin: CGFloat = 40
        let bottomMargin: CGFloat = 80
        let topLimit = bottomMargin + (size.height - bottomMargin) * 0.7
        return CGRect(x: horizontalMargin, y: bottomMargin, width: size.width - 2 * horizontalMargin, height: topLimit - bottomMargin)
    }
    
    func runRandomAction(completion: @escaping () -> Void) {
        let (textures, key) = pickRandomAnimation()
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        let sequence = SKAction.sequence([animation, SKAction.run(completion)])
        character.removeAllActions()
        character.run(sequence, withKey: key)
    }
    
    func pickRandomAnimation() -> ([SKTexture], String) {
        switch Int.random(in: 0..<3) {
        case 0: return (earTextures, "ear")
        case 1: return (noseTextures, "nose")
        default: return (walkTextures, "walk")
        }
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
