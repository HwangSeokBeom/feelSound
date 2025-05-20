//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/20/25.
//

import SwiftUI
import UserNotifications

struct ReminderView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isEnabled = true
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 알림 설정 토글
                HStack {
                    Text("알림 설정")
                        .font(.title3)
                        .foregroundColor(.white)

                    Spacer()

                    ReminderToggle(isOn: $isEnabled)
                }
                .padding(.horizontal)

                VStack(spacing: 36) {
                    Text("몇 시에 알람을 드릴까요?")
                        .font(.title2)
                        .foregroundColor(.white)

                    Text("매일 연습 시간을 알려드릴게요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 32)

                // 요일 선택
                HStack(spacing: 14) {
                    ForEach(Weekday.allCases) { day in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(selectedDays.contains(day) ? 0 : 0.6), lineWidth: 1)

                                if selectedDays.contains(day) {
                                    Circle()
                                        .stroke(Color.yellow.opacity(0.7), lineWidth: 1.5)

                                    // Glow 효과
                                    Circle()
                                        .stroke(Color.yellow.opacity(0.4), lineWidth: 4)
                                        .blur(radius: 3)
                                }

                                Text(day.label)
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 40, height: 40)

                            // 밑줄 (더 연하고 더 길게)
                            Rectangle()
                                .fill(Color.yellow.opacity(selectedDays.contains(day) ? 0.4 : 0))
                                .frame(height: 2)
                                .frame(width: 16)
                        }
                        .onTapGesture {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)

                // 시간 선택 - AM/PM 포함 휠
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .frame(height: 250) // 기본 높이보다 크게
                    .scaleEffect(x: 1.2, y: 1.2, anchor: .center) // 확대
                    .clipped() // 확대 영역 잘림 방지
                    .colorMultiply(.white)

                Spacer()
            }
            .padding(.top)
            .background(Color(red: 0.03, green: 0.03, blue: 0.10).edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Reminder", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                },
                trailing: Button("Save") {
                    scheduleNotifications()
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
            )
        }
        .onAppear {
            requestNotificationPermission()
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("권한 요청 에러: \(error)")
            }
            print("알림 권한: \(granted)")
        }
    }

    func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        guard isEnabled else { return }

        for day in selectedDays {
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
            dateComponents.weekday = day.calendarWeekday

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let content = UNMutableNotificationContent()
            content.title = "연습 시간이에요!"
            content.body = "설정하신 시간에 맞춰 알림을 드려요."
            content.sound = .default

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    enum Weekday: String, CaseIterable, Identifiable {
        case mon, tue, wed, thu, fri, sat, sun

        var id: String { self.rawValue }

        var label: String {
            switch self {
            case .mon: return "M"
            case .tue: return "T"
            case .wed: return "W"
            case .thu: return "T"
            case .fri: return "F"
            case .sat: return "S"
            case .sun: return "S"
            }
        }

        var calendarWeekday: Int {
            switch self {
            case .sun: return 1
            case .mon: return 2
            case .tue: return 3
            case .wed: return 4
            case .thu: return 5
            case .fri: return 6
            case .sat: return 7
            }
        }
    }
}

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
                // 배경
                RoundedRectangle(cornerRadius: toggleHeight / 2)
                    .fill(
                        isOn
                        ? AnyShapeStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,               // 파란색
                                    Color.purple.opacity(0.6) // 자연스러운 끝단 보라색
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        : AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .frame(width: toggleWidth, height: toggleHeight)

                // 텍스트 (슬라이더 영역 제외한 가운데)
                HStack(spacing: 0) {
                    if isOn {
                        Text("ON")
                            .frame(width: toggleWidth - knobSize - knobPadding * 2, height: toggleHeight)
                            .foregroundColor(.white)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        Spacer().frame(width: knobSize + knobPadding * 2)
                    } else {
                        Spacer().frame(width: knobSize + knobPadding * 2)
                        Text("OFF")
                            .frame(width: toggleWidth - knobSize - knobPadding * 2, height: toggleHeight)
                            .foregroundColor(.white)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }
                }

                // 슬라이더
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

extension Date {
    var isAM: Bool {
        let hour = Calendar.current.component(.hour, from: self)
        return hour < 12
    }
}
