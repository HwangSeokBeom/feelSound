////
////  Untitled.swift
////  feelsound
////
////  Created by Hwangseokbeom on 5/23/25.
////
//
//import AVFoundation
//import CoreML
//import AudioKitEX
//
//class AudioEmotionAnalyzer {
//    private let engine = AVAudioEngine()
//    private let inputBus: AVAudioNodeBus = 0
//    private let sampleRate: Double = 16000
//    private let bufferSize: AVAudioFrameCount = 1024  // 약 64ms 분량
//    private var lastEmotionTime: TimeInterval = 0
//    private let emotionCooldown: TimeInterval = 5.0
//
//    weak var delegate: ArcticFoxScene?  // 💡 SpriteKit Scene과 연동
//
//    func start() {
//        do {
//            let session = AVAudioSession.sharedInstance()
//
//            // 🎤 마이크 사용 설정 (playAndRecord로 해야 마이크 허용됨)
//            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
//
//            // 시스템이 호환 가능한 샘플레이트 설정
//            try session.setPreferredSampleRate(44100)
//            try session.setActive(true)
//
//            let inputNode = engine.inputNode
//            let format = inputNode.outputFormat(forBus: inputBus) // 💡 시스템이 반환하는 기본 포맷 사용
//
//            // 🔁 포맷을 강제로 지정하지 마세요! format: nil 이 더 안전
//            inputNode.installTap(onBus: inputBus, bufferSize: bufferSize, format: nil) { buffer, time in
//                self.processAudioBuffer(buffer, format: format)
//            }
//
//            try engine.start()
//            print("🎤 마이크 입력 시작됨")
//
//        } catch {
//            print("❌ AVAudioEngine 시작 실패: \(error.localizedDescription)")
//        }
//    }
//
//    func stop() {
//        engine.inputNode.removeTap(onBus: inputBus)
//        engine.stop()
//    }
//
//    func processAudioBuffer(_ buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
//        let now = CACurrentMediaTime()
//        guard now - lastEmotionTime > emotionCooldown else { return }  // 쿨타임 체크
//
//        guard let channelData = buffer.floatChannelData?[0] else { return }
//        let frameLength = Int(buffer.frameLength)
//        let audioData = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
//
//        let mfccVector = extractMFCC(from: audioData, sampleRate: format.sampleRate)
//
//        if let emotion = predictEmotion(from: mfccVector) {
//            lastEmotionTime = now  // 쿨타임 갱신
//            print("🔮 감정 추론 결과: \(emotion)")
//            DispatchQueue.main.async {
//                self.delegate?.performAction(for: emotion)
//            }
//        }
//    }
//
//    func predictEmotion(from mfcc: [Float]) -> String? {
//        guard mfcc.count == 26 else { return nil }
//
//        guard let mlModel = try? EmotionVectorClassifier(configuration: .init()),
//              let inputArray = try? MLMultiArray(shape: [1, 26], dataType: .float32) else {
//            return nil
//        }
//
//        for (i, value) in mfcc.enumerated() {
//            inputArray[i] = NSNumber(value: value)
//        }
//
//        guard let result = try? mlModel.prediction(input_1: inputArray) else {
//            return nil
//        }
//
//        return result.classLabel
//    }
//
//    func extractMFCC(from audio: [Float], sampleRate: Double) -> [Float] {
//        let frameCount = 512
//        let hopCount = 256
//
//        guard let mfccExtractor = MFCC(
//            numberOfCoefficients: 26,
//            windowSize: frameCount,
//            hopSize: hopCount,
//            sampleRate: Double(Float(sampleRate))
//        ) else {
//            print("❌ MFCC 생성 실패")
//            return []
//        }
//
//        let result = mfccExtractor.process(audio)
//
//        let averaged = result.reduce(into: Array(repeating: 0.0 as Float, count: 26)) { sum, vec in
//            for i in 0..<26 {
//                sum[i] += vec[i]
//            }
//        }.map { $0 / Float(result.count) }
//
//        return averaged
//    }
//    
//    func isVoiceDetected(audioData: [Float]) -> Bool {
//        // RMS 에너지 기반 필터링 (에너지가 낮으면 무성으로 판단)
//        let energy = audioData.reduce(0) { $0 + $1 * $1 } / Float(audioData.count)
//        return energy > 0.005  // ✅ 실험적으로 튜닝 필요
//    }
//    
//    func isVoiceDetected(audioData: [Float], sampleRate: Double) -> Bool {
//        let energy = audioData.reduce(0) { $0 + $1 * $1 } / Float(audioData.count)
//
//        // Zero-Crossing Rate 계산
//        var zeroCrossings = 0
//        for i in 1..<audioData.count {
//            if (audioData[i - 1] >= 0 && audioData[i] < 0) ||
//               (audioData[i - 1] < 0 && audioData[i] >= 0) {
//                zeroCrossings += 1
//            }
//        }
//        let zcr = Double(zeroCrossings) / Double(audioData.count)
//
//        // 💡 기준값은 환경에 따라 조정 가능
//        let isEnergyValid = energy > 0.001   // 실험적으로 튜닝 필요
//        let isZCRValid = zcr > 0.01 && zcr < 0.2 // 말소리에 적절한 범위
//
//        return isEnergyValid && isZCRValid
//    }
//}
