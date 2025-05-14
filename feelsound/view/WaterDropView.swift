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

struct WaterDropView: View {
    @EnvironmentObject var router: Router
    
    @State private var raindrops: [Raindrop] = []
    @State private var weatherState: WeatherState = .day
    @State private var previousWeatherState: WeatherState = .day
    @State private var rainScene: RainFall? = RainFall()
    @State private var timer: Timer?
    @State private var waterStreamDrops: [StreamDrop] = []
    @State private var activeStreams: [UUID: StreamInfo] = [:]
    
    @StateObject private var motionManager = MotionManager()
    
    // Constants
    private let maxRaindrops: Int = 300
    private let waterdropImages = ["waterdrop_01", "waterdrop_02", "waterdrop_03", "waterdrop_04"]
    
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
                    // SpriteKit rain
                    if let rainScene = rainScene {
                        SpriteView(scene: rainScene, options: [.allowsTransparency])
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .allowsHitTesting(false)
                    }
                    
                    // Stream drops
                    ForEach(waterStreamDrops) { drop in
                        Image(drop.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
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
                }
                
                // UI controls
                VStack {
                    Spacer()
                    
                    // Splash effect
                    if rainScene != nil {
                        SpriteView(scene: RainFallLanding(), options: [.allowsTransparency])
                            .frame(width: geometry.size.width, height: 50)
                    }
                    
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
                motionManager.startDeviceMotionUpdates()
                startRainAnimation(in: geometry.size)
                startRandomStreams(in: geometry.size)
            }
            .onDisappear {
                motionManager.stopDeviceMotionUpdates()
                stopRainAnimation()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func setWeatherState(_ state: WeatherState) {
        if weatherState == .stop {
            startRainAnimation(in: UIScreen.main.bounds.size)
            startRandomStreams(in: UIScreen.main.bounds.size)
        }
        weatherState = state
        previousWeatherState = state
    }
    
    // Start rain animation
    private func startRainAnimation(in size: CGSize) {
        raindrops.removeAll()
        waterStreamDrops.removeAll()
        
        // Clear timers
        timer?.invalidate()
        
        for stream in activeStreams.values {
            stream.timer?.invalidate()
        }
        activeStreams.removeAll()
        
        // Create raindrop generation timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            // Create raindrops with 10% probability
            if Double.random(in: 0...1) < 0.1 && self.raindrops.count < self.maxRaindrops {
                self.createRaindrop(in: size)
            }
            
            self.checkStreamCollisions()
            self.checkOutOfBoundsDrops(in: size)
        }
        
        // Setup SpriteKit rain scene
        let scene = RainFall()
        scene.backgroundColor = .clear
        scene.motionManager = motionManager
        rainScene = scene
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
        }
        
        // Mark all water stream drops for fading
        for i in 0..<waterStreamDrops.count {
            waterStreamDrops[i].isFading = true
        }
        
        // Fade out SpriteKit scene
        rainScene?.children.forEach { node in
            node.run(SKAction.fadeOut(withDuration: 1)) {
                self.rainScene = nil
            }
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
            size: CGFloat.random(in: 5...15),
            speed: CGFloat.random(in: 2...5),
            creationTime: Date(),
            imageName: randomImage
        )
        
        raindrops.append(newRaindrop)
    }
    
    // Start random water streams
    private func startRandomStreams(in size: CGSize) {
        // Create a new stream every 0.5-1 seconds
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 0.5...1), repeats: true) { timer in
            // Only create new streams if not in STOP mode
            guard self.weatherState != .stop else {
                timer.invalidate()
                return
            }
            
            let randomX = CGFloat.random(in: 20...(size.width - 20))
            let randomY = CGFloat.random(in: 20...(size.height / 2))
            
            self.startWaterdropStream(at: CGPoint(x: randomX, y: randomY), in: size)
        }
    }
    
    // Start a water stream
    private func startWaterdropStream(at position: CGPoint, in size: CGSize) {
        let streamId = UUID()
        var currentPosition = position
        let yVelocity = 30.0
        
        let streamTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            // Get random image and create slight offset
            let randomImage = self.waterdropImages.randomElement() ?? "waterdrop_01"
            let randomOffset = CGPoint(x: CGFloat.random(in: -5...5), y: CGFloat.random(in: -5...5))
            
            // Update X velocity based on device tilt
            let currentXVelocity = self.getXVelocityFromMotion()
            
            // Create new stream drop
            let newDrop = StreamDrop(
                id: UUID(),
                position: CGPoint(x: currentPosition.x + randomOffset.x, y: currentPosition.y + randomOffset.y),
                imageName: randomImage,
                creationTime: Date()
            )
            
            self.waterStreamDrops.append(newDrop)
            
            // Set timer to start fading the drop after 2 seconds
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                if let index = self.waterStreamDrops.firstIndex(where: { $0.id == newDrop.id }) {
                    self.waterStreamDrops[index].isFading = true
                }
            }
            
            // Update current position
            currentPosition.x += currentXVelocity
            currentPosition.y += yVelocity
            
            // Stop if out of bounds
            if currentPosition.y > size.height + 30 || currentPosition.x < -30 || currentPosition.x > size.width + 30 {
                timer.invalidate()
                self.activeStreams[streamId] = nil
            }
        }
        
        activeStreams[streamId] = StreamInfo(timer: streamTimer)
    }
    
    // Calculate X velocity based on device tilt
    private func getXVelocityFromMotion() -> CGFloat {
        let roll = motionManager.roll
        let maxVelocity: CGFloat = 30.0
        let velocityFactor: CGFloat = 20.0
        
        return max(-maxVelocity, min(maxVelocity, roll * velocityFactor))
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
        
        // Remove completely faded drops
        updateFadingDrops()
    }
    
    // Check for collisions between streams and raindrops
    private func checkStreamCollisions() {
        var raindropsToRemove = Set<UUID>()
        let streamDropsToFade = Set<UUID>()
        
        for streamDrop in waterStreamDrops where !streamDrop.isFading {
            let streamRect = CGRect(
                x: streamDrop.position.x - 12,
                y: streamDrop.position.y - 12,
                width: 24,
                height: 24
            )
            
            // Check collisions with raindrops
            for raindrop in raindrops {
                let dropRect = CGRect(
                    x: raindrop.position.x - raindrop.size / 2,
                    y: raindrop.position.y - raindrop.size / 2,
                    width: raindrop.size,
                    height: raindrop.size
                )
                
                if streamRect.intersects(dropRect) {
                    raindropsToRemove.insert(raindrop.id)
                }
            }
        }
        
        // Remove collided raindrops
        raindrops.removeAll { raindropsToRemove.contains($0.id) }
        
        // Apply fade out effect to collided stream drops
        for i in 0..<waterStreamDrops.count {
            if streamDropsToFade.contains(waterStreamDrops[i].id) {
                waterStreamDrops[i].isFading = true
            }
        }
    }
    
    // Update fading drops
    private func updateFadingDrops() {
        let currentTime = Date()
        
        for i in 0..<waterStreamDrops.count {
            if waterStreamDrops[i].isFading {
                let fadeStartTime = waterStreamDrops[i].creationTime
                let elapsedTime = currentTime.timeIntervalSince(fadeStartTime)
                
                let fadeDuration: TimeInterval = 2.0
                let newOpacity = max(0, 1.0 - (elapsedTime / fadeDuration))
                
                waterStreamDrops[i].opacity = newOpacity
            }
        }
        
        // Remove completely transparent drops
        waterStreamDrops.removeAll { $0.opacity <= 0 }
    }
}

// Motion Manager
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    
    init() {
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
    }
    
    func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            
            self?.pitch = motion.attitude.pitch
            self?.roll = motion.attitude.roll
        }
    }
    
    func stopDeviceMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
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

struct StreamInfo {
    var timer: Timer?
}

enum WeatherState {
    case day
    case night
    case stop
}

// SpriteKit Scene for Rain
class RainFall: SKScene {
    var motionManager: MotionManager?
    private var emitterNode: SKEmitterNode?
    
    override func sceneDidLoad() {
        size = UIScreen.main.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0)
        backgroundColor = .clear
        
        if let rainNode = SKEmitterNode(fileNamed: "Rain.sks") {
            rainNode.position = CGPoint(x: size.width / 2, y: 1000)
            rainNode.particlePositionRange = CGVector(dx: size.width * 2, dy: 0)
            rainNode.zPosition = 1
            emitterNode = rainNode
            addChild(rainNode)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        updateRainDirection()
    }
    
    private func updateRainDirection() {
        guard let motionManager = motionManager, let emitter = emitterNode else { return }
        
        let roll = motionManager.roll
        let maxDeflection: CGFloat = 200
        let xSpeed = CGFloat(roll) * maxDeflection
        
        emitter.xAcceleration = xSpeed
    }
}

class RainFallLanding: SKScene {
    override func sceneDidLoad() {
        size = UIScreen.main.bounds.size
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0)
        backgroundColor = .clear
        
        if let node = SKEmitterNode(fileNamed: "RainFallLanding.sks") {
            node.particlePositionRange = CGVector(dx: 240, dy: 0)
            addChild(node)
        }
    }
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
