//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/22/25.
//

// NotificationManager.swift
import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("권한 요청 에러: \(error)")
            }
            print("알림 권한: \(granted)")
        }
    }

    func scheduleNotifications(for days: Set<Weekday>, at time: Date) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for day in days {
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
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

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
