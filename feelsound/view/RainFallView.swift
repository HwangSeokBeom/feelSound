//
//  RainView.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI

struct RainFallView: View {
    @EnvironmentObject var router: Router

    var body: some View {
        ZStack {
            // Background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            
            // Rain effect
            RainView(
                windDirection: 1.2,   // Positive for right, negative for left
                density: 200,         // Number of raindrops
                opacity: 0.7          // Raindrop opacity
            )
            .overlay(alignment : .topLeading){
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
            }
        }
    }
}


// MARK: - Models

struct Vector2 {
    var x: CGFloat
    var y: CGFloat
}

struct WaterDrop: Identifiable {
    let id = UUID()
    var position: Vector2
    var velocity: Vector2
    var radius: CGFloat
    var trailLength: CGFloat
    var touchedGround = false
    var isDead = false
    var splatters: [Splatter] = []
    var splatterFrameCount: Int = 0
    
    static let maxSplatterPerRaindrop = 4
    static let maxSplatterFrameCount = 30
    static let terminalVelocity: CGFloat = 500
    static let windMultiplier: CGFloat = 40
    static let splatterStartingVelocity: CGFloat = 100
    
    mutating func updatePosition(deltaSeconds: Double, screenSize: CGSize) {
        if isDead { return }
        
        // Update position
        position.x += velocity.x * CGFloat(deltaSeconds)
        position.y += velocity.y * CGFloat(deltaSeconds)
        
        if !touchedGround {
            if position.y + radius >= screenSize.height {
                touchedGround = true
                position.y = screenSize.height
                
                // Check if raindrop is within bounds
                if position.x >= 0 && position.x <= screenSize.width {
                    createSplatters(screenSize: screenSize)
                } else {
                    isDead = true
                }
            }
        } else {
            // Update splatters
            for i in 0..<splatters.count {
                splatters[i].updatePosition(deltaSeconds: deltaSeconds, screenSize: screenSize)
            }
            
            // Update frame count for splatter animation
            splatterFrameCount += 1
            isDead = splatterFrameCount >= WaterDrop.maxSplatterFrameCount
        }
    }
    
    mutating func createSplatters(screenSize: CGSize) {
        for _ in 0..<WaterDrop.maxSplatterPerRaindrop {
            // Generate random angle for the splatter (20-70° or 110-160°)
            let useFirstRange = Bool.random()
            let angleBounce = useFirstRange ?
                CGFloat.random(in: 20...70) :
                CGFloat.random(in: 110...160)
            
            let angleBounceRadians = angleBounce * (CGFloat.pi / 180.0)
            
            // Calculate velocity components
            let velX = WaterDrop.splatterStartingVelocity * cos(angleBounceRadians)
            let velY = -WaterDrop.splatterStartingVelocity * sin(angleBounceRadians)
            
            let splatterVelocity = Vector2(x: velX, y: velY)
            let splatter = Splatter(position: position, velocity: splatterVelocity, radius: radius * 0.7)
            
            splatters.append(splatter)
        }
    }
}

struct Splatter: Identifiable {
    let id = UUID()
    var position: Vector2
    var velocity: Vector2
    var radius: CGFloat
    static let gravity: CGFloat = 500
    
    mutating func updatePosition(deltaSeconds: Double, screenSize: CGSize) {
        // Apply gravity
        velocity.y += Splatter.gravity * CGFloat(deltaSeconds)
        
        // Update position
        position.x += velocity.x * CGFloat(deltaSeconds)
        position.y += velocity.y * CGFloat(deltaSeconds)
        
        // Optional: Add bounds checking if needed
    }
}

// MARK: - Rain System

class RainSystem: ObservableObject {
    @Published var raindrops: [WaterDrop] = []
    
    private var screenSize: CGSize = .zero
    private var lastUpdateTime: Date = Date()
    private var timer: Timer?
    private let windDirectionFactor: CGFloat
    private let density: Int
    
    init(windDirection: CGFloat = 1.0, density: Int = 100) {
        self.windDirectionFactor = windDirection
        self.density = density
    }
    
    func startRain(screenSize: CGSize) {
        self.screenSize = screenSize
        
        // Initialize raindrops
        raindrops = []
        for _ in 0..<density {
            raindrops.append(createRaindrop())
        }
        
        // Start update timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.update()
        }
    }
    
    func stopRain() {
        timer?.invalidate()
        timer = nil
    }
    
    private func update() {
        let now = Date()
        let deltaSeconds = now.timeIntervalSince(lastUpdateTime)
        lastUpdateTime = now
        
        // Update existing raindrops
        for i in 0..<raindrops.count {
            raindrops[i].updatePosition(deltaSeconds: deltaSeconds, screenSize: screenSize)
        }
        
        // Remove dead raindrops and replace with new ones
        let deadCount = raindrops.filter { $0.isDead }.count
        raindrops.removeAll { $0.isDead }
        
        for _ in 0..<deadCount {
            raindrops.append(createRaindrop())
        }
    }
    
    private func createRaindrop() -> WaterDrop {
        // Extra width to account for wind effect
        let extraWidth = screenSize.width / 3
        
        // Random x position
        let x = CGFloat.random(in: -extraWidth...(screenSize.width + extraWidth))
        
        // Start above screen
        let startOffset = CGFloat.random(in: 0...(screenSize.height / 2))
        let y = -startOffset
        
        // Random drop attributes
        let radius = CGFloat.random(in: 0.2...0.7)
        let trailLength = CGFloat.random(in: 30...100)
        
        // Calculate velocity
        let velocityX = WaterDrop.windMultiplier * windDirectionFactor
        let velocityY = WaterDrop.terminalVelocity
        
        return WaterDrop(
            position: Vector2(x: x, y: y),
            velocity: Vector2(x: velocityX, y: velocityY),
            radius: radius,
            trailLength: trailLength
        )
    }
}

// MARK: - Views

struct RainDropView: View {
    let raindrop: WaterDrop
    let opacity: Double
    
    var body: some View {
        ZStack {
            // Draw raindrop trail
            if !raindrop.touchedGround {
                let startX = raindrop.position.x - (raindrop.velocity.x * raindrop.trailLength / raindrop.velocity.y)
                let startY = raindrop.position.y - raindrop.trailLength
                
                Path { path in
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: raindrop.position.x, y: raindrop.position.y))
                }
                .stroke(Color(.sRGB, white: 1.0, opacity: opacity), lineWidth: raindrop.radius * 2)
            }
            
            // Draw splatters
            ForEach(raindrop.splatters, id: \.id) { splatter in
                Circle()
                    .fill(Color(.sRGB, white: 1.0, opacity: opacity * 0.8))
                    .frame(width: splatter.radius * 2, height: splatter.radius * 2)
                    .position(x: splatter.position.x, y: splatter.position.y)
            }
        }
    }
}

struct RainView: View {
    @StateObject private var rainSystem: RainSystem
    @State private var screenSize: CGSize = .zero
    
    let opacity: Double
    
    init(windDirection: CGFloat = 1.0, density: Int = 100, opacity: Double = 0.6) {
        _rainSystem = StateObject(wrappedValue: RainSystem(windDirection: windDirection, density: density))
        self.opacity = opacity
    }
    
    var body: some View {
        ZStack {
            Color.clear
            
            // Draw all raindrops
            ForEach(rainSystem.raindrops) { raindrop in
                RainDropView(raindrop: raindrop, opacity: opacity)
            }
        }
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear {
                    screenSize = geometry.size
                    rainSystem.startRain(screenSize: screenSize)
                }
                .onChange(of: geometry.size) { newSize in
                    screenSize = newSize
                    rainSystem.startRain(screenSize: screenSize)
                }
        })
        .onDisappear {
            rainSystem.stopRain()
        }
    }
}

