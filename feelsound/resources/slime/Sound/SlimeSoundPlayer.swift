//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/14/25.
//

import AVFoundation

enum SlimeSoundType {
    case tap       // 톡 누름
    case press     // 꾹 누름
    case drag      // 드래그
}

class SlimeSoundPlayer {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    private var sampleRate: Float = 44100
    private var isPlaying = false
    private var time: Float = 0

    private var dynamicFrequency: Bool = false
    private var baseFrequency: Float = 100.0
    private var frequencyRate: Float = 0.0
    private var amplitude: Float = 1.0
    private var useLFO: Bool = false

    init() {
        setupEngine()
    }

    private func setupEngine() {
        let mainMixer = engine.mainMixerNode
        sampleRate = Float(engine.outputNode.outputFormat(forBus: 0).sampleRate)

        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let envelope = self.envelope(at: self.time)

                let mod: Float = self.useLFO
                    ? sin(2 * .pi * 6.0 * self.time) * 0.3 + 0.7
                    : 1.0

                let currentFrequency = self.dynamicFrequency
                    ? self.baseFrequency + self.frequencyRate * self.time
                    : self.baseFrequency

                let sample = sin(2 * .pi * currentFrequency * self.time) * self.amplitude * mod * envelope

                self.time += 1 / self.sampleRate

                for buffer in ablPointer {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = sample
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1))
        try? engine.start()
    }

    private func envelope(at t: Float) -> Float {
        if t < 0.02 { return t / 0.02 }
        else if t < 0.08 { return 1.0 - (t - 0.02) / 0.06 }
        else if t < 0.3 { return 0.4 * (1 - (t - 0.08) / 0.22) }
        else { return 0 }
    }

    func play(type: SlimeSoundType, velocity: Float = 0, duration: Float = 0) {
        guard !isPlaying else { return }
        isPlaying = true
        time = 0

        // 통일된 슬라임 사운드 기본값
        baseFrequency = 180.0
        frequencyRate = 0.0
        amplitude = 0.3
        useLFO = true
        dynamicFrequency = false

        switch type {
        case .tap:
            break  // 기본값 그대로 사용

        case .drag:
            break  // 기본값 그대로 사용

        case .press:
            dynamicFrequency = true
            frequencyRate = 80.0  // 시간이 지날수록 주파수 빨라짐 (깊이/넓이 증가 표현)
        }

        engine.mainMixerNode.volume = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.stop() }
    }

    func stop() {
        isPlaying = false
        engine.mainMixerNode.volume = 0.0
    }
}
