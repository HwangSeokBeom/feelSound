//
//  WaterDropView.swift
//  feelsound
//
//  Created by 안준경 on 5/8/25.
//

import SwiftUI
import Combine
import SpriteKit

struct WaterDropView: View {
    @State private var raindrops: [Raindrop] = []
    @State private var weatherState: WeatherState = .day
    @State private var previousWeatherState: WeatherState = .day
    @State private var timerCancellable: Cancellable? = nil
    @State private var rainScene: RainFall? = RainFall()
    @State private var isAnimating = false
    @State private var timer: Timer?
    @State private var streamTimer: Timer?
    @State private var waterStreamDrops: [StreamDrop] = []
    @State private var exclusionArea: CGRect? = nil
    
    // 빗물 생성 간격 (초)
    private let creationInterval: Double = 0.01
    // 최대 빗물 개수
    private let maxRaindrops: Int = 500
    // 물줄기 생성 간격 (초)
    private let streamDropInterval: Double = 0.01
    // 새로운 물줄기 생성 간격 (초)
    private let newStreamInterval: Double = 2.0
    
    // 물방울 이미지 배열
    let waterdropImages = ["waterdrop_01", "waterdrop_02", "waterdrop_03", "waterdrop_04"]
    
    // 활성 물줄기 스트림 관리 (UUID: 타이머 매핑)
    @State private var activeStreams: [UUID: StreamInfo] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 이미지 - 우선순위 높이기
                Image("nature")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 4)
                    .zIndex(0) // 명시적으로 zIndex 설정
                
                // 밤 효과 (어두운 오버레이)
                Color.black
                    .opacity(weatherState == .stop ? (previousWeatherState == .night ? 0.5 : 0) : (weatherState == .night ? 0.5 : 0))
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(1)
                    .animation(.easeInOut(duration: 1), value: weatherState)
                
                // 빗물과 물줄기 컨테이너
                ZStack {
                    // SpriteKit 비 효과 - 투명 배경 강제 적용
                    if let rainScene = rainScene {
                        SpriteView(scene: rainScene, options: [.allowsTransparency])
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .zIndex(2)
                            .allowsHitTesting(false) // 터치 이벤트 통과
                    }
                    
                    // 흘러내리는 물방울들
                    ForEach(waterStreamDrops) { drop in
                        Image(drop.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .opacity(drop.opacity)
                            .position(x: drop.position.x, y: drop.position.y)
                    }
                    .zIndex(3)
                    
                    // 빗물들 (고정된 물방울)
                    ForEach(raindrops) { raindrop in
                        Image(raindrop.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: raindrop.size, height: raindrop.size)
                            .position(raindrop.position)
                    }
                    .zIndex(4)
                }
                .zIndex(2)
                
                // UI 요소 컨테이너 - 최상단에 배치
                VStack {
                    Spacer()
                    
                    // SpriteKit 비가 바닥에 튕기는 효과
                    if rainScene != nil {
                        SpriteView(scene: RainFallLanding(), options: [.allowsTransparency])
                            .frame(width: geometry.size.width, height: 50)
                            .offset(y: 5)
                    }
                    
                    // 버튼 그룹 - 명확한 스타일로 강조
                    HStack(spacing: 12) {
                        Button("DAY") {
                            if weatherState == .stop {
                                startRainAnimation(in: geometry.size)
                                startRandomStreams(in: geometry.size)
                            }
                            weatherState = .day
                            previousWeatherState = .day
                        }
                        .buttonStyle(BasicButtonStyle())
                        
                        Button("STOP") {
                            if weatherState != .stop {
                                previousWeatherState = weatherState
                            }
                            stopRainAnimation()
                            weatherState = .stop
                        }
                        .buttonStyle(BasicButtonStyle())
                        
                        Button("NIGHT") {
                            if weatherState == .stop {
                                startRainAnimation(in: geometry.size)
                                startRandomStreams(in: geometry.size)
                            }
                            weatherState = .night
                            previousWeatherState = .night
                        }
                        .buttonStyle(BasicButtonStyle())
                    }
                    .padding(.bottom, 30)
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                .zIndex(5) // 최상위 레이어
            }
            .onAppear {
                // 애니메이션 시작
                startRainAnimation(in: geometry.size)
                startRandomStreams(in: geometry.size)
            }
            .onDisappear {
                stopRainAnimation()
            }
        }
        .edgesIgnoringSafeArea(.all) // 전체 화면 사용
    }
    
    // 빗물 애니메이션 시작
    private func startRainAnimation(in size: CGSize) {
        raindrops.removeAll()
        waterStreamDrops.removeAll()
        
        // 기존 타이머 정리
        timer?.invalidate()
        streamTimer?.invalidate()
        timerCancellable?.cancel()
        
        // 모든 물줄기 타이머 정리
        for stream in activeStreams.values {
            stream.timer?.invalidate()
        }
        activeStreams.removeAll()
        
        // 물방울 생성 타이머
        timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { _ in
            // 빗물 생성 (더 긴 간격으로)
            if Double.random(in: 0...1) < 0.1 { // 10% 확률로 물방울 생성
                if self.raindrops.count < self.maxRaindrops {
                    self.createRaindrop(in: size)
                }
            }
            
            // 페이드 아웃 효과와 충돌 체크
            self.checkStreamCollisions()
            
            // 물줄기 방울들 중 화면 밖으로 나간 것들도 페이드 아웃 처리
            self.checkOutOfBoundsDrops(in: size)
        }
        
        // SpriteKit 비 효과 생성 - 투명 배경 보장
        let scene = RainFall()
        scene.backgroundColor = .clear
        rainScene = scene
    }
    
    // 빗물 애니메이션 중지
    private func stopRainAnimation() {
        timer?.invalidate()
        timer = nil
        
        streamTimer?.invalidate()
        streamTimer = nil
        
        timerCancellable?.cancel()
        timerCancellable = nil
        
        // 모든 물줄기 타이머 정리
        for stream in activeStreams.values {
            stream.timer?.invalidate()
        }
        activeStreams.removeAll()
        
        // 점진적으로 사라지게 처리
        withAnimation(.easeOut(duration: 3)) {
            raindrops.removeAll()
        }
        
        // 물줄기 방울 페이드 아웃 효과 적용
        for i in 0..<waterStreamDrops.count {
            waterStreamDrops[i].isFading = true
        }
        
        // RainFall SKScene 천천히 투명화
        rainScene?.children.forEach { node in
            node.run(SKAction.fadeOut(withDuration: 1)) {
                self.rainScene = nil // 완전히 투명해지면 Scene 삭제
            }
        }
    }
    
    // 새로운 빗물 생성
    private func createRaindrop(in size: CGSize) {
        // 랜덤 이미지 선택
        let randomImage = waterdropImages.randomElement() ?? "waterdrop_01"
        
        let newRaindrop = Raindrop(
            id: UUID(),
            position: CGPoint(
                x: CGFloat.random(in: 20...(size.width - 20)),
                y: CGFloat.random(in: 0...size.height) // 화면 전체 높이에서 랜덤하게 생성
            ),
            size: CGFloat.random(in: 5...15),//CGFloat.random(in: 5...8),
            speed: CGFloat.random(in: 2...5),
            creationTime: Date(),
            imageName: randomImage
        )
        
        raindrops.append(newRaindrop)
    }
    
    // 랜덤 물줄기 시작 (독립적으로 실행)
    private func startRandomStreams(in size: CGSize) {
        // 이전 타이머 정리
        streamTimer?.invalidate()
        
        streamTimer = Timer.scheduledTimer(withTimeInterval: newStreamInterval, repeats: true) { _ in
            // 랜덤 위치에서 물줄기 시작
            let randomX = CGFloat.random(in: 20...(size.width - 20))
            let randomY = CGFloat.random(in: 20...(size.height / 2)) // 화면 상단 절반에서 시작
            
            startWaterdropStream(at: CGPoint(x: randomX, y: randomY), in: size)
        }
    }
    
    // 물방울 스트림 시작
    private func startWaterdropStream(at position: CGPoint, in size: CGSize) {
        let streamId = UUID()
        var currentPosition = position
        
        // 물줄기의 방향 결정 (대각선 포함)
        // 각도는 라디안 단위: 0.5π(90°)는 수직 아래, 0.3π~0.7π는 대각선 범위
        let angle = CGFloat.random(in: 0.3 * .pi...0.7 * .pi)
        let xVelocity = cos(angle) * 20  // X 방향 속도
        let yVelocity = sin(angle) * 30  // Y 방향 속도 (항상 양수로 아래쪽)
        
        // 물줄기 정보 생성
        let streamTimer = Timer.scheduledTimer(withTimeInterval: streamDropInterval, repeats: true) { timer in
            // 랜덤 이미지 선택
            let randomImage = waterdropImages.randomElement() ?? "waterdrop_01"
            // 약간의 무작위성 추가 (물방울마다 약간의 편차)
            let randomOffset = CGPoint(
                x: CGFloat.random(in: -5...5),
                y: CGFloat.random(in: -5...5)
            )
            
            // 물줄기 방울 생성
            let newDrop = StreamDrop(
                id: UUID(),
                position: CGPoint(
                    x: currentPosition.x + randomOffset.x,
                    y: currentPosition.y + randomOffset.y
                ),
                imageName: randomImage,
                creationTime: Date(),
                opacity: 1.0,
                isFading: false
            )
            
            // 물줄기 방울 추가
            waterStreamDrops.append(newDrop)
            
            // 이전 물방울 제거 (너무 오래된 물방울)
            let currentTime = Date()
            for i in 0..<waterStreamDrops.count {
                // 아직 페이드 아웃이 시작되지 않은 오래된 물방울 찾기
                if !waterStreamDrops[i].isFading &&
                    currentTime.timeIntervalSince(waterStreamDrops[i].creationTime) > 0.1 {
                    // 페이드 아웃 시작으로 표시
                    waterStreamDrops[i].isFading = true
                }
            }
            
            // 위치 업데이트 (대각선 방향으로)
            currentPosition.x += xVelocity
            currentPosition.y += yVelocity
            
            // 화면 밖으로 나가면 타이머 중지
            if currentPosition.y > size.height + 30 ||
               currentPosition.x < -30 ||
               currentPosition.x > size.width + 30 {
                timer.invalidate()
                activeStreams[streamId] = nil
            }
        }
        
        // 활성 스트림에 추가
        activeStreams[streamId] = StreamInfo(timer: streamTimer)
    }
    
    // 화면 밖으로 나간 물방울 체크
    private func checkOutOfBoundsDrops(in size: CGSize) {
        for i in 0..<waterStreamDrops.count {
            let drop = waterStreamDrops[i]
            
            // 화면 밖으로 나간 물방울이면서 아직 페이드 아웃 중이 아닌 경우
            if (drop.position.y > size.height + 30 ||
                drop.position.x < -30 ||
                drop.position.x > size.width + 30) && !drop.isFading {
                waterStreamDrops[i].isFading = true
            }
        }
    }
    
    // 물줄기와 빗물의 충돌 체크 및 물줄기 간 충돌 체크
    private func checkStreamCollisions() {
        var raindropsToRemove = Set<UUID>()
        var streamDropsToFade = Set<UUID>()  // 페이드 아웃할 물방울들
        
        // 먼저 생성된 물줄기와 나중에 생성된 물줄기 구분을 위해 정렬
        let sortedStreamDrops = waterStreamDrops.sorted { $0.creationTime < $1.creationTime }
        
        // 물줄기와 빗물 충돌 체크
        for streamDrop in sortedStreamDrops {
            // 이미 페이드 아웃 중인 물방울은 건너뜀
            if streamDrop.isFading {
                continue
            }
            
            // 스트림 물방울의 대략적인 충돌 범위
            let streamRect = CGRect(
                x: streamDrop.position.x - 12,
                y: streamDrop.position.y - 12,
                width: 24,
                height: 24
            )
            
            // 빗물과의 충돌 체크
            for raindrop in raindrops {
                // 빗물의 대략적인 경계 계산
                let dropRect = CGRect(
                    x: raindrop.position.x - raindrop.size / 2,
                    y: raindrop.position.y - raindrop.size / 2,
                    width: raindrop.size,
                    height: raindrop.size
                )
                
                // 흘러내림 효과와 빗물 충돌 체크
                if streamRect.intersects(dropRect) {
                    raindropsToRemove.insert(raindrop.id)
                }
            }
            
            // 물줄기끼리의 충돌 체크 - 현재 물방울보다 나중에 생성된 물방울들과만 비교
            for otherDropIndex in sortedStreamDrops.indices {
                let otherDrop = sortedStreamDrops[otherDropIndex]
                
                // 자기 자신과는 충돌 체크 안함
                if streamDrop.id == otherDrop.id {
                    continue
                }
                
                // 나중에 생성된 물방울과만 비교 (먼저 생성된 물방울만 제거하기 위해)
                if otherDrop.creationTime <= streamDrop.creationTime {
                    continue
                }
                
                // 이미 페이드 아웃 중인 물방울은 충돌 체크에서 제외
                if otherDrop.isFading {
                    continue
                }
                
                // 다른 물줄기 방울의 충돌 범위
                let otherRect = CGRect(
                    x: otherDrop.position.x - 12,
                    y: otherDrop.position.y - 12,
                    width: 24,
                    height: 24
                )
                
                // 물줄기끼리 충돌 체크
                if streamRect.intersects(otherRect) {
                    // 먼저 생성된 물방울만 페이드 아웃 대상에 추가
                    streamDropsToFade.insert(streamDrop.id)
                    break  // 이미 제거 대상이므로 더 이상 확인 필요 없음
                }
            }
        }
        
        // 충돌한 빗물 제거
        raindrops.removeAll { raindropsToRemove.contains($0.id) }
        
        // 충돌한 물줄기 방울들에 페이드 아웃 효과 적용 시작
        for i in 0..<waterStreamDrops.count {
            if streamDropsToFade.contains(waterStreamDrops[i].id) {
                waterStreamDrops[i].isFading = true
            }
        }
        
        // 페이드 아웃 진행 중인 물방울들의 투명도 업데이트
        updateFadingDrops()
    }
    
    // 페이드 아웃 중인 물방울들 업데이트
    private func updateFadingDrops() {
        let currentTime = Date()
        
        for i in 0..<waterStreamDrops.count {
            // 페이드 아웃 중인 물방울만 처리
            if waterStreamDrops[i].isFading {
                // 페이드 아웃 시작 시점이 없으면 현재 시간으로 설정
                let fadeStartTime = waterStreamDrops[i].creationTime
                let elapsedTime = currentTime.timeIntervalSince(fadeStartTime)
                
                // 2초 동안 서서히 투명해지도록 설정
                let fadeDuration: TimeInterval = 2.0
                let newOpacity = max(0, 1.0 - (elapsedTime / fadeDuration))
                
                waterStreamDrops[i].opacity = newOpacity
            }
        }
        
        // 완전히 투명해진 물방울은 제거
        waterStreamDrops.removeAll { $0.opacity <= 0 }
    }
}

// 빗물 모델
struct Raindrop: Identifiable {
    var id: UUID
    var position: CGPoint
    var size: CGFloat
    var speed: CGFloat
    var creationTime: Date
    var imageName: String
}

// 흘러내리는 물방울 모델
struct StreamDrop: Identifiable {
    var id: UUID
    var position: CGPoint
    var imageName: String
    var creationTime: Date
    var opacity: Double = 1.0   // 투명도 (1.0 = 완전 불투명, 0.0 = 완전 투명)
    var isFading: Bool = false  // 페이드 아웃 중인지 여부
}

// 물줄기 정보 모델
struct StreamInfo {
    var timer: Timer?
}

enum WeatherState {
    case day
    case night
    case stop
}

class RainFall: SKScene {
    override func sceneDidLoad() {
        size = UIScreen.main.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0)
        
        // 명시적으로 투명 배경 설정
        backgroundColor = .clear
        
        if let rainNode = SKEmitterNode(fileNamed: "Rain.sks") {
            rainNode.position = CGPoint(x: size.width / 2, y: 1000)
            rainNode.particlePositionRange = CGVector(dx: size.width * 2, dy: 0) // X축 전체로 확산
            rainNode.particlePosition = CGPoint(x: 0, y: 0) // 중앙 기준으로 확산
            rainNode.zPosition = 1
            addChild(rainNode)
        }
    }
}

class RainFallLanding: SKScene {
    override func sceneDidLoad() {
        size = UIScreen.main.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0) // 하단 기준
        
        // 명시적으로 투명 배경 설정
        backgroundColor = .clear
        
        if let node = SKEmitterNode(fileNamed: "RainFallLanding.sks") {
            node.particlePositionRange = CGVector(dx: 240, dy: 0) // X축 전체로 확산
            addChild(node)
        }
    }
}

// 버튼 스타일 지정
struct BasicButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(configuration.isPressed ? Color.white : Color.clear, lineWidth: 3)
            )
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
