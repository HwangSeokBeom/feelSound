//
//  LiquidFlowView.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//


import SwiftUI
import CoreMotion

// MARK: - 액체 효과를 위한 환경 설정
class LiquidFlowManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var gravity: CGVector = .zero
    @Published var drops: [LiquidDrop] = []
    private var timer: Timer?
    
    init() {
        setupMotionManager()
        createInitialDrops()
    }
    
    private func setupMotionManager() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let data = data, error == nil else { return }
                
                // 가속도 데이터를 중력 벡터로 변환
                let gravityX = CGFloat(data.acceleration.x) * 5
                let gravityY = CGFloat(data.acceleration.y) * 5
                
                withAnimation(.spring()) {
                    self?.gravity = CGVector(dx: gravityX, dy: gravityY)
                }
            }
        }
    }
    
    private func createInitialDrops() {
        // 초기 액체 방울들 생성
        for _ in 0..<15 {
            drops.append(LiquidDrop(
                position: CGPoint(
                    x: CGFloat.random(in: 50...300),
                    y: CGFloat.random(in: 50...600)
                ),
                size: CGFloat.random(in: 30...60),
                color: Color(
                    red: Double.random(in: 0...0.5),
                    green: Double.random(in: 0.5...0.8),
                    blue: Double.random(in: 0.8...1.0),
                    opacity: Double.random(in: 0.7...0.9)
                ),
                opacity: Double.random(in: 0.7...0.9)

            ))
        }
        
        // 방울 움직임 타이머 시작
        startAnimation()
    }
    
    func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.updateDropPositions()
        }
    }
    
    func updateDropPositions() {
        let bounds = UIScreen.main.bounds
        let friction: CGFloat = 0.97
        
        for i in 0..<drops.count {
            // 중력 적용
            var drop = drops[i]
            
            // 속도 업데이트
            drop.velocity.x += gravity.dx * 0.2
            drop.velocity.y -= gravity.dy * 0.2
            
            // 마찰 적용
            drop.velocity.x *= friction
            drop.velocity.y *= friction
            
            // 위치 업데이트
            drop.position.x += drop.velocity.x
            drop.position.y += drop.velocity.y
            
            // 화면 경계 체크
            if drop.position.x < 0 {
                drop.position.x = 0
                drop.velocity.x *= -0.7
            } else if drop.position.x > bounds.width {
                drop.position.x = bounds.width
                drop.velocity.x *= -0.7
            }
            
            if drop.position.y < 0 {
                drop.position.y = 0
                drop.velocity.y *= -0.7
            } else if drop.position.y > bounds.height {
                drop.position.y = bounds.height
                drop.velocity.y *= -0.7
            }
            
            // 업데이트된 방울 저장
            drops[i] = drop
        }
        
        // 충돌 감지 및 처리
        detectCollisions()
    }
    
    func detectCollisions() {
        for i in 0..<drops.count {
            for j in (i+1)..<drops.count {
                let drop1 = drops[i]
                let drop2 = drops[j]
                
                let dx = drop2.position.x - drop1.position.x
                let dy = drop2.position.y - drop1.position.y
                let distance = sqrt(dx * dx + dy * dy)
                let minDistance = (drop1.size + drop2.size) / 2
                
                if distance < minDistance {
                    // 충돌 발생
                    let angle = atan2(dy, dx)
                    let targetX = drop1.position.x + cos(angle) * minDistance
                    let targetY = drop1.position.y + sin(angle) * minDistance
                    
                    let ax = (targetX - drop2.position.x) * 0.05
                    let ay = (targetY - drop2.position.y) * 0.05
                    
                    var updatedDrop1 = drop1
                    var updatedDrop2 = drop2
                    
                    updatedDrop1.velocity.x -= ax
                    updatedDrop1.velocity.y -= ay
                    updatedDrop2.velocity.x += ax
                    updatedDrop2.velocity.y += ay
                    
                    drops[i] = updatedDrop1
                    drops[j] = updatedDrop2
                }
            }
        }
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
        timer?.invalidate()
    }
}

// MARK: - 액체 방울 뷰
struct LiquidDropView: View {
    let drop: LiquidDrop
    
    var body: some View {
        Circle()
            .fill(drop.color)
            .frame(width: drop.size, height: drop.size)
            .position(drop.position)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
            .blur(radius: 3)
    }
}

// MARK: - 메인 뷰
struct LiquidFlowView: View {
    @EnvironmentObject var router: Router

    @StateObject private var flowManager = LiquidFlowManager()
    @State var showSubscription : Bool = false

    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [.black, Color(red: 0.1, green: 0.1, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 액체 방울들
            ForEach(flowManager.drops) { drop in
                LiquidDropView(drop: drop)
            }
            
            // UI 요소들
            VStack {
                HStack{
                    HStack{
                        Text("FeelSound")
                            .font(.righteous(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action : {
                        showSubscription.toggle()
                    },
                           label : {
                        HStack {
                            Image(systemName : "crown.fill")
                                .resizable()
                                .foregroundColor(.yellow)
                                .frame(width : 24, height : 24)
                            
                            Text("Pro")
                                .foregroundColor(.yellow)
                                .font(.system(size:12, weight:.bold))
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(.yellow, lineWidth: 2.0)
                        )
                    })
                    .padding(4)
                }
                .padding(.horizontal, 20)
                
                
                VStack{
                    HStack(alignment : .bottom){
                        
                        Text("Get to know \nyourself \nbetter")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        
                        NavigationLink(destination : {
                            
                        }){
                            Text("Get Answers")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.bluePurple)
                                .clipShape(Capsule())
                                .glowing()
                        }
                    }
                    .padding(.vertical, 20)
                    
                    LazyVStack{
                        Button {
                            router.navigate(to: .sampleView1)
                        } label: {
                            Text("SampleView1")
                                .foregroundColor(.white)

                        }
                        
                        Button {
                            router.navigate(to: .sampleView2)
                        } label: {
                            Text("SampleView2")
                                .foregroundColor(.white)

                        }
                        
                        Button {
                            router.navigate(to: .sampleView3)
                        } label: {
                            Text("SampleView3")
                                .foregroundColor(.white)

                        }
                        
                        Button {
                            router.navigate(to: .coloring)
                        } label: {
                            Text("ColoringView")
                                .foregroundColor(.white)

                        }
                    }
                }
                
                Spacer()

            }
        }
    }
}
