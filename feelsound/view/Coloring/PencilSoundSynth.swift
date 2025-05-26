//
//  PencilSoundSynth.swift
//  feelsound
//
//  Created by 안준경 on 5/26/25.
//

import AVFoundation

// MARK: - PencilSoundSynth: 노이즈 생성 및 볼륨 제어
class PencilSoundSynth: ObservableObject {
    private let engine = AVAudioEngine()
    private let noiseNode: AVAudioSourceNode
    private let mixer = AVAudioMixerNode()
    private let eq = AVAudioUnitEQ(numberOfBands: 1)
    
    @Published var masterVolume: Float = 0.5
    @Published var filterFrequency: Float = 3000.0
    @Published var filterGain: Float = 15.0

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        // 노이즈 생성
        noiseNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let noise = Float.random(in: -0.15...0.15)
                for buffer in ablPointer {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = noise
                }
            }
            return noErr
        }

        // EQ 설정: 고역 강조
        eq.bands[0].filterType = .lowPass
        eq.bands[0].frequency = 4000.0
        eq.bands[0].bandwidth = 0.05
        eq.bands[0].gain = 3.0
        eq.bands[0].bypass = false

        engine.attach(noiseNode)
        engine.attach(eq)
        engine.attach(mixer)

        engine.connect(noiseNode, to: eq, format: format)
        engine.connect(eq, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)

        // 초기 볼륨을 0으로 설정하여 소음 방지
        mixer.outputVolume = 0
        
        // 엔진 시작 시 오류 처리 및 지연
        do {
            try engine.start()
            // 엔진이 완전히 초기화될 때까지 잠시 대기
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 엔진 초기화 완료 후에도 볼륨 0 유지
                self.mixer.outputVolume = 0
            }
        } catch {
            print("Audio engine start failed: \(error)")
        }
    }

    func setVolume(_ value: Float) {
        // 부드러운 볼륨 변화를 위한 추가 체크
        let targetVolume = value * masterVolume
        
        // 볼륨이 너무 급격히 변하지 않도록 제한
        if abs(mixer.outputVolume - targetVolume) > 0.3 {
            // 큰 볼륨 변화는 점진적으로 적용
            DispatchQueue.main.async {
                self.mixer.outputVolume = targetVolume * 0.5
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.mixer.outputVolume = targetVolume
                }
            }
        } else {
            mixer.outputVolume = targetVolume
        }
    }

    func stop() {
        // 부드러운 페이드아웃
        let currentVolume = mixer.outputVolume
        if currentVolume > 0 {
            mixer.outputVolume = currentVolume * 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.mixer.outputVolume = 0
            }
        } else {
            mixer.outputVolume = 0
        }
    }
    
    func updateFilterFrequency(_ value: Float) {
        eq.bands[0].frequency = value
        filterFrequency = value
    }
    
    func updateFilterGain(_ value: Float) {
        eq.bands[0].gain = value
        filterGain = value
    }
    
    // 엔진 정리 (뷰가 사라질 때 호출)
    func cleanup() {
        mixer.outputVolume = 0
        engine.stop()
    }
}
