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

    var body: some View {
        ZStack {
            backgroundView()
            
            ForEach(raindrops) { raindrop in
                Image(raindrop.imageName)
                    .resizable()
                    .frame(width: raindrop.size, height: raindrop.size)
                    .position(x: raindrop.x, y: raindrop.y)
            }
            
            VStack {
                Spacer()
                HStack {
                    Button("Day") {
                        startRain(with: .day)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Stop") {
                        stopRain()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Night") {
                        startRain(with: .night)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            startRain(with: .day)
        }
    }
    
    // ✅ 배경 이미지 변경
    @ViewBuilder
    private func backgroundView() -> some View {
        switch weatherState {
        case .day:
            Image("day_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        case .night:
            Image("night_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        case .stop:
            Color.clear.ignoresSafeArea()
        }
    }

    // ✅ 비 내리기 시작
    private func startRain(with state: WeatherState) {
        weatherState = state
        raindrops.removeAll()
        stopRain() // 기존 타이머 정지
        
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.addRaindrop()
            }
    }

    // ✅ 비 멈추기
    private func stopRain() {
        timerCancellable?.cancel()
        timerCancellable = nil
        raindrops.removeAll()
        weatherState = .stop
    }

    // ✅ 빗방울 생성
    private func addRaindrop() {
        let raindropImages = ["waterdrop_01", "waterdrop_02", "waterdrop_03", "waterdrop_04"]
        let dropCount = Int.random(in: 10...15) // 한 번에 생성할 빗방울 개수
        
        for _ in 0..<dropCount {
            guard let randomImageName = raindropImages.randomElement() else { continue }

            // ✅ 화면 전체에서 랜덤한 위치로 생성
            let randomX = CGFloat.random(in: 0...(UIScreen.main.bounds.width))
            let randomY = CGFloat.random(in: 0...(UIScreen.main.bounds.height - 200))
            let size = CGFloat.random(in: 5...8)

            let newRaindrop = Raindrop(id: UUID(), imageName: randomImageName, x: randomX, y: randomY, size: size)
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

// ✅ 날씨 상태 enum
enum WeatherState {
    case day
    case night
    case stop
}

// 버튼 스타일 지정
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(width: 230, height: 45)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .cornerRadius(6.0)
    }
}
