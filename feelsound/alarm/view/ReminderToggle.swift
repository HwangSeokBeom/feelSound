//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/22/25.
//

import SwiftUI

struct ReminderToggle: View {
    @Binding var isOn: Bool

    private let toggleWidth: CGFloat = 68
    private let toggleHeight: CGFloat = 36
    private let knobSize: CGFloat = 24
    private let knobPadding: CGFloat = 4

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: toggleHeight / 2)
                    .fill(
                        isOn
                        ? AnyShapeStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.6)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .frame(width: toggleWidth, height: toggleHeight)

                HStack(spacing: 0) {
                    if isOn {
                        Text("ON")
                            .frame(width: toggleWidth - knobSize - knobPadding * 2, height: toggleHeight)
                            .foregroundColor(.white)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer().frame(width: knobSize + knobPadding * 2)
                    } else {
                        Spacer().frame(width: knobSize + knobPadding * 2)
                        Text("OFF")
                            .frame(width: toggleWidth - knobSize - knobPadding * 2, height: toggleHeight)
                            .foregroundColor(.white)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }

                HStack {
                    if isOn { Spacer() }
                    Circle()
                        .fill(Color.white)
                        .frame(width: knobSize, height: knobSize)
                        .padding(knobPadding)
                    if !isOn { Spacer() }
                }
                .frame(width: toggleWidth, height: toggleHeight)
            }
        }
        .buttonStyle(.plain)
    }
}
