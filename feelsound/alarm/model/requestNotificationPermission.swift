//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/20/25.
//

import UserNotifications

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            print("권한 요청 에러: \(error)")
        }
        print("알림 권한: \(granted)")
    }
}
