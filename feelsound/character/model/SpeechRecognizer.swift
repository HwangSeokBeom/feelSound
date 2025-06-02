//
//  SpeechRecognizer.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/27/25.
//

import Foundation
import AVFoundation
import Speech

class SpeechRecognizer: NSObject, ObservableObject {
    private let engine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let emotionAnalyzer = EmotionAnalyzer()

    weak var foxScene: ArcticFoxScene?

    @Published var recognizedText = ""
    @Published var isListening = false

    private var lastVoiceDetectedTime: TimeInterval = CACurrentMediaTime()
    private let silenceTimeout: TimeInterval = 5.0
    private var silenceCheckTimer: Timer?

    // MARK: - 권한 요청 + 녹음 시작
    func requestPermissionAndStart() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    print("✅ 음성 인식 권한 허용됨")
                    self.requestMicPermissionAndStart()
                } else {
                    print("❌ 음성 인식 권한 거부됨")
                }
            }
        }
    }

    private func requestMicPermissionAndStart() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("🎤 마이크 권한 허용됨")
                    self.startRecording()
                } else {
                    print("🚫 마이크 권한 거부됨")
                }
            }
        }
    }

    // MARK: - 녹음 시작
    func startRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("❌ SFSpeechRecognizer 사용 불가 또는 인식기 없음")
            return
        }

        if engine.isRunning {
            print("⚠️ AVAudioEngine 이미 실행 중")
            return
        }

        stopRecording()
        recognizedText = ""

        // 세션 설정
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ AVAudioSession 설정 완료")
        } catch {
            print("❌ 세션 설정 실패: \(error.localizedDescription)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        // 엔진 시작
        do {
            engine.prepare()
            try engine.start()
            print("🎤 AVAudioEngine 시작됨")
            startSilenceMonitor()
        } catch {
            print("❌ AVAudioEngine 시작 실패: \(error.localizedDescription)")
            stopRecording()
            return
        }

        // 음성 인식 시작
        DispatchQueue.main.async {
            self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.recognizedText = text
                        self.lastVoiceDetectedTime = CACurrentMediaTime()

                        if !self.isListening {
                            self.isListening = true
                            self.foxScene?.isEmotionListening = true
                            self.foxScene?.updateFoxForListeningState()
                        }
                    }

                    let emotion = self.analyzeEmotion(from: text)
                    if emotion != "neutral", let fox = self.foxScene {
                        fox.performAction(for: emotion)
                    }
                }

                if let error = error {
                    print("❌ 인식 중 오류 발생: \(error.localizedDescription)")
                    self.stopRecording()
                }
            }
        }
    }

    // MARK: - 무음 모니터링
    private func startSilenceMonitor() {
        silenceCheckTimer?.invalidate()
        silenceCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let now = CACurrentMediaTime()
            if self.isListening && (now - self.lastVoiceDetectedTime > self.silenceTimeout) {
                print("🔇 무음 지속 감지 → 듣기 종료")
                self.isListening = false
                DispatchQueue.main.async {
                    self.foxScene?.isEmotionListening = false
                    self.foxScene?.updateFoxForListeningState()
                    self.recognizedText = ""
                }
            }
        }
    }

    private func stopSilenceMonitor() {
        silenceCheckTimer?.invalidate()
        silenceCheckTimer = nil
    }

    // MARK: - 녹음 중지
    func stopRecording() {
        isListening = false

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        stopSilenceMonitor()

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ 세션 비활성화 실패: \(error.localizedDescription)")
        }

        print("🛑 녹음 중지됨")
    }

    // MARK: - 키워드 기반 감정 분석
    func analyzeEmotion(from text: String) -> String {
        let lowered = text.lowercased()

        let emotionKeywords: [(keyword: String, emotion: String)] = [
            ("기뻐", "happy"), ("좋아", "happy"), ("행복", "happy"),
            ("슬퍼", "sad"), ("우울", "sad"), ("눈물", "sad"),
            ("화나", "angry"), ("짜증", "angry"), ("분노", "angry"),
            ("놀라", "surprised"), ("헉", "surprised"), ("어머", "surprised")
        ]

        var latestEmotion: String? = nil
        var latestRangeLocation = -1

        for (keyword, emotion) in emotionKeywords {
            if let range = lowered.range(of: keyword, options: .backwards) {
                let location = lowered.distance(from: lowered.startIndex, to: range.lowerBound)
                if location > latestRangeLocation {
                    latestRangeLocation = location
                    latestEmotion = emotion
                }
            }
        }

        return latestEmotion ?? "neutral"
    }
}
