//
//  StudyPlanView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 15.07.2026.
//

import SwiftUI

struct StudyPlanView: View {

    let course: Course

    var body: some View {

        List {

            if course.studyTasks.isEmpty {

                ContentUnavailableView(
                    "Henüz plan oluşturulmadı",
                    systemImage: "calendar.badge.exclamationmark"
                )

            } else {

                ForEach(course.studyTasks) { task in

                    VStack(alignment: .leading, spacing: 6) {

                        Text(task.topicTitle)
                            .font(.headline)

                        Text(task.date.formatted(date: .long,
                                                 time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.gray)

                    }

                }

            }

        }
        .navigationTitle("Çalışma Planı")
    }
}

#Preview {

    StudyPlanView(
        course: Course(
            name: "Algoritma",
            examDate: .now,
            difficulty: 4,
            topics: [],
            studyTasks: [
                StudyTask(date: .now, topicTitle: "C++"),
                StudyTask(date: .now, topicTitle: "Pointer")
            ]
        )
    )
}
