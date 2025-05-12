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
    private var feedButton: SKSpriteNode!
    private var cleanButton: SKSpriteNode!
    private var poopTexture: SKTexture!
    private var foods: [SKSpriteNode] = []
    
    private var walkTextures: [SKTexture] = []
    private var noseTextures: [SKTexture] = []
    private var hornTextures: [SKTexture] = []
    private var earTextures: [SKTexture] = []
    private var legTextures: [SKTexture] = []
    private var wheelRunTextures: [SKTexture] = []
    
    private var isEating = false
    private var isRunningWheel = false
    
    private enum CharacterAction {
        case idle
        case movingToFood
        case eating
        case runningOnWheel
    }
    
    private var currentAction: CharacterAction = .idle
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "배경")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = self.size
        background.zPosition = -10
        addChild(background)
        
        loadTextures()
        setupButtons()
        
        // 쳇바퀴
        wheelNode = SKSpriteNode(imageNamed: "쳇바퀴")
        wheelNode.size = CGSize(width: 180, height: 210)
        let wheelX = size.width * 0.2
        let wheelY = size.height * (2.0 / 3.0)
        wheelNode.position = CGPoint(x: wheelX, y: wheelY)
        wheelNode.zPosition = -5
        wheelNode.name = "wheel"
        addChild(wheelNode)
        
        // 창문
        let windowNode = SKSpriteNode(imageNamed: "창문")
        windowNode.size = CGSize(width: 150, height: 150)
        windowNode.position = CGPoint(x: size.width / 2, y: size.height - 120)
        windowNode.zPosition = -5
        windowNode.name = "window"
        addChild(windowNode)
        
        // 그림판
        let easelNode = SKSpriteNode(imageNamed: "그림판")
        easelNode.size = CGSize(width: 170, height: 200)
        easelNode.position = CGPoint(x: size.width * 0.84, y: size.height * 0.7)
        easelNode.zPosition = -5
        easelNode.name = "easel"
        addChild(easelNode)
        
        // 침대
        let bedNode = SKSpriteNode(imageNamed: "침대")
        bedNode.size = CGSize(width: 180, height: 180)
        bedNode.position = CGPoint(x: size.width * 0.82, y: size.height * 0.52)
        bedNode.zPosition = -5
        bedNode.name = "bed"
        addChild(bedNode)
        
        // 고슴도치
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
        poopTexture = SKTexture(imageNamed: "임시똥")
    }
    
    private func setupButtons() {
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
        
        let proButton = SKSpriteNode(imageNamed: "프로버튼")
        proButton.name = "pro"
        proButton.size = CGSize(width: 100, height: 56)
        proButton.position = CGPoint(x: 60, y: size.height - 80)
        proButton.zPosition = 10
        addChild(proButton)
        
        let outdoorButton = SKSpriteNode(imageNamed: "야외버튼")
        outdoorButton.name = "outdoor"
        outdoorButton.size = CGSize(width: 80, height: 80)
        outdoorButton.position = CGPoint(x: size.width - 60, y: 80)
        outdoorButton.zPosition = 10
        addChild(outdoorButton)
    }
    
    private func runCleanAction() {
        // 씬에 있는 모든 자식 중에서 첫 번째 "poop" 노드를 찾음
        guard let poopNode = children.first(where: { $0.name == "poop" }) else { return }

        // 빗자루를 똥 위치에 생성
        let broom = SKSpriteNode(imageNamed: "빗자루")
        broom.size = CGSize(width: 80, height: 80)
        broom.position = poopNode.position
        broom.zPosition = 11
        addChild(broom)

        // 좌우로 움직이는 청소 애니메이션
        let move = SKAction.moveBy(x: 40, y: 0, duration: 0.2)
        let moveBack = SKAction.moveBy(x: -40, y: 0, duration: 0.2)
        let sequence = SKAction.sequence([move, moveBack])
        let repeatSweep = SKAction.repeat(sequence, count: 3)

        // 애니메이션 완료 후 똥 제거
        broom.run(repeatSweep) { [weak self] in
            broom.removeFromParent()
            poopNode.removeFromParent()
        }
    }
    
    private func actionAreaBounds(for size: CGSize) -> CGRect {
        let horizontalMargin: CGFloat = 40
        let bottomMargin: CGFloat = 80
        let topLimit = bottomMargin + (size.height - bottomMargin) * 0.7

        let minX = horizontalMargin
        let maxX = size.width - horizontalMargin
        let minY = bottomMargin
        let maxY = topLimit

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
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
        foodNode.position = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
        foodNode.name = "food"
        foodNode.zPosition = 1
        addChild(foodNode)
        foods.append(foodNode)

        if currentAction == .idle {
            moveToFood()
        }
    }
    
    private func moveToFood() {
        guard !foods.isEmpty, currentAction == .idle else { return }

        // 가장 가까운 먹이 선택
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
                self.currentAction = .idle
                self.runFreeMovement()

                // 먹이가 더 남아있으면 계속 먹음
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)
        
        switch tappedNode.name {
        case "wheel":
            if currentAction == .idle || currentAction == .runningOnWheel {
                toggleWheelRunning()
            }
        case "feed":
            spawnFood()
        case "clean":
            runCleanAction()
        case "window":
            print("창문 클릭됨!") // 여기에 원하는 동작 구현
        case "easel":
            print("그림판 클릭됨!") // 여기에 원하는 동작 구현
        case "bed":
            print("침대 클릭됨!") // 여기에 원하는 동작 구현
        case "pro":
            print("프로 버튼 클릭됨!")
            // 여기에 광고 팝업 또는 Pro 업그레이드 화면 전환 코드 추가
        case "outdoor":
            print("야외 버튼 클릭됨!")
            // 야외 씬으로 이동하거나 애니메이션 등 추가
        default:
            break
        }
    }
    
    private func toggleWheelRunning() {
        let wheelFrontPosition = CGPoint(x: wheelNode.position.x, y: wheelNode.position.y + 10)
        
        if isRunningWheel {
            wheelNode.removeAllActions()
            wheelNode.texture = SKTexture(imageNamed: "쳇바퀴")
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
                let animation = SKAction.repeatForever(
                    SKAction.animate(with: self.wheelRunTextures, timePerFrame: 0.1)
                )
                self.wheelNode.run(animation)
                self.isRunningWheel = true
            }
        }
    }
    
    private func runFreeMovement() {
        guard !isEating, currentAction == .idle else { return }

        if Int.random(in: 0..<4) == 0 {
            runRandomAction {
                self.runFreeMovement()
            }
            return
        }

        if Int.random(in: 0..<20) == 0 {
            dropPoop()
        }

        let bounds = actionAreaBounds(for: size)
        let halfWidth = character.size.width / 2
        let halfHeight = character.size.height / 2

        let randomDx = CGFloat.random(in: -100...100)
        let randomDy = CGFloat.random(in: -100...100)

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
    
    private func dropPoop() {
        let poop = SKSpriteNode(texture: poopTexture)
        poop.size = CGSize(width: 30, height: 30)
        poop.position = CGPoint(
            x: character.position.x,
            y: character.position.y - character.size.height / 2 - 10
        )
        poop.zPosition = -1
        poop.name = "poop" // 이름 지정
        addChild(poop)
    }
    
    private func removeOnePoop() {
        // 씬에 있는 모든 자식 중에서 첫 번째 "poop" 노드를 찾음
        if let poopNode = children.first(where: { $0.name == "poop" }) {
            poopNode.removeFromParent()
        }
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

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
