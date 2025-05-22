//
//  ReminderView.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/20/25.
//

// ReminderView.swift
// 기능은 그대로 유지하되, MVVM + 분리 구조 적용

import SwiftUI

struct ReminderView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ReminderViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                HStack {
                    Text("알림 설정")
                        .font(.title3)
                        .foregroundColor(.white)

                    Spacer()
                    ReminderToggle(isOn: $viewModel.isEnabled)
                }
                .padding(.horizontal)

                Group {
                    VStack(spacing: 36) {
                        Text("몇 시에 알람을 드릴까요?")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text("매일 연습 시간을 알려드릴게요.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 32)

                    HStack(spacing: 14) {
                        ForEach(Weekday.allCases) { day in
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(viewModel.selectedDays.contains(day) ? 0 : 0.6), lineWidth: 1)

                                    if viewModel.selectedDays.contains(day) {
                                        Circle().stroke(Color.yellow.opacity(0.7), lineWidth: 1.5)
                                        Circle().stroke(Color.yellow.opacity(0.4), lineWidth: 4).blur(radius: 3)
                                    }

                                    Text(day.label)
                                        .font(.body)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 40, height: 40)

                                Rectangle()
                                    .fill(Color.yellow.opacity(viewModel.selectedDays.contains(day) ? 0.4 : 0))
                                    .frame(height: 2)
                                    .frame(width: 16)
                            }
                            .onTapGesture {
                                viewModel.toggleDay(day)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                    DatePicker("", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(height: 250)
                        .scaleEffect(x: 1.2, y: 1.2, anchor: .center)
                        .clipped()
                        .colorMultiply(.white)
                }
                .opacity(viewModel.isEnabled ? 1.0 : 0.3)
                .allowsHitTesting(viewModel.isEnabled)

                Spacer()
            }
            .padding(.top)
            .background(Color(red: 0.03, green: 0.03, blue: 0.10).edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Reminder", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    viewModel.handleDismiss()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            )
        }
        .onAppear {
            viewModel.load()
        }
    }
}
