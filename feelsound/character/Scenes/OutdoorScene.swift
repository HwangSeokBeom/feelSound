//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/12/25.
//

// OutdoorScene.swift
// feelsound

import SpriteKit

class OutdoorScene: BaseScene {
    
    override var wheelType: WheelType { .outdoor }
    
    override func setupBackground() {
        let background = SKSpriteNode(imageNamed: "야외3")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = self.size
        background.zPosition = -10
        addChild(background)
    }

    override func setupWheel() {
        wheelNode = SKSpriteNode(imageNamed: "쳇바퀴_야외")
        wheelNode.size = CGSize(width: 150, height: 150)
        wheelNode.position = CGPoint(x: size.width * 0.2, y: size.height * (2.0 / 3.0))
        wheelNode.zPosition = -5
        wheelNode.name = "wheel"
        addChild(wheelNode)
    }

    override func setupEnvironment() {
        let stone = SKSpriteNode(imageNamed: "돌다리")
        stone.size = CGSize(width: 360, height: 240)
        stone.position = CGPoint(x: size.width * 0.35, y: size.height * 0.5)
        stone.zPosition = -5
        stone.name = "stone"
        addChild(stone)

        let fountain = SKSpriteNode(imageNamed: "분수")
        fountain.size = CGSize(width: 170, height: 200)
        fountain.position = CGPoint(x: size.width * 0.85, y: size.height * 0.5)
        fountain.zPosition = -5
        fountain.name = "fountain"
        addChild(fountain)

        let lamp = SKSpriteNode(imageNamed: "가로등")
        lamp.size = CGSize(width: 80, height: 260)
        lamp.position = CGPoint(x: size.width * 0.15, y: size.height * 0.4)
        lamp.zPosition = -5
        lamp.name = "lamp"
        addChild(lamp)

        let proButton = SKSpriteNode(imageNamed: "프로버튼")
        proButton.name = "pro"
        proButton.size = CGSize(width: 100, height: 56)
        proButton.position = CGPoint(x: 60, y: size.height - 80)
        proButton.zPosition = 10
        addChild(proButton)

        let indoorButton = SKSpriteNode(imageNamed: "실내버튼")
        indoorButton.name = "indoor"
        indoorButton.size = CGSize(width: 100, height: 100)
        indoorButton.position = CGPoint(x: size.width - 60, y: 80)
        indoorButton.zPosition = 10
        addChild(indoorButton)
    }

    override func handleTouch(named name: String) {
        switch name {
        case "stone": print("돌다리 클릭됨!")
        case "fountain": print("분수 클릭됨!")
        case "lamp": print("가로등 클릭됨!")
        case "indoor":
            presentScene(scene: IndoorScene(size: size))
        default:
            super.handleTouch(named: name)
        }
    }
}

