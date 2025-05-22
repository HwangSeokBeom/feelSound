//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/22/25.
//

// ReminderSetting.swift
import Foundation

struct ReminderSetting: Codable {
    let isEnabled: Bool
    let selectedTime: Date
    let selectedDays: [String]
}
