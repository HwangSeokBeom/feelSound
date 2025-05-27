//
//  ContentView.swift
//  MovingCharacter
//
//  Created by Hwangseokbeom on 5/7/25.
//

import SwiftUI
import SpriteKit

struct CharacterView: View {
    @EnvironmentObject var router: Router
    @State private var isSheetVisible = true
    @State private var isSoundOn = true
    @StateObject private var recognizer = SpeechRecognizer()
    let scene = ArcticFoxScene()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SpriteView(scene: scene)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        scene.size = geometry.size
                        scene.scaleMode = .resizeFill
                        scene.isPaused = false

                        // 🔗 연결 (필요 시 foxScene 프로퍼티 선언)
                        // scene.foxScene = scene ← 선언되어 있지 않으면 주석처리 또는 제거
                        recognizer.foxScene = scene
                        recognizer.requestPermission()
                    }

                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Good night, user")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Hope you get a good night's rest.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            isSoundOn.toggle()
                        }) {
                            Image(systemName: isSoundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 12)
                    .padding(.horizontal, 20)

                    Spacer()
                }

                VStack {
                    Spacer()

                    VStack(spacing: 24) {
                        Capsule()
                            .frame(width: 36, height: 4)
                            .foregroundColor(.gray.opacity(0.6))
                            .onTapGesture {
                                withAnimation { isSheetVisible.toggle() }
                            }

                        HStack(spacing: 20) {
                            Button(action: {}) {
                                Text("Focus")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#2E2E3E"))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }

                            Button(action: {}) {
                                Text("Reset")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#2E2E3E"))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }

                        Button(action: {
                            recognizer.toggleRecording()
                            scene.isEmotionListening = recognizer.isListening  // 녹음 상태 전달
                            scene.updateFoxForListeningState()                 // 여우 상태 즉시 반영

                            if !recognizer.isListening {
                                recognizer.recognizedText = ""                // 🔸 녹음 중지 시 텍스트 초기화
                            }
                        }) {
                            Text(recognizer.isListening ? "Stop Listening" : "Sound")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#2E2E3E"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        if !recognizer.recognizedText.isEmpty {
                            Text("\u{1F50A} \(recognizer.recognizedText)") // 이모지 수정됨
                                .foregroundColor(.yellow)
                                .font(.caption)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .padding(.bottom, 80)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#1C1B2E"))
                    .cornerRadius(20)
                    .offset(y: isSheetVisible ? 0 : 160)
                    .animation(.easeInOut, value: isSheetVisible)
                }
            }
            .edgesIgnoringSafeArea(.top)
            .navigationBarHidden(true)
            .onDisappear {
                scene.removeAllChildren()
                scene.removeAllActions()
                scene.isPaused = true
            }
        }
    }
}
