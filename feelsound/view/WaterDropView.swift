//
//  WaterDropView.swift
//  feelsound
//
//  Created by 안준경 on 5/8/25.
//

import SwiftUI
import Combine

struct WaterDropView: View {
    @State private var raindrops: [Raindrop] = []
    @State private var weatherState: WeatherState = .day
    @State private var timerCancellable: Cancellable? = nil
    @State private var backgroundImage: String = "nature"
    
    var body: some View {
        ZStack {
            // ✅ 배경 이미지 (항상 전체화면)
            Image(backgroundImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 1.4)
            
            // 배경 색상 변경 (DAY와 NIGHT에 따른 opacity 효과)
            Color.black
                .opacity(weatherState == .day ? 0 : 0.5) // DAY와 NIGHT 상태에 따른 opacity 변화
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1), value: weatherState)
            
            ZStack {
                ForEach(raindrops) { raindrop in
                    Image(raindrop.imageName)
                        .resizable()
                        .frame(width: raindrop.size, height: raindrop.size)
                        .position(x: raindrop.x, y: raindrop.y)
                }
            }
            
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Button("DAY") {
                        weatherState == .stop ? startRain() : nil
                        weatherState = .day
                    }
                    .buttonStyle(BasicButtonStyle())
                    
                    Button("STOP") {
                        stopRain()
                    }
                    .buttonStyle(BasicButtonStyle())
                    
                    Button("NIGHT") {
                        weatherState == .stop ? startRain() : nil
                        weatherState = .night
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
    
    // 비 내리기 시작
    private func startRain() {
        raindrops.removeAll()
        timerCancellable?.cancel() // ✅ 기존 타이머 정지 (stopRain() 호출 X)
        
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.addRaindrop()
            }
    }

    // 비 멈추기
    private func stopRain() {
        timerCancellable?.cancel()
        timerCancellable = nil
        raindrops.removeAll()
        weatherState = .stop // ✅ 여기서만 weatherState를 .stop으로 설정
    }
    
    // 빗방울 생성
    private func addRaindrop() {
        let raindropImages = ["waterdrop_01", "waterdrop_02", "waterdrop_03", "waterdrop_04"]
        let dropCount = Int.random(in: 10...15) // 한 번에 생성할 빗방울 개수
        
        for _ in 0..<dropCount {
            guard let randomImageName = raindropImages.randomElement() else { continue }
            
            let dropSize = CGFloat.random(in: 5...8) // 빗방울 크기
            
            let randomX = CGFloat.random(in: 0...1000)
            let randomY = CGFloat.random(in: -50...(UIScreen.main.bounds.height))
            
            let newRaindrop = Raindrop(id: UUID(), imageName: randomImageName, x: randomX, y: randomY, size: dropSize)
            raindrops.append(newRaindrop)
            
            // 빗방울 제거 (5초 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
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

struct WaterDropViewPreviews: PreviewProvider {
    static var previews: some View {
        WaterDropView()
            .previewLayout(.sizeThatFits)
    }
}
