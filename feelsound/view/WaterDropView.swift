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
    @State private var backgroundImage: String = "nature"
    @State private var rainScene: RainFall? = RainFall()
    
    var body: some View {
        ZStack {
            Image(backgroundImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 1.4)
            
            Color.black
                .opacity(weatherState == .stop ? (previousWeatherState == .night ? 0.5 : 0) : (weatherState == .night ? 0.5 : 0))
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1), value: weatherState)
            
            ZStack {
                //RainFall
                if let rainScene = rainScene {
                    SpriteView(scene: rainScene, options: [.allowsTransparency])
                }
                
                ForEach(raindrops) { raindrop in
                    Image(raindrop.imageName)
                        .resizable()
                        .frame(width: raindrop.size, height: raindrop.size)
                        .position(x: raindrop.x, y: raindrop.y)
                }
            }
            
            VStack {
                Spacer()
                // RainFallLanding - 버튼 위에서 튕기게
                if rainScene != nil {
                    SpriteView(scene: RainFallLanding(), options: [.allowsTransparency])
                    .offset(y: 5)                }
                
                
                HStack(spacing: 8) {
                    Button("DAY") {
                        weatherState == .stop ? startRain() : nil
                        weatherState = .day
                        previousWeatherState = .day
                    }
                    .buttonStyle(BasicButtonStyle())
                    
                    Button("STOP") {
                        if weatherState != .stop {
                            previousWeatherState = weatherState
                        }
                        stopRain()
                        weatherState = .stop
                    }
                    .buttonStyle(BasicButtonStyle())
                    
                    Button("NIGHT") {
                        weatherState == .stop ? startRain() : nil
                        weatherState = .night
                        previousWeatherState = .night
                    }
                    .buttonStyle(BasicButtonStyle())
                }
                .padding(.bottom, 20)
                
            }
            .onAppear {
                startRain()
            }
        }
    }
    
    private func startRain() {
        raindrops.removeAll()
        timerCancellable?.cancel()
        
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.addRaindrop()
            }
        
        rainScene = RainFall()
    }
    
    private func stopRain() {
        timerCancellable?.cancel()
        timerCancellable = nil
        
        // RainDrop 투명도 점차 줄이기
        withAnimation(.easeOut(duration: 3)) {
            raindrops.removeAll()
        }
        
        // RainFall SKScene 천천히 투명화
        rainScene?.children.forEach { node in
            node.run(SKAction.fadeOut(withDuration: 1)) {
                self.rainScene = nil // 완전히 투명해지면 Scene 삭제
            }
        }
    }
    
    private func addRaindrop() {
        let raindropImages = ["waterdrop_01", "waterdrop_02", "waterdrop_03", "waterdrop_04"]
        let dropCount = 20
        
        for _ in 0..<dropCount {
            guard let randomImageName = raindropImages.randomElement() else { continue }
            
            let dropSize = CGFloat.random(in: 1...7)
            let randomX = CGFloat.random(in: 0...1000)
            let randomY = CGFloat.random(in: -50...(UIScreen.main.bounds.height))
            
            let newRaindrop = Raindrop(id: UUID(), imageName: randomImageName, x: randomX, y: randomY, size: dropSize)
            raindrops.append(newRaindrop)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                raindrops.removeAll { $0.id == newRaindrop.id }
            }
        }
    }
}

struct Raindrop: Identifiable, Equatable {
    let id: UUID
    var imageName: String
    let x: CGFloat
    var y: CGFloat
    var size: CGFloat
}

enum WeatherState {
    case day
    case night
    case stop
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

class RainFall: SKScene {
    override func sceneDidLoad() {
        size = UIScreen.main.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0)
        
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
        
        backgroundColor = .clear
        
        if let node = SKEmitterNode(fileNamed: "RainFallLanding.sks") {
            node.particlePositionRange = CGVector(dx: 240, dy: 0) // X축 전체로 확산
            addChild(node)
        }
    }
}
