//
//  CharacterView.swift
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
                // SpriteKit 장면
                SpriteView(scene: scene)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        scene.size = geometry.size
                        scene.scaleMode = .resizeFill
                        scene.isPaused = false

                        recognizer.foxScene = scene
                        recognizer.requestPermissionAndStart()  // ✅ 권한 요청 + 인식 시작
                    }

                // 상단 인삿말 + 사운드 버튼
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

                // 하단 반모달 제어 영역
                VStack {
                    Spacer()

                    VStack(spacing: 24) {
                        // 위로 당기기 캡슐
                        Capsule()
                            .frame(width: 36, height: 4)
                            .foregroundColor(.gray.opacity(0.6))
                            .onTapGesture {
                                withAnimation { isSheetVisible.toggle() }
                            }

                        // 기능 버튼
                        HStack(spacing: 20) {
                            Button(action: {
                                // TODO: Focus 기능 구현
                            }) {
                                Text("Focus")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#2E2E3E"))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }

                            Button(action: {
                                // TODO: Reset 기능 구현
                            }) {
                                Text("Reset")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#2E2E3E"))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }

                        // 음성 인식 상태 표시
                        Text(recognizer.isListening ? "Listening..." : "Silent")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#2E2E3E"))
                            .foregroundColor(recognizer.isListening ? .green : .gray)
                            .cornerRadius(12)

                        // 인식된 텍스트 표시
                        if !recognizer.recognizedText.isEmpty {
                            Text("🔊 \(recognizer.recognizedText)")
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
                // 정리
                scene.removeAllChildren()
                scene.removeAllActions()
                scene.isPaused = true
                recognizer.stopRecording()
            }
        }
    }
}
