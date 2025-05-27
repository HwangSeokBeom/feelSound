//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/27/25.
//

import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    func configureSessionForRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ AVAudioSession (recording) 활성화됨")
        } catch {
            print("❌ AVAudioSession 설정 실패: \(error.localizedDescription)")
        }
    }

    func configureSessionForPlayback() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            print("✅ AVAudioSession (playback) 활성화됨")
        } catch {
            print("❌ AVAudioSession 설정 실패: \(error.localizedDescription)")
        }
    }
}
