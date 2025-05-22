//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/22/25.
//

import Foundation
import UserNotifications
import SwiftUI

class ReminderViewModel: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var selectedTime: Date = Date()
    @Published var selectedDays: Set<Weekday> = []

    private let reminderKey = Constants.UserDefaultsKeys.reminderSetting

    func load() {
        guard let data = UserDefaults.standard.data(forKey: reminderKey),
              let setting = try? JSONDecoder().decode(ReminderSetting.self, from: data) else {
            return
        }
        isEnabled = setting.isEnabled
        selectedTime = setting.selectedTime
        selectedDays = Set(setting.selectedDays.compactMap { Weekday(rawValue: $0) })
    }

    func save() {
        let setting = ReminderSetting(
            isEnabled: isEnabled,
            selectedTime: selectedTime,
            selectedDays: selectedDays.map { $0.rawValue }
        )
        if let data = try? JSONEncoder().encode(setting) {
            UserDefaults.standard.set(data, forKey: reminderKey)
        }
    }

    func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
        save()
    }

    func handleDismiss() {
        save()
        if isEnabled {
            NotificationManager.shared.scheduleNotifications(for: selectedDays, at: selectedTime)
        } else {
            NotificationManager.shared.removeAllNotifications()
        }
    }
}
