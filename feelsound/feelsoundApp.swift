//
//  feelsoundApp.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import SwiftUI
import SwiftData
import AVFoundation
import UserNotifications

@main
struct feelsoundApp: App {
    @StateObject var router = Router()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environmentObject(router)
        .modelContainer(sharedModelContainer)
    }

    init() {
        Font.registerFontsTTF(fontName: "Micro5-Regular")
        Font.registerFonts(fontName: "Pretendard-Bold")
        Font.registerFonts(fontName: "Pretendard-Regular")
        Font.registerFonts(fontName: "Pretendard-SemiBold")

        let identifier = Locale.current.identifier
        guard let regionCode = Locale.current.regionCode else { return }
        guard let languageCode = Locale.current.languageCode else { return }
        print("identifier: \(identifier), regionCode: \(regionCode), languageCode: \(languageCode)")
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession Error: \(error)")
        }

        // 로컬 알림에 필요한 설정
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()

        application.beginReceivingRemoteControlEvents()
        return true
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 요청 실패: \(error.localizedDescription)")
            } else {
                print("알림 권한 granted: \(granted)")
            }
        }
    }
}

// 포그라운드에서도 알림 표시되도록 설정
extension AppDelegate: UNUserNotificationCenterDelegate {
    // 포그라운드 알림 배너 출력
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
