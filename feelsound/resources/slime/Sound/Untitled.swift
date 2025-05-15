////
////  Untitled.swift
////  feelsound
////
////  Created by Hwangseokbeom on 5/14/25.
////
//
//import AVFoundation
//
//enum SlimeSoundType {
//    case tap
//    case press
//    case drag
//}
//
//class SlimeSoundPlayer {
//    private let engine = AVAudioEngine()
//    private var sourceNode: AVAudioSourceNode!
//    private var sampleRate: Float = 44100
//    private var time: Float = 0
//    private var isPlaying = false
//
//    private var baseFrequency: Float = 150
//    private var amplitude: Float = 0.8
//    private var profile: SlimeSoundProfile
//
//    init(profile: SlimeSoundProfile = .soft) {
//        self.profile = profile
//        setupEngine()
//    }
//
//    private func setupEngine() {
//        sampleRate = Float(engine.outputNode.outputFormat(forBus: 0).sampleRate)
//
//        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
//            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
//            for frame in 0..<Int(frameCount) {
//                self.time += 1.0 / self.sampleRate
//                let value = sin(2.0 * .pi * self.baseFrequency * self.time) * self.amplitude
//                for buffer in ablPointer {
//                    let buf = buffer.mData!.assumingMemoryBound(to: Float.self)
//                    buf[frame] = value
//                }
//            }
//            return noErr
//        }
//
//        engine.attach(sourceNode)
//        let format = engine.outputNode.outputFormat(forBus: 0)
//        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
//
//        try? engine.start()
//    }
//
//    func play(type: SlimeSoundType, velocity: Float = 0.5, duration: Float = 0.3) {
//        updateParameters(type: type, velocity: velocity, duration: duration)
//
//        if !isPlaying {
//            isPlaying = true
//            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
//                self.isPlaying = false
//            }
//        }
//    }
//
//    private func updateParameters(type: SlimeSoundType, velocity: Float, duration: Float) {
//        switch profile {
//        case .soft:
//            baseFrequency = 80 + velocity * 40
//            amplitude = 0.5
//        case .shimmer:
//            baseFrequency = 600 + velocity * 200
//            amplitude = 0.4
//        case .bubble:
//            baseFrequency = 100 + velocity * 100
//            amplitude = 0.6
//        case .muffled:
//            baseFrequency = 60 + velocity * 30
//            amplitude = 0.3
//        case .metallic:
//            baseFrequency = 800 + velocity * 400
//            amplitude = 0.7
//        }
//
//        if type == .tap {
//            amplitude *= 0.8
//        } else if type == .press {
//            amplitude *= 0.6
//        } else if type == .drag {
//            amplitude *= 1.0
//        }
//    }
//}
