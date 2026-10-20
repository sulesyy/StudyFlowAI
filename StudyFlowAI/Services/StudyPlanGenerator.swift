//
//  StudyPlanGenerator.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 15.07.2026.
//

import Foundation

struct StudyPlanGenerator {

    static func generateTasks(
        topics: [StudyTopic],
        examDate: Date
    ) -> [StudyTask] {

        guard !topics.isEmpty else {
            return []
        }

        let calendar = Calendar.current
        let today = Date()

        let totalDays = max(
            calendar.dateComponents(
                [.day],
                from: today,
                to: examDate
            ).day ?? 1,
            1
        )

        var tasks: [StudyTask] = []

        for (index, topic) in topics.enumerated() {

            let offset = min(index, totalDays - 1)

            let date = calendar.date(
                byAdding: .day,
                value: offset,
                to: today
            ) ?? today

            tasks.append(
                StudyTask(
                    date: date,
                    topicTitle: topic.title
                )
            )

        }

        return tasks
    }

}
