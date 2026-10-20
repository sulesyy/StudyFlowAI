//
//  StudyPlannerViewModel.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 12.07.2026.
//

import Foundation

final class StudyPlannerViewModel: ObservableObject {

    // MARK: - Courses

    @Published var courses: [Course] = [] {
        didSet {
            StudyPlanStorage.save(courses)
        }
    }

    // MARK: - Statistics

    @Published var statistics = StudyPlanStorage.loadStatistics() {
        didSet {
            StudyPlanStorage.saveStatistics(statistics)
        }
    }

    // MARK: - Init

    init() {
        courses = StudyPlanStorage.load()
    }

    // MARK: - Course Operations

    func addCourse(_ course: Course) {
        courses.append(course)
    }

    func deleteCourse(at offsets: IndexSet) {
        courses.remove(atOffsets: offsets)
    }

    func deleteCourse(id: UUID) {
        courses.removeAll { $0.id == id }
    }

    // MARK: - Topic Operations

    func toggleTopic(courseID: UUID, topicID: UUID) {

        guard let courseIndex = courses.firstIndex(where: { $0.id == courseID }) else {
            return
        }

        guard let topicIndex = courses[courseIndex].topics.firstIndex(where: { $0.id == topicID }) else {
            return
        }

        let wasCompleted = courses[courseIndex].topics[topicIndex].isCompleted
        courses[courseIndex].topics[topicIndex].isCompleted.toggle()

        // A study day counts only when a topic is completed, never when it is unchecked.
        if !wasCompleted {
            updateStudyStreak()
        }
    }

    // MARK: - Study Streak

    func updateStudyStreak() {

        let calendar = Calendar.current
        let today = Date()

        guard let lastDate = statistics.lastStudyDate else {
            statistics.lastStudyDate = today
            statistics.streak = 1
            return
        }

        // Aynı gün tekrar konu tamamlanırsa streak artmasın
        if calendar.isDate(lastDate, inSameDayAs: today) {
            return
        }

        // Dün çalışıldıysa streak +1
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(lastDate, inSameDayAs: yesterday) {

            statistics.streak += 1

        } else {

            // Seri bozulduysa tekrar 1'den başla
            statistics.streak = 1

        }

        statistics.lastStudyDate = today
    }
}
