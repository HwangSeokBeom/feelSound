//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/14/25.
//

import AVFAudio

enum SlimeSoundType {
    case tap
    case press
    case drag
}

enum SlimeSoundProfile {
    case fudge
    case glitter
    case bubble
    case moss
    case metallic
}

class SlimeSoundPlayer {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    private var sampleRate: Float = 44100

    private var isPlaying = false
    private var time: Float = 0
    private var duration: Float = 0.3

    private var baseFrequency: Float = 150
    private var amplitude: Float = 0.8
    private let profile: SlimeSoundProfile

    init(profile: SlimeSoundProfile = .fudge) {
        self.profile = profile
        setupEngine()
    }

    private func setupEngine() {
        sampleRate = Float(engine.outputNode.outputFormat(forBus: 0).sampleRate)

        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                guard self.isPlaying else {
                    for buffer in ablPointer {
                        let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                        ptr[frame] = 0
                    }
                    continue
                }

                let env = self.envelope(at: self.time, duration: self.duration)
                let value: Float

                switch self.profile {
                case .metallic:
                    let phase = self.baseFrequency * self.time
                    value = (2 * (phase - floor(phase + 0.5))) * self.amplitude * env // sawtooth

                case .bubble:
                    let noise = Float.random(in: -1...1)
                    value = noise * sin(2 * .pi * self.baseFrequency * self.time) * self.amplitude * env

                case .glitter:
                    let tremolo = sin(2 * .pi * 8 * self.time) * 0.5 + 0.5
                    value = sin(2 * .pi * self.baseFrequency * self.time) * self.amplitude * env * tremolo

                case .moss:
                    value = sin(2 * .pi * self.baseFrequency * self.time) * self.amplitude * env * exp(-1.5 * self.time)

                case .fudge:
                    value = sin(2 * .pi * self.baseFrequency * self.time) * self.amplitude * env
                }

                self.time += 1.0 / self.sampleRate

                for buffer in ablPointer {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = value
                }

                // 자동 종료
                if self.time >= self.duration {
                    self.isPlaying = false
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    /// 공통 ADSR Envelope (Attack: 0.05s, Sustain: 60%, Release: 나머지)
    private func envelope(at t: Float, duration: Float) -> Float {
        let attack: Float = 0.05
        let releaseStart = duration * 0.6
        let releaseDuration = duration - releaseStart

        if t < attack {
            return t / attack
        } else if t < releaseStart {
            return 1.0
        } else if t < duration {
            return max(0, 1 - (t - releaseStart) / releaseDuration)
        }
        return 0
    }

    func play(type: SlimeSoundType, velocity: Float = 0.5, duration: Float = 0.3) {
        guard !isPlaying else { return }
        isPlaying = true
        time = 0
        self.duration = duration

        updateParameters(type: type, velocity: velocity)
    }

    private func updateParameters(type: SlimeSoundType, velocity: Float) {
        switch profile {
        case .fudge:
            baseFrequency = 90 + velocity * 20
            amplitude = 0.4
        case .glitter:
            baseFrequency = 550 + velocity * 100
            amplitude = 0.35
        case .bubble:
            baseFrequency = 180 + velocity * 80
            amplitude = 0.5
        case .moss:
            baseFrequency = 50 + velocity * 30
            amplitude = 0.3
        case .metallic:
            baseFrequency = 700 + velocity * 300
            amplitude = 0.6
        }

        switch type {
        case .tap: amplitude *= 0.8
        case .press: amplitude *= 0.6
        case .drag: amplitude *= 1.0
        }
    }
}
