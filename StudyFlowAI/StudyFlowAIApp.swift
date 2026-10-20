//
//  StudyFlowAIApp.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 12.07.2026.
//

import SwiftUI
import UserNotifications

@main
struct StudyFlowAIApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains("-resetStudyFlowForUITest") {
            UserDefaults.standard.removeObject(forKey: "StudyFlowCourses")
            UserDefaults.standard.removeObject(forKey: "StudyStatistics")
            UserDefaults.standard.removeObject(forKey: "StudyFlowReviewCards")
            UserDefaults.standard.removeObject(forKey: "StudyFlowCachedAIContent")
            UserDefaults.standard.removeObject(forKey: "StudyFlowSavedAIContent")
            UserDefaults.standard.removeObject(forKey: "StudyFlowFocusDuration")
            UserDefaults.standard.removeObject(forKey: "StudyFlowFocusRemaining")
            UserDefaults.standard.removeObject(forKey: "StudyFlowFocusRunning")
            UserDefaults.standard.removeObject(forKey: "StudyFlowFocusEndDate")
            UserDefaults.standard.removeObject(forKey: "StudyFlowFocusTotalMinutes")
            UserDefaults.standard.removeObject(forKey: "StudyFlowFocusSessions")
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
