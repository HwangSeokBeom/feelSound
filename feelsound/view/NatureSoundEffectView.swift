//
//  NatureSoundEffectView.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//
import SwiftUI
import CoreMotion
import AVFoundation

// MARK: - 소리 종류
enum SoundType: String, CaseIterable, Identifiable {
    case crystal = "수정볼"
    case chimes = "풍경"
    case musicBox = "오르골"
    case ocean = "파도"
    case raindrops = "빗소리"
    case windBells = "윈드벨"
    case tibetanBowl = "티벳 싱잉볼"
    case harp = "하프"
    case woodWind = "목관악기"
    case kalimba = "칼림바"
    
    var id: String { self.rawValue }
    
    // 배경 색상
    var backgroundColors: [Color] {
        switch self {
        case .crystal:
            return [Color(red: 0.0, green: 0.1, blue: 0.3), Color(red: 0.2, green: 0.3, blue: 0.6)]
        case .chimes:
            return [Color(red: 0.3, green: 0.1, blue: 0.4), Color(red: 0.5, green: 0.3, blue: 0.6)]
        case .musicBox:
            return [Color(red: 0.5, green: 0.3, blue: 0.3), Color(red: 0.7, green: 0.5, blue: 0.5)]
        case .ocean:
            return [Color(red: 0.0, green: 0.2, blue: 0.4), Color(red: 0.0, green: 0.4, blue: 0.6)]
        case .raindrops:
            return [Color(red: 0.4, green: 0.4, blue: 0.5), Color(red: 0.6, green: 0.6, blue: 0.7)]
        case .windBells:
            return [Color(red: 0.2, green: 0.5, blue: 0.4), Color(red: 0.3, green: 0.7, blue: 0.5)]
        case .tibetanBowl:
            return [Color(red: 0.4, green: 0.3, blue: 0.1), Color(red: 0.6, green: 0.5, blue: 0.2)]
        case .harp:
            return [Color(red: 0.5, green: 0.4, blue: 0.6), Color(red: 0.7, green: 0.6, blue: 0.8)]
        case .woodWind:
            return [Color(red: 0.2, green: 0.4, blue: 0.2), Color(red: 0.3, green: 0.6, blue: 0.3)]
        case .kalimba:
            return [Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.8, green: 0.6, blue: 0.3)]
        }
    }
}

// MARK: - 충돌 소리 생성 클래스 (배경음 제외)
class SimpleSoundGenerator: ObservableObject {
    // 오디오 엔진
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    
    // 진동 및 소리 피드백
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // 상태
    @Published var isPlaying = false
    @Published var soundType: SoundType = .crystal
    
    // 소리 파라미터
    private var baseFrequency: Double = 440.0
    private var volume: Float = 0.7
    
    // 충돌 소리 관련
    private var lastCollisionTime: TimeInterval = 0.0
    
    // 동시 활성화된 소리 개수
    @Published var activeCollisionCount: Int = 0
    
    init() {
        setupAudio()
        impactFeedback.prepare()
    }
    
    // 오디오 설정
    private func setupAudio() {
        // 오디오 세션 설정
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("오디오 세션 설정 실패: \(error)")
        }
        
        // 오디오 포맷 설정
        let format = engine.outputNode.inputFormat(forBus: 0)
        
        // 믹서 설정
        engine.attach(mixer)
        
        // 믹서를 출력에 연결
        engine.connect(mixer, to: engine.outputNode, format: format)
        
        // 볼륨 설정
        mixer.volume = volume
        
        // 다중 플레이어 설정
        setupMultiplePlayers()
    }
    
    // 충돌 소리 재생 - 여러 소리 중첩 가능
    func triggerCollisionSound(intensity: Float) {
        guard isPlaying else { return }
        
        // 소리 간격 조절 (너무 많은 소리 방지) - 낮은 강도에서는 간격을 더 길게
        let currentTime = Date().timeIntervalSince1970
        let minInterval = intensity < 0.3 ? 0.1 : 0.03  // 낮은 강도에서는 소리 덜 발생
        if currentTime - lastCollisionTime < minInterval {
            return
        }
        lastCollisionTime = currentTime
        
        // 충돌 강도에 따른 진동 피드백 (낮게 설정)
        if intensity > 0.4 {
            // 진동 강도를 낮게 설정 (0.7 대신 0.4)
            impactFeedback.impactOccurred(intensity: CGFloat(intensity) * 0.6)
        }
        
        // 소리 유형에 따른 충돌음 특성 설정
        let baseSoundFrequency: Double
        let duration: Double = max(0.05, min(0.15, Double(intensity) * 0.15))  // 강도에 따라 지속 시간 조절
        
        switch soundType {
        case .crystal:
            // 맑은 높은 음
            baseSoundFrequency = 1200.0
        case .chimes:
            // 금속성 소리
            baseSoundFrequency = 1800.0
        case .musicBox:
            // 뮤직박스 음계에서 랜덤 선택
            let notes = [1.0, 9/8.0, 5/4.0, 4/3.0, 3/2.0, 5/3.0, 15/8.0, 2.0]
            baseSoundFrequency = 700.0 * notes.randomElement()!
        case .ocean:
            // 물 방울 소리
            baseSoundFrequency = 900.0
        case .raindrops:
            // 빗방울 소리
            baseSoundFrequency = 1400.0
        case .windBells:
            // 윈드벨 소리 - 맑고 은은한 소리
            let notes = [1.0, 1.2, 1.33, 1.5, 1.66, 2.0]
            baseSoundFrequency = 900.0 * notes.randomElement()!
        case .tibetanBowl:
            // 티벳 싱잉볼 - 낮고 울리는 소리
            baseSoundFrequency = 300.0 + Double.random(in: 0...200)
        case .harp:
            // 하프 - 부드럽고 맑은 음계
            let notes = [0.66, 0.75, 1.0, 1.25, 1.33, 1.5, 2.0]
            baseSoundFrequency = 600.0 * notes.randomElement()!
        case .woodWind:
            // 목관악기 - 부드럽고 따뜻한 소리
            let notes = [0.75, 1.0, 1.25, 1.5, 1.66]
            baseSoundFrequency = 500.0 * notes.randomElement()!
        case .kalimba:
            // 칼림바 - 독특하고 맑은 음색
            let notes = [0.8, 1.0, 1.2, 1.33, 1.6, 2.0]
            baseSoundFrequency = 550.0 * notes.randomElement()!
        }
        
        // 약간의 주파수 변화를 줘서 더 자연스럽게
        let frequencyVariation = Double.random(in: -50...50)
        let soundFrequency = baseSoundFrequency + frequencyVariation
        
        // 충돌 강도에 따른 볼륨 조절 (작은 충돌은 더 작은 소리)
        // 전체 볼륨을 낮게 조정 (0.7 대신 0.4 곱하기)
        let adjustedAmplitude = Double(intensity) * 0.4
        
        // 충돌음 생성 및 재생 - 기존 소리를 중단하지 않고 중첩
        playCollisionTone(frequency: soundFrequency, amplitude: adjustedAmplitude, duration: duration)
    }
    
    // 다중 플레이어 및 버퍼 캐시
    private var playerNodes: [AVAudioPlayerNode] = []
    private var maxPlayers = 8  // 최대 동시 재생 소리 개수
    
    // 초기화 중에 여러 플레이어 노드 생성
    private func setupMultiplePlayers() {
        // 기존 플레이어 노드들 제거 (재설정 시)
        for player in playerNodes {
            engine.detach(player)
        }
        playerNodes.removeAll()
        
        // 여러 개의 플레이어 노드 생성
        for _ in 0..<maxPlayers {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mixer, format: engine.outputNode.inputFormat(forBus: 0))
            playerNodes.append(player)
        }
    }
    
    // 다중 톤 재생 - 소리 중첩 가능
    private func playCollisionTone(frequency: Double, amplitude: Double, duration: Double) {
        // 오디오 엔진의 출력 포맷과 일치하도록 채널 수를 설정
        let sampleRate = 44100.0
        let channelCount: UInt32 = 2  // 스테레오 출력과 일치
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount) else {
            return
        }
        
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return
        }
        
        buffer.frameLength = frameCount
        
        // 모든 채널에 대해 동일한 오디오 데이터 생성
        for channelIdx in 0..<Int(channelCount) {
            // 버퍼 생성
            guard let samples = buffer.floatChannelData?[channelIdx] else { continue }
            
            // 사인파 생성
            for frame in 0..<Int(frameCount) {
                let value = amplitude * sin(2.0 * .pi * frequency * Double(frame) / sampleRate)
                // 타임 엔벨로프 적용 (시작 부분은 크게, 끝부분은 작게)
                let envelope = 1.0 - Double(frame) / Double(frameCount)
                samples[frame] = Float(value * envelope)
            }
        }
        
        // 사용 가능한 플레이어 노드 찾기
        let availablePlayer = playerNodes.first { !$0.isPlaying } ?? playerNodes.randomElement()
        
        guard let player = availablePlayer else { return }
        
        // 버퍼 재생 (중단 없이)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }
    
    // 소리 유형 변경
    func setSoundType(_ type: SoundType) {
        soundType = type
    }
    
    // 볼륨 조절
    func setVolume(_ newVolume: Float) {
        volume = max(0.1, min(1.0, newVolume))
        mixer.volume = volume
    }
    
    // 소리 시작
    func startSound() {
        guard !isPlaying else { return }
        
        do {
            try engine.start()
            isPlaying = true
        } catch {
            print("오디오 엔진 시작 실패: \(error)")
        }
    }
    
    // 소리 중지
    func stopSound() {
        guard isPlaying else { return }
        
        engine.stop()
        isPlaying = false
    }
}

// MARK: - 기울기 감지 관리자
class TiltManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var tiltX: Double = 0.0
    @Published var tiltY: Double = 0.0
    @Published var tiltMagnitude: Double = 0.0
    
    @Published var isMonitoring: Bool = false
    
    var sensitivity: Double = 1.0 {
        didSet {
            sensitivity = max(0.1, min(2.0, sensitivity))
        }
    }
    
    private let maxTiltAngle: Double = 45.0
    
    init() {
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else {
            print("기기 모션 감지 기능을 사용할 수 없습니다.")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.05
    }
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable, !isMonitoring else { return }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion, error == nil else { return }
            
            let rollAngle = motion.attitude.roll * 180.0 / .pi
            let pitchAngle = motion.attitude.pitch * 180.0 / .pi
            
            let normalizedRoll = (rollAngle / self.maxTiltAngle) * self.sensitivity
            let normalizedPitch = (pitchAngle / self.maxTiltAngle) * self.sensitivity
            
            self.tiltX = max(-1.0, min(1.0, normalizedRoll))
            self.tiltY = max(-1.0, min(1.0, normalizedPitch))
            
            self.tiltMagnitude = min(1.0, sqrt(pow(self.tiltX, 2) + pow(self.tiltY, 2)))
        }
        
        isMonitoring = true
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        motionManager.stopDeviceMotionUpdates()
        isMonitoring = false
        
        tiltX = 0.0
        tiltY = 0.0
        tiltMagnitude = 0.0
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - 액체 효과 관리자
class LiquidEffectManager: ObservableObject {
    @Published var drops: [LiquidDrop] = []
    @Published var isAnimating: Bool = false
    
    private var screenBounds: CGRect = UIScreen.main.bounds
    private let friction: CGFloat = 0.97
    private var timer: Timer?
    private var gravity: CGVector = .zero
    
    weak var soundDelegate: SoundDelegate?
    
    private let collisionCooldown: Double = 0.1
    private var currentTime: Double = 0
    
    private let dropColors: [Color] = [
        Color(red: 0.0, green: 0.4, blue: 0.8, opacity: 0.7),
        Color(red: 0.0, green: 0.5, blue: 0.9, opacity: 0.7),
        Color(red: 0.0, green: 0.6, blue: 0.7, opacity: 0.7),
        Color(red: 0.0, green: 0.7, blue: 0.8, opacity: 0.7),
        Color(red: 0.1, green: 0.5, blue: 0.6, opacity: 0.7)
    ]
    
    init() {
        createInitialDrops()
    }
    
    private func createInitialDrops() {
        for _ in 0..<30 {
            createDrop()
        }
    }
    
    private func createDrop() {
        drops.append(LiquidDrop(
            position: CGPoint(
                x: CGFloat.random(in: 50...screenBounds.width-50),
                y: CGFloat.random(in: 50...screenBounds.height-50)
            ),
            size: CGFloat.random(in: 20...60),
            color: dropColors.randomElement() ?? dropColors[0],
            opacity: Double.random(in: 0.5...0.9)
        ))
    }
    
    func updateGravity(tiltX: Double, tiltY: Double) {
        gravity = CGVector(dx: tiltX * 3, dy: -tiltY * 3)
        
        if !isAnimating {
            startAnimation()
        }
    }
    
    func startAnimation() {
        guard !isAnimating else { return }
        
        isAnimating = true
        currentTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime += 0.016
            self.updateDropPositions()
        }
    }
    
    func stopAnimation() {
        isAnimating = false
        timer?.invalidate()
        timer = nil
    }
    
    private func updateDropPositions() {
        for i in 0..<drops.count {
            var drop = drops[i]
            
            drop.velocity.x += gravity.dx * 0.2
            drop.velocity.y += gravity.dy * 0.2
            
            drop.velocity.x *= friction
            drop.velocity.y *= friction
            
            drop.position.x += drop.velocity.x
            drop.position.y += drop.velocity.y
            
            var edgeCollision = false
            
            if drop.position.x - drop.size/2 < 0 {
                drop.position.x = drop.size/2
                drop.velocity.x *= -0.7
                edgeCollision = true
            } else if drop.position.x + drop.size/2 > screenBounds.width {
                drop.position.x = screenBounds.width - drop.size/2
                drop.velocity.x *= -0.7
                edgeCollision = true
            }
            
            if drop.position.y - drop.size/2 < 0 {
                drop.position.y = drop.size/2
                drop.velocity.y *= -0.7
                edgeCollision = true
            } else if drop.position.y + drop.size/2 > screenBounds.height {
                drop.position.y = screenBounds.height - drop.size/2
                drop.velocity.y *= -0.7
                edgeCollision = true
            }
            
            if edgeCollision && currentTime - drop.lastCollisionTime > collisionCooldown {
                let velocityMagnitude = sqrt(pow(drop.velocity.x, 2) + pow(drop.velocity.y, 2))
                let normalizedVelocity = min(1.0, velocityMagnitude / 20.0)
                
                if normalizedVelocity > 0.15 {
                    soundDelegate?.playCollisionSound(intensity: Float(normalizedVelocity))
                    drop.lastCollisionTime = currentTime
                }
            }
            
            drops[i] = drop
        }
        
        detectDropCollisions()
        
        if Int.random(in: 0...100) == 0 && drops.count < 40 {
            createDrop()
        }
    }
    
    private func detectDropCollisions() {
        for i in 0..<drops.count {
            for j in (i+1)..<drops.count {
                let drop1 = drops[i]
                let drop2 = drops[j]
                
                let dx = drop2.position.x - drop1.position.x
                let dy = drop2.position.y - drop1.position.y
                let distance = sqrt(dx * dx + dy * dy)
                let minDistance = (drop1.size + drop2.size) / 2
                
                if distance < minDistance {
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
                    
                    if currentTime - drop1.lastCollisionTime > collisionCooldown &&
                       currentTime - drop2.lastCollisionTime > collisionCooldown {
                        
                        let relativeVelocityX = drop1.velocity.x - drop2.velocity.x
                        let relativeVelocityY = drop1.velocity.y - drop2.velocity.y
                        let velocityMagnitude = sqrt(pow(relativeVelocityX, 2) + pow(relativeVelocityY, 2))
                        let normalizedVelocity = min(1.0, velocityMagnitude / 15.0)
                        
                        if normalizedVelocity > 0.15 {
                            soundDelegate?.playCollisionSound(intensity: Float(normalizedVelocity))
                            
                            updatedDrop1.lastCollisionTime = currentTime
                            updatedDrop2.lastCollisionTime = currentTime
                        }
                    }
                    
                    drops[i] = updatedDrop1
                    drops[j] = updatedDrop2
                }
            }
        }
    }
    
    func setScreenBounds(_ bounds: CGRect) {
        screenBounds = bounds
    }
    
    deinit {
        stopAnimation()
    }
}

// 소리 재생을 위한 프로토콜
protocol SoundDelegate: AnyObject {
    func playCollisionSound(intensity: Float)
}

// MARK: - 소리 델리게이트 구현
extension SimpleSoundGenerator: SoundDelegate {
    func playCollisionSound(intensity: Float) {
        triggerCollisionSound(intensity: max(0.2, min(1.0, intensity)))
    }
}

// MARK: - 메인 뷰
struct NatureSoundEffectView: View {
    @StateObject private var tiltManager = TiltManager()
    @StateObject private var soundEngine = SimpleSoundGenerator()
    @StateObject private var liquidManager = LiquidEffectManager()
    
    @State private var isPlaying = false
    @State private var showSettings = false
    @State private var selectedSoundType: SoundType = .crystal
    @State private var sensitivity: Double = 0.5  // 고정된 감도: 50%
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: selectedSoundType.backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ForEach(liquidManager.drops) { drop in
                    Circle()
                        .fill(drop.color)
                        .frame(width: drop.size, height: drop.size)
                        .position(drop.position)
                        .opacity(drop.opacity)
                        .blur(radius: 3)
                        .shadow(color: .white.opacity(0.2), radius: 5, x: 1, y: 1)
                }
                
                VStack {
                    Text("감미로운 자연 소리")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                    
                    TiltVisualizerView(tiltX: tiltManager.tiltX, tiltY: tiltManager.tiltY)
                        .frame(width: 200, height: 200)
                        .padding()
                    
                    Text("소리: \(selectedSoundType.rawValue)")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    if showSettings {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("소리 유형 선택:")
                                .foregroundColor(.white)
                                .padding(.vertical, 5)
                            
                            Picker("소리 유형", selection: $selectedSoundType) {
                                ForEach(SoundType.allCases) { soundType in
                                    Text(soundType.rawValue).tag(soundType)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedSoundType) { newValue in
                                soundEngine.setSoundType(newValue)
                            }
                            .padding(.bottom)
                            
                            Text("감도: 50% (고정)")
                                .foregroundColor(.white)
                                .padding(.vertical, 5)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(15)
                        .padding()
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 30) {
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            isPlaying.toggle()
                            if isPlaying {
                                tiltManager.startMonitoring()
                                tiltManager.sensitivity = sensitivity // 감도 설정
                                soundEngine.startSound()
                                liquidManager.startAnimation()
                            } else {
                                tiltManager.stopMonitoring()
                                soundEngine.stopSound()
                                liquidManager.stopAnimation()
                            }
                        }) {
                            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(isPlaying ? Color.red : Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        
                        Button(action: {
                            // 정보 표시
                        }) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .onAppear {
                liquidManager.setScreenBounds(geometry.frame(in: .global))
                liquidManager.soundDelegate = soundEngine
                soundEngine.setSoundType(selectedSoundType)
                tiltManager.sensitivity = sensitivity // 시작시 감도 설정
            }
            .onChange(of: tiltManager.tiltX) { _ in
                updateEffects()
            }
            .onChange(of: tiltManager.tiltY) { _ in
                updateEffects()
            }
        }
    }
    
    private func updateEffects() {
        // 볼륨을 기본보다 낮게 시작 (0.4 대신 0.2)
        let newVolume = 0.2 + Float(tiltManager.tiltY + 1.0) / 2.0 * 0.5
        soundEngine.setVolume(newVolume)
        
        liquidManager.updateGravity(
            tiltX: tiltManager.tiltX,
            tiltY: tiltManager.tiltY
        )
    }
}

// 기울기 시각화 뷰
struct TiltVisualizerView: View {
    let tiltX: Double
    let tiltY: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Circle().fill(Color.black.opacity(0.2)))
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: 100))
                path.addLine(to: CGPoint(x: 200, y: 100))
                path.move(to: CGPoint(x: 100, y: 0))
                path.addLine(to: CGPoint(x: 100, y: 200))
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
                .position(
                    x: 100 + CGFloat(tiltX) * 80,
                    y: 100 + CGFloat(tiltY) * 80
                )
                .shadow(color: .white.opacity(0.5), radius: 5)
            
            Path { path in
                path.move(to: CGPoint(x: 100, y: 100))
                path.addLine(to: CGPoint(
                    x: 100 + CGFloat(tiltX) * 80,
                    y: 100 + CGFloat(tiltY) * 80
                ))
            }
            .stroke(Color.blue.opacity(0.5), lineWidth: 1)
        }
        .frame(width: 200, height: 200)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
        )
    }
}
