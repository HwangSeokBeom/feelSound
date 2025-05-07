//
//  TiltDropletView.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI
import CoreMotion
import SpriteKit

// MARK: - Water Droplet Configuration
struct WaterDroplet: Identifiable {
    let id = UUID()
    var textureIndex: Int = 0 // Current texture/image index
    var position: CGPoint // Position on screen
    var velocity: CGVector // Movement velocity
    var isActive: Bool = false // Whether the droplet is currently falling
}

// 기울기에 따른 물방울 장면
class TiltDropletScene: SKScene {
    // 물방울 텍스처 배열
    private let dropletTextures: [SKTexture] = [
        SKTexture(imageNamed: "waterdrop_01"),
        SKTexture(imageNamed: "waterdrop_02"),
        SKTexture(imageNamed: "waterdrop_03"),
        SKTexture(imageNamed: "waterdrop_04"),
        SKTexture(imageNamed: "waterdrop_05"),
        SKTexture(imageNamed: "waterdrop_06"),
        SKTexture(imageNamed: "waterdrop_07")
    ]
    
    private var dropletNode: SKSpriteNode?
    private var currentTextureIndex = 0
    private var motionManager: CMMotionManager?
    private var lastUpdateTime: TimeInterval = 0
    private var canCreateDroplet = true
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupPhysicsWorld()
        startMotionUpdates()
    }
    
    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame) // 화면 경계에 벽 추가
    }
    
    private func startMotionUpdates() {
        motionManager = CMMotionManager()
        
        guard let motionManager = motionManager, motionManager.isAccelerometerAvailable else {
            print("가속도계를 사용할 수 없습니다")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let accelerometerData = data else { return }
            
            // X축 기울기 (좌우)
            let xTilt = accelerometerData.acceleration.x
            // Y축 기울기 (상하)
            let yTilt = accelerometerData.acceleration.y
            
            // 기울기 값에 따라 중력 방향 조정
            self.physicsWorld.gravity = CGVector(
                dx: CGFloat(xTilt * 10.0),  // 좌우 중력
                dy: -9.8 + CGFloat(yTilt * 5.0)  // 상하 중력 (기본 중력에 Y축 기울기 추가)
            )
            
            // 기울기가 충분할 때만 물방울 생성
            let tiltMagnitude = sqrt(xTilt * xTilt + yTilt * yTilt)
            if tiltMagnitude > 0.1 && self.canCreateDroplet {
                self.createDroplet(tiltMagnitude: CGFloat(tiltMagnitude))
                self.canCreateDroplet = false
                
                // 0.5초 후에 다시 물방울 생성 가능하도록 설정
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.canCreateDroplet = true
                }
            }
        }
    }
    
    private func createDroplet(tiltMagnitude: CGFloat) {
        // 시작 위치 계산 - 기울기 방향의 반대쪽 가장자리에서 시작
        let xPosition: CGFloat
        if physicsWorld.gravity.dx > 0 {
            // 오른쪽으로 기울어져 있으면 왼쪽에서 시작
            xPosition = size.width * 0.2
        } else if physicsWorld.gravity.dx < 0 {
            // 왼쪽으로 기울어져 있으면 오른쪽에서 시작
            xPosition = size.width * 0.8
        } else {
            // 수평이면 중앙에서 시작
            xPosition = size.width / 2
        }
        
        // 첫 번째(가장 짧은) 물방울 이미지로 시작
        let droplet = SKSpriteNode(texture: dropletTextures[0])
        droplet.position = CGPoint(x: xPosition, y: size.height - 100)
        droplet.setScale(0.7)
        droplet.name = "droplet"
        
        // 물리 바디 추가
        droplet.physicsBody = SKPhysicsBody(texture: dropletTextures[0], size: droplet.size)
        droplet.physicsBody?.affectedByGravity = true
        droplet.physicsBody?.mass = 0.1
        droplet.physicsBody?.restitution = 0.3
        
        addChild(droplet)
        
        // 기울기 정도에 따라 최대 텍스처 인덱스 결정
        // 더 많이 기울어질수록 더 긴 물방울
        let maxTextureIndex = min(Int(tiltMagnitude * 10), dropletTextures.count - 1)
        
        // 이전 물방울이 있으면 제거
        if let oldDroplet = self.dropletNode {
            oldDroplet.removeFromParent()
        }
        
        self.dropletNode = droplet
        self.currentTextureIndex = 0
        
        // 물방울 텍스처 변화 애니메이션 시작
        startTextureChangeAnimation(maxIndex: maxTextureIndex)
    }
    
    private func startTextureChangeAnimation(maxIndex: Int) {
        let wait = SKAction.wait(forDuration: 0.15)
        let changeTexture = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            if self.currentTextureIndex < maxIndex {
                self.currentTextureIndex += 1
                let newTexture = self.dropletTextures[self.currentTextureIndex]
                
                self.dropletNode?.texture = newTexture
                
                // 물리 바디도 업데이트
                if let velocity = self.dropletNode?.physicsBody?.velocity {
                    self.dropletNode?.physicsBody = SKPhysicsBody(texture: newTexture, size: self.dropletNode!.size)
                    self.dropletNode?.physicsBody?.affectedByGravity = true
                    self.dropletNode?.physicsBody?.velocity = velocity
                    self.dropletNode?.physicsBody?.mass = 0.1
                    self.dropletNode?.physicsBody?.restitution = 0.3
                }
            }
        }
        
        let sequence = SKAction.sequence([wait, changeTexture])
        let repeatAction = SKAction.repeat(sequence, count: maxIndex + 1)
        
        dropletNode?.run(repeatAction)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // 화면 밖으로 나간 물방울 제거
        if let droplet = dropletNode,
           (droplet.position.y < -50 || droplet.position.y > size.height + 50 ||
            droplet.position.x < -50 || droplet.position.x > size.width + 50) {
            droplet.removeFromParent()
            dropletNode = nil
            canCreateDroplet = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 터치 시 새 물방울 생성 허용
        canCreateDroplet = true
    }
    
    override func willMove(from view: SKView) {
        // 화면을 떠날 때 가속도계 업데이트 중지
        motionManager?.stopAccelerometerUpdates()
    }
}

// SwiftUI 뷰
struct TiltDropletView: View {
    @EnvironmentObject var router: Router

    var scene: SKScene {
        let scene = TiltDropletScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .fill
        return scene
    }
    
    var body: some View {
        ZStack {
            // 안내 텍스트
            VStack {
                HStack{
                    Button(action: {
                        router.navigateBack()
                    }) {
                        
                        Image(systemName: "chevron.backward")
                            .padding(.all, 10)
                            .foregroundColor(.white)
                        
                    }
                    .padding(.horizontal, 16)
                    
                    
                    Spacer()
                    
                }
                Text("기울기에 따른 물방울 시뮬레이션")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                
                Text("기기를 기울여서 물방울이 떨어지는 방향을 제어하세요")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                
                Text("더 많이 기울일수록 물방울이 더 길어집니다")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding()
                
                Spacer()
            }
            .zIndex(1)
            
            // SpriteKit 장면
            SpriteView(scene: scene)
                .ignoresSafeArea()
        }
        .background(Color.black)
    }
}
