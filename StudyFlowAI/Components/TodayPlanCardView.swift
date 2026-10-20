//
//  TodayPlanCardView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 15.07.2026.
//

import SwiftUI

struct TodayPlanCardView: View {

    let courses: [Course]

    var todayTasks: [(String, String)] {

        let calendar = Calendar.current

        return courses.flatMap { course in

            course.studyTasks.compactMap { task in

                if calendar.isDateInToday(task.date) {

                    return (course.name, task.topicTitle)

                }

                return nil

            }

        }

    }

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("📅 Bugünkü Çalışma Planı")
                .font(.headline)

            if todayTasks.isEmpty {

                Text("Bugün için görev bulunmuyor.")
                    .foregroundStyle(.secondary)

            } else {

                ForEach(todayTasks.indices, id: \.self) { index in

                    VStack(alignment: .leading, spacing: 4) {

                        Text(todayTasks[index].0)
                            .font(.subheadline)
                            .fontWeight(.bold)

                        Text("• \(todayTasks[index].1)")
                            .foregroundStyle(.secondary)

                    }

                }

            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 18))

    }

}

#Preview {

    TodayPlanCardView(courses: [])

}
