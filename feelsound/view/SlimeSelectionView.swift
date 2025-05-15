//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/15/25.
//

//
//  SlimeSelectionView.swift
//  feelsound
//

import SwiftUI

struct SlimeSelectionView: View {
    @State private var selectedSlime: SlimeType = .fudge
    @State private var renderer: SlimeRenderer = SlimeRenderer(type: .fudge)

    var body: some View {
        ZStack {
            SlimeView(renderer: renderer)
                .id(renderer) // 💡 renderer가 바뀌면 뷰도 새로 생성되게

            VStack {
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(SlimeType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedSlime = type
                                renderer = SlimeRenderer(type: type) // 새 렌더러 할당
                            }) {
                                Image(type.previewImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }
                    }
                    .padding()
                }
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
    }
}
