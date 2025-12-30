//
//  Untitled.swift
//  MovingCharacter
//
//  Created by Hwangseokbeom on 5/7/25.
//

// IndoorScene.swift
// feelsound

import SpriteKit

class IndoorScene: BaseScene {
    override func setupBackground() {
        let background = SKSpriteNode(imageNamed: "실내배경")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = self.size
        background.zPosition = -10
        addChild(background)
    }
    
    override func setupWheel() {
        wheelNode = SKSpriteNode(imageNamed: "쳇바퀴")
        wheelNode.size = CGSize(width: 180, height: 210)
        wheelNode.position = CGPoint(x: size.width * 0.2, y: size.height * (2.0 / 3.0))
        wheelNode.zPosition = -5
        wheelNode.name = "wheel"
        addChild(wheelNode)
    }
    
    override func setupEnvironment() {
        let window = SKSpriteNode(imageNamed: "창문")
        window.size = CGSize(width: 150, height: 150)
        window.position = CGPoint(x: size.width / 2, y: size.height - 120)
        window.zPosition = -5
        window.name = "window"
        addChild(window)
        
        let easel = SKSpriteNode(imageNamed: "그림판")
        easel.size = CGSize(width: 170, height: 200)
        easel.position = CGPoint(x: size.width * 0.84, y: size.height * 0.7)
        easel.zPosition = -5
        easel.name = "easel"
        addChild(easel)
        
        let bed = SKSpriteNode(imageNamed: "침대")
        bed.size = CGSize(width: 180, height: 180)
        bed.position = CGPoint(x: size.width * 0.82, y: size.height * 0.52)
        bed.zPosition = -5
        bed.name = "bed"
        addChild(bed)
        
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
    
    override func handleTouch(named name: String) {
        switch name {
        case "window":
            print("창문 클릭됨!")
        case "easel":
            print("그림판 클릭됨!")
        case "bed":
            print("침대 클릭됨!")
        case "pro":
            print("프로 버튼 클릭됨!")
        case "outdoor":
            presentScene(scene: OutdoorScene(size: size))
        default:
            super.handleTouch(named: name)
        }
    }
}
