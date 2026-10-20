//
//  StudyPlanStorage.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 15.07.2026.
//

import Foundation

final class StudyPlanStorage {

    // MARK: - Keys

    private static let key = "StudyFlowCourses"
    private static let statisticsKey = "StudyStatistics"

    struct Backup: Codable {
        let formatVersion: Int
        let createdAt: Date
        let courses: [Course]
        let statistics: StudyStatistics
        let reviewCards: [SavedReviewCard]
        let focusMinutes: Int
        let focusSessions: Int
        let aiCache: Data?
        let aiLibrary: Data?
    }

    @MainActor
    static func createBackup() throws -> Data {
        let backup = Backup(
            formatVersion: 1,
            createdAt: .now,
            courses: load(),
            statistics: loadStatistics(),
            reviewCards: FlashcardReviewStore.allCards(),
            focusMinutes: FocusTimerModel.shared.totalMinutes,
            focusSessions: FocusTimerModel.shared.completedSessions,
            aiCache: AIContentCache.backupData(),
            aiLibrary: AIContentCache.libraryBackupData()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    @MainActor
    static func restoreBackup(from data: Data) throws -> Backup {
        let backup = try JSONDecoder().decode(Backup.self, from: data)
        guard backup.formatVersion == 1 else {
            throw NSError(domain: "StudyFlowBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bu yedek dosyasının sürümü desteklenmiyor."])
        }
        save(backup.courses)
        saveStatistics(backup.statistics)
        FlashcardReviewStore.restore(backup.reviewCards)
        FocusTimerModel.shared.restore(totalMinutes: backup.focusMinutes, sessions: backup.focusSessions)
        AIContentCache.restore(backup.aiCache)
        AIContentCache.restoreLibrary(backup.aiLibrary)
        return backup
    }

    // MARK: - Courses

    static func save(_ courses: [Course]) {

        if let data = try? JSONEncoder().encode(courses) {
            UserDefaults.standard.set(data, forKey: key)
        }

    }

    static func load() -> [Course] {

        guard
            let data = UserDefaults.standard.data(forKey: key),
            let courses = try? JSONDecoder().decode([Course].self, from: data)
        else {
            return []
        }

        return courses

    }

    // MARK: - Statistics

    static func saveStatistics(_ statistics: StudyStatistics) {

        if let data = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(data, forKey: statisticsKey)
        }

    }

    static func loadStatistics() -> StudyStatistics {

        guard
            let data = UserDefaults.standard.data(forKey: statisticsKey),
            let statistics = try? JSONDecoder().decode(
                StudyStatistics.self,
                from: data
            )
        else {
            return StudyStatistics()
        }

        return statistics

    }

}
