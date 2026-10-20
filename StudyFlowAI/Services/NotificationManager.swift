//
//  NotificationManager.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    func scheduleNotification(title: String, body: String, date: Date) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let authorized: Bool

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            authorized = true
        case .notDetermined:
            authorized = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        case .denied:
            authorized = false
        @unknown default:
            authorized = false
        }

        guard authorized, date > Date() else { return false }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}
