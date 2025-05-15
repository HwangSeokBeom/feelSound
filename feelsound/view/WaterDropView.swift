//
//  WaterDropView.swift
//  feelsound
//
//  Created by 안준경 on 5/8/25.
//

import SwiftUI
import Combine
import SpriteKit
import CoreMotion

// 물방울 잔흔을 위한 새로운 구조체
struct DropletTrail: Identifiable {
    var id = UUID()
    var position: CGPoint
    var size: CGFloat          // 시작 크기
    var opacity: Double = 1.0
    var imageName: String
    var creationTime = Date()
    
    // 애니메이션 관련 속성
    var fadeTime: TimeInterval = 5.0  // 완전히 사라지는데 걸리는 시간
    var shrinkRate: CGFloat = 0.97    // 매 업데이트마다 크기가 줄어드는 비율
}

struct WaterDropView: View {
    @EnvironmentObject var router: Router
    
    @State private var raindrops: [Raindrop] = []
    @State private var weatherState: WeatherState = .day
    @State private var previousWeatherState: WeatherState = .day
    @State private var timer: Timer?
    @State private var waterStreamDrops: [StreamDrop] = []
    @State private var activeStreams: [UUID: StreamInfo] = [:]
    @State private var collisionDrops: [CollisionDrop] = []
    @State private var dropletTrails: [DropletTrail] = []  // 물방울 잔흔 배열 추가
    
    // Constants
    private let maxRaindrops: Int = 500
    private let waterdropImages = ["waterdrop_01", "waterdrop_02", "waterdrop_03", "waterdrop_04"]
    private let trailDropImages = ["waterdrop_01", "waterdrop_02"]  // 잔흔 물방울 이미지
    private let collisionDropImages = ["waterdrop_08"]
    private let collisionRadius: CGFloat = 15 // Collision detection radius
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Image("nature")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 4)
                
                // Night effect overlay
                Color.black
                    .opacity(weatherState == .night ? 0.5 : 0)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut(duration: 1), value: weatherState)
                
                // Rain effects
                ZStack {
                    // 물방울 잔흔 - 가장 먼저 그려서 다른 물방울 뒤에 위치하도록 함
                    ForEach(dropletTrails) { trail in
                        Image(trail.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: trail.size, height: trail.size)
                            .opacity(trail.opacity)
                            .position(trail.position)
                    }
                    
                    // Stream drops
                    ForEach(waterStreamDrops) { drop in
                        Image(drop.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 10, height: 10)
                            .opacity(drop.opacity)
                            .position(x: drop.position.x, y: drop.position.y)
                    }
                    
                    // Static raindrops
                    ForEach(raindrops) { raindrop in
                        Image(raindrop.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: raindrop.size, height: raindrop.size)
                            .position(raindrop.position)
                    }
                    
                    // Collision drops - animated drops that cycle through images
                    ForEach(collisionDrops) { drop in
                        Image(collisionDropImages[drop.imageIndex])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .position(drop.position)
                            .opacity(drop.opacity)
                    }
                }
                
                // UI controls
                VStack {
                    Spacer()
                    
                    // Control buttons
                    HStack(spacing: 12) {
                        Button("DAY") {
                            setWeatherState(.day)
                        }
                        .buttonStyle(BasicButtonStyle())
                        
                        Button("STOP") {
                            previousWeatherState = weatherState
                            stopRainAnimation()
                            weatherState = .stop
                        }
                        .buttonStyle(BasicButtonStyle())
                        
                        Button("NIGHT") {
                            setWeatherState(.night)
                        }
                        .buttonStyle(BasicButtonStyle())
                    }
                    .padding(.bottom, 30)
                }
            }
            .onAppear {
                startRainAnimation(in: geometry.size)
            }
            .onDisappear {
                stopRainAnimation()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func setWeatherState(_ state: WeatherState) {
        if weatherState == .stop {
            startRainAnimation(in: UIScreen.main.bounds.size)
        }
        weatherState = state
        previousWeatherState = state
    }
    
    // Start rain animation
    private func startRainAnimation(in size: CGSize) {
        raindrops.removeAll()
        waterStreamDrops.removeAll()
        collisionDrops.removeAll()
        dropletTrails.removeAll()  // 잔흔 물방울도 초기화
        
        // Clear timers
        timer?.invalidate()
        
        for stream in activeStreams.values {
            stream.timer?.invalidate()
        }
        activeStreams.removeAll()
        
        // Create raindrop generation timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            // 물방울 생성
            //self.createRaindrop(in: size)
            for _ in 0..<3 {
                if self.raindrops.count < self.maxRaindrops {
                    self.createRaindrop(in: size)
                } else {
                    break // 최대 개수에 도달하면 중단
                }
            }
            
            // Check for collisions
            self.checkRaindropCollisions()
            
            // Update collision drops
            self.updateCollisionDrops()
            
            // 물줄기 끼리의 충돌 검사 (새로 추가)
            self.checkCollisionDropsInteraction()
            
            // Update droplet trails
            self.updateDropletTrails()
            
            self.checkOutOfBoundsDrops(in: size)
        }
    }
    
    // Stop rain animation
    private func stopRainAnimation() {
        timer?.invalidate()
        timer = nil
        
        // Clear active streams
        for stream in activeStreams.values {
            stream.timer?.invalidate()
        }
        activeStreams.removeAll()
        
        // Fade out effects
        withAnimation(.easeOut(duration: 2)) {
            raindrops.removeAll()
            collisionDrops.removeAll()
        }
        
        // 잔흔 물방울에도 fade 적용
        for i in 0..<dropletTrails.count {
            dropletTrails[i].opacity *= 0.9  // 빠르게 사라지게 함
        }
        
        // Mark all water stream drops for fading
        for i in 0..<waterStreamDrops.count {
            waterStreamDrops[i].isFading = true
        }
    }
    
    // Create a new raindrop
    private func createRaindrop(in size: CGSize) {
        let randomImage = waterdropImages.randomElement() ?? "waterdrop_01"
        
        let newRaindrop = Raindrop(
            id: UUID(),
            position: CGPoint(
                x: CGFloat.random(in: 20...(size.width - 20)),
                y: CGFloat.random(in: 0...size.height)
            ),
            size: CGFloat.random(in: 5...10),
            speed: CGFloat.random(in: 2...5),
            creationTime: Date(),
            imageName: randomImage
        )
        
        raindrops.append(newRaindrop)
    }
    
    // Check for collisions between raindrops
    private func checkRaindropCollisions() {
        guard raindrops.count > 1 else { return }
        
        var collidedRaindrops: Set<UUID> = []
        var newCollisionPositions: [CGPoint] = []
        
        // Check every raindrop against others
        for i in 0..<raindrops.count {
            let raindrop1 = raindrops[i]
            
            // Skip if already processed as collided
            if collidedRaindrops.contains(raindrop1.id) {
                continue
            }
            
            for j in (i+1)..<raindrops.count {
                let raindrop2 = raindrops[j]
                
                // Skip if already processed as collided
                if collidedRaindrops.contains(raindrop2.id) {
                    continue
                }
                
                // Calculate distance between raindrops
                let distance = hypot(
                    raindrop1.position.x - raindrop2.position.x,
                    raindrop1.position.y - raindrop2.position.y
                )
                
                // If distance is less than combined sizes, they collide
                if distance < (raindrop1.size/2 + raindrop2.size/2) {
                    // Mark both as collided
                    collidedRaindrops.insert(raindrop1.id)
                    collidedRaindrops.insert(raindrop2.id)
                    
                    // Create a collision point at the midpoint between the two raindrops
                    let collisionPosition = CGPoint(
                        x: (raindrop1.position.x + raindrop2.position.x) / 2,
                        y: (raindrop1.position.y + raindrop2.position.y) / 2
                    )
                    
                    newCollisionPositions.append(collisionPosition)
                }
            }
        }
        
        // Remove collided raindrops
        raindrops.removeAll { collidedRaindrops.contains($0.id) }
        
        // Create new collision drops
        for position in newCollisionPositions {
            createCollisionDrop(at: position)
        }
    }
    
    // Create a collision drop
    private func createCollisionDrop(at position: CGPoint) {
        let newCollisionDrop = CollisionDrop(
            id: UUID(),
            position: position,
            creationTime: Date(),
            opacity: 1.0,
            velocity: CGFloat.random(in: 1.5...3.0),
            imageIndex: 0,
            lastImageChangeTime: Date(),
            
            // 기존 속성 초기화
            totalPauses: Int.random(in: 1...4),      // 2~4회 사이 랜덤하게 멈춤
            pauseTime: Double.random(in: 1.0...2.0), // 멈춤 시간
            fallTime: Double(0.05),  // 낙하 시간
            lastStateChangeTime: Date(),             // 상태 변경 시간
            
            // 물방울 흔적 관련 속성 초기화
            lastDropletTime: Date(),
            dropletInterval: Double.random(in: 0.05...0.15), // 더 자주 물방울 흔적 생성 (0.05~0.15초)
            leaveDroplets: true  // 물방울 흔적을 남기도록 설정
        )
        
        collisionDrops.append(newCollisionDrop)
        
        // 충돌 물방울은 바깥으로 나가거나 오랜 시간이 지난 후 제거됩니다
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            // 오래된 물방울을 안전하게 정리
            self.collisionDrops.removeAll { $0.id == newCollisionDrop.id }
        }
    }
    
    // Update collision drops (move them down and cycle through images)
    private func updateCollisionDrops() {
        let currentTime = Date()
        let screenHeight = UIScreen.main.bounds.height
        
        // 각 충돌 물방울의 위치와 모양을 업데이트
        for i in 0..<collisionDrops.count {
            // 이미지 변경 로직 (이전과 동일)
            let timeElapsedSinceLastChange = currentTime.timeIntervalSince(collisionDrops[i].lastImageChangeTime)
            if timeElapsedSinceLastChange > 0.15 {
                // 다음 이미지로 순환
                collisionDrops[i].imageIndex = (collisionDrops[i].imageIndex + 1) % collisionDropImages.count
                collisionDrops[i].lastImageChangeTime = currentTime
            }
            
            // 물방울이 화면 바깥으로 나갔는지 확인
            if collisionDrops[i].position.y > screenHeight + 50 {
                // 제거를 위해 투명도 감소
                collisionDrops[i].opacity = 0
                continue
            }
            
            // 최종 미끄러짐 상태인 경우
            if collisionDrops[i].finalSlide {
                // 속도를 빠르게 증가시키며 계속 낙하
                collisionDrops[i].velocity += 0.5
                collisionDrops[i].position.y += collisionDrops[i].velocity
                
                // 물방울 잔흔 생성 로직 추가
                if collisionDrops[i].leaveDroplets {
                    let dropletTimeElapsed = currentTime.timeIntervalSince(collisionDrops[i].lastDropletTime)
                    
                    // 일정 간격마다 물방울 잔흔 생성
                    if dropletTimeElapsed >= collisionDrops[i].dropletInterval {
                        // 새 물방울 잔흔 생성
                        createDropletTrail(at: collisionDrops[i].position)
                        collisionDrops[i].lastDropletTime = currentTime
                    }
                }
                
                // 기존 물방울과 미끄러지는 물방울 간의 충돌 검사
                checkStreamCollisions(with: collisionDrops[i])
                
                continue
            }
            
            // 상태 전환 로직
            let timeInCurrentState = currentTime.timeIntervalSince(collisionDrops[i].lastStateChangeTime)
            
            if collisionDrops[i].isPaused {
                // 멈춤 상태에서 타이머 확인
                if timeInCurrentState >= collisionDrops[i].pauseTime {
                    // 멈춤 상태 끝, 낙하 상태로 전환
                    collisionDrops[i].isPaused = false
                    collisionDrops[i].lastStateChangeTime = currentTime
                    collisionDrops[i].velocity = CGFloat.random(in: 1.5...3.0) // 새로운 속도 설정
                }
            } else {
                // 낙하 상태
                if timeInCurrentState >= collisionDrops[i].fallTime {
                    // 낙하 상태 끝
                    collisionDrops[i].pauseCount += 1
                    
                    // 정해진 멈춤 횟수에 도달했는지 확인
                    if collisionDrops[i].pauseCount >= collisionDrops[i].totalPauses {
                        // 최종 미끄러짐 상태로 전환
                        collisionDrops[i].finalSlide = true
                        collisionDrops[i].velocity = CGFloat(3.0) // 낙하 속도
                    } else {
                        // 다시 멈춤 상태로 전환
                        collisionDrops[i].isPaused = true
                        collisionDrops[i].lastStateChangeTime = currentTime
                        collisionDrops[i].velocity = 0 // 속도 0으로 설정
                    }
                } else {
                    // 계속 낙하 중
                    collisionDrops[i].position.y += collisionDrops[i].velocity
                    
                    // 일반 낙하 중일 때는 중력 효과를 약하게 적용
                    if !collisionDrops[i].finalSlide {
                        collisionDrops[i].velocity += 1//0.03
                    }
                }
            }
        }
        
        // 완전히 투명해진 물방울 제거
        collisionDrops.removeAll { $0.opacity <= 0.01 }
    }
    
    // 새로 추가: 미끄러지는 물방울과 다른 물방울들 간의 충돌 검사
    // 물줄기와 다른 물방울들 간의 충돌 검사 함수 수정
    private func checkStreamCollisions(with streamDrop: CollisionDrop) {
        // 물줄기가 아닌 경우 검사 건너뛰기
        if !streamDrop.finalSlide {
            return
        }
        
        let collisionThreshold: CGFloat = 15.0  // 충돌 감지 반경
        
        // 1. 기존 정적 물방울들과의 충돌 검사
        var collidedRaindrops: Set<UUID> = []
        
        for raindrop in raindrops {
            let distance = hypot(
                streamDrop.position.x - raindrop.position.x,
                streamDrop.position.y - raindrop.position.y
            )
            
            if distance < collisionThreshold {
                collidedRaindrops.insert(raindrop.id)
            }
        }
        
        // 충돌한 정적 물방울들 모두 제거
        if !collidedRaindrops.isEmpty {
            raindrops.removeAll { collidedRaindrops.contains($0.id) }
        }
        
        // 2. 스트림 물방울과의 충돌 검사
        var collidedStreamDrops: Set<UUID> = []
        
        for streamDrop in waterStreamDrops {
            let distance = hypot(
                streamDrop.position.x - streamDrop.position.x,
                streamDrop.position.y - streamDrop.position.y
            )
            
            if distance < collisionThreshold {
                collidedStreamDrops.insert(streamDrop.id)
            }
        }
        
        // 충돌한 스트림 물방울들 제거 (완전히 투명하게)
        for i in 0..<waterStreamDrops.count {
            if collidedStreamDrops.contains(waterStreamDrops[i].id) {
                waterStreamDrops[i].opacity = 0  // 완전히 투명하게 설정하여 제거
                waterStreamDrops[i].isFading = true
            }
        }
    }
    
    // 물방울 잔흔 생성 함수 (크기 배율 파라미터 추가)
    private func createDropletTrail(at position: CGPoint, sizeMultiplier: CGFloat = 1.0) {
        // 약간의 랜덤 오프셋 추가하여 자연스러운 느낌 부여
        let randomOffset = CGPoint(
            x: CGFloat.random(in: -3...3),
            y: CGFloat.random(in: -1...1)
        )
        
        let trailPosition = CGPoint(
            x: position.x + randomOffset.x,
            y: position.y + randomOffset.y
        )
        
        // 랜덤한 이미지 선택
        let randomImage = trailDropImages.randomElement() ?? "waterdrop_01"
        
        // 랜덤한 크기로 시작 (원래 물방울보다 작게)
        let size = CGFloat.random(in: 20...30) * sizeMultiplier
        
        let newTrail = DropletTrail(
            position: trailPosition,
            size: size,
            imageName: randomImage,
            fadeTime: Double.random(in: 2.0...4.0) // 2~4초 사이에 사라짐
        )
        
        dropletTrails.append(newTrail)
        
        // 잔흔 물방울 제한 (너무 많아지지 않도록)
        if dropletTrails.count > 100 {
            // 가장 오래된 것부터 제거
            dropletTrails.removeFirst()
        }
    }
    
    // 물방울 잔흔 업데이트 함수
    private func updateDropletTrails() {
        let currentTime = Date()
        
        for i in 0..<dropletTrails.count {
            // 생성 후 경과 시간 계산
            let timeElapsed = currentTime.timeIntervalSince(dropletTrails[i].creationTime)
            let progress = timeElapsed / dropletTrails[i].fadeTime
            
            // 점점 작아지고 투명해지게 함
            dropletTrails[i].size *= dropletTrails[i].shrinkRate
            dropletTrails[i].opacity = max(0, 1.0 - progress)
        }
        
        // 투명도가 0에 가까운 잔흔들 제거
        dropletTrails.removeAll { $0.opacity < 0.05 || $0.size < 1.0 }
    }
    
    // 물방울 충돌 검사
    private func checkCollisionDropsInteraction() {
        var processedDrops: Set<UUID> = []
        let collisionThreshold: CGFloat = 20.0
        
        // 모든 물방울 간의 충돌 검사 (미끄러짐 상태가 아닌 물방울도 포함)
        for i in 0..<collisionDrops.count {
            let drop1 = collisionDrops[i]
            
            // 이미 처리된 물방울이면 건너뜀
            if processedDrops.contains(drop1.id) {
                continue
            }
            
            for j in (i+1)..<collisionDrops.count {
                let drop2 = collisionDrops[j]
                
                // 이미 처리된 물방울이면 건너뜀
                if processedDrops.contains(drop2.id) {
                    continue
                }
                
                // 두 물방울 간의 거리 계산
                let distance = hypot(
                    drop1.position.x - drop2.position.x,
                    drop1.position.y - drop2.position.y
                )
                
                // 충돌 감지
                if distance < collisionThreshold {
                    processedDrops.insert(drop1.id)
                    processedDrops.insert(drop2.id)
                    
                    // 충돌 처리 로직
                    handleCollisionBetween(drop1: drop1, drop2: drop2, at: i, and: j)
                }
            }
        }
        
        // 투명도가 낮아진 물방울 제거
        collisionDrops.removeAll { $0.opacity < 0.1 }
    }
    
    private func handleCollisionBetween(drop1: CollisionDrop, drop2: CollisionDrop, at index1: Int, and index2: Int) {
            
            // 어떤 물방울이 더 오래됐는지 확인
            let drop1IsOlder = drop1.creationTime < drop2.creationTime
            
            // 간단한 룰: 가장 오래된 물방울만 살아남고, 나머지는 사라진다.
            // 물줄기 상태인 물방울이 있으면 가장 오래된 물줄기만 살아남는다.
            
            if drop1.finalSlide && drop2.finalSlide {
                // 두 물방울 모두 물줄기 상태일 때 가장 오래된 것만 살아남음
                if drop1IsOlder {
                    // drop1이 더 오래됨 - drop1은 살아남고, drop2는 사라짐
                    if index2 < collisionDrops.count {
                        collisionDrops[index2].opacity = 0
                        collisionDrops[index2].finalSlide = false
                        collisionDrops[index2].leaveDroplets = false
                    }
                } else {
                    // drop2가 더 오래됨 - drop2는 살아남고, drop1은 사라짐
                    if index1 < collisionDrops.count {
                        collisionDrops[index1].opacity = 0
                        collisionDrops[index1].finalSlide = false
                        collisionDrops[index1].leaveDroplets = false
                    }
                }
                
                return
            }
            
            // 하나만 물줄기 상태일 때
            if drop1.finalSlide || drop2.finalSlide {
                if drop1.finalSlide {
                    // drop1이 물줄기 상태, drop2는 제거
                    if index2 < collisionDrops.count {
                        collisionDrops[index2].opacity = 0
                        collisionDrops[index2].finalSlide = false
                        collisionDrops[index2].leaveDroplets = false
                    }
                } else {
                    // drop2가 물줄기 상태, drop1은 제거
                    if index1 < collisionDrops.count {
                        collisionDrops[index1].opacity = 0
                        collisionDrops[index1].finalSlide = false
                        collisionDrops[index1].leaveDroplets = false
                    }
                }
                
                return
            }
            
            // 두 물방울 모두 일반 상태일 때, 가장 오래된 물방울만 물줄기가 됨
            if drop1IsOlder {
                // drop1이 더 오래됨 - drop1은 물줄기 상태로, drop2는 사라짐
                if index1 < collisionDrops.count {
                    collisionDrops[index1].finalSlide = true
                    collisionDrops[index1].velocity = CGFloat.random(in: 3.0...5.0)
                    collisionDrops[index1].leaveDroplets = true
                }
                
                if index2 < collisionDrops.count {
                    collisionDrops[index2].opacity = 0
                    collisionDrops[index2].finalSlide = false
                    collisionDrops[index2].leaveDroplets = false
                }
            } else {
                // drop2가 더 오래됨 - drop2는 물줄기 상태로, drop1은 사라짐
                if index2 < collisionDrops.count {
                    collisionDrops[index2].finalSlide = true
                    collisionDrops[index2].velocity = CGFloat.random(in: 3.0...5.0)
                    collisionDrops[index2].leaveDroplets = true
                }
                
                if index1 < collisionDrops.count {
                    collisionDrops[index1].opacity = 0
                    collisionDrops[index1].finalSlide = false
                    collisionDrops[index1].leaveDroplets = false
                }
            }
        }

    
    // Calculate X velocity based on device tilt
    private func getXVelocityFromMotion() -> CGFloat {
        let maxVelocity: CGFloat = 30.0
        let velocityFactor: CGFloat = 20.0
        
        return max(-maxVelocity, min(maxVelocity, velocityFactor))
    }
    
    // Check for drops that have gone out of bounds
    private func checkOutOfBoundsDrops(in size: CGSize) {
        for i in 0..<waterStreamDrops.count {
            let drop = waterStreamDrops[i]
            
            if (drop.position.y > size.height + 30 || drop.position.x < -30 ||
                drop.position.x > size.width + 30) && !drop.isFading {
                waterStreamDrops[i].isFading = true
            }
        }
    }
}

// Model Structs
struct Raindrop: Identifiable {
    var id: UUID
    var position: CGPoint
    var size: CGFloat
    var speed: CGFloat
    var creationTime: Date
    var imageName: String
}

struct StreamDrop: Identifiable {
    var id: UUID
    var position: CGPoint
    var imageName: String
    var creationTime: Date
    var opacity: Double = 1.0
    var isFading: Bool = false
}

struct CollisionDrop: Identifiable {
    var id: UUID
    var position: CGPoint
    var creationTime: Date
    var opacity: Double = 1.0
    var velocity: CGFloat = 0.0
    var imageIndex: Int = 0      // Current image index in the cycle
    var lastImageChangeTime: Date // Track when we last changed the image
    
    // 기존 속성
    var pauseCount: Int = 0                 // 현재까지 멈춘 횟수
    var totalPauses: Int                    // 총 멈춤 횟수 (2~5 사이로 랜덤)
    var isPaused: Bool = false              // 현재 멈춤 상태인지
    var pauseTime: TimeInterval = 0         // 멈춤 상태 지속 시간
    var fallTime: TimeInterval = 0          // 낙하 상태 지속 시간
    var lastStateChangeTime: Date           // 마지막으로 상태가 변경된 시간
    var finalSlide: Bool = false            // 최종 미끄러짐 상태인지
    
    // 물방울 흔적 관련 속성
    var lastDropletTime: Date               // 마지막으로 물방울 흔적을 남긴 시간
    var dropletInterval: TimeInterval       // 물방울 흔적을 남기는 간격
    var leaveDroplets: Bool = false         // 물방울 흔적을 남길지 여부
}

struct StreamInfo {
    var timer: Timer?
}

enum WeatherState {
    case day
    case night
    case stop
}

// Button Style
struct BasicButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct WaterDropViewPreviews: PreviewProvider {
    static var previews: some View {
        WaterDropView()
            .previewLayout(.sizeThatFits)
    }
}
