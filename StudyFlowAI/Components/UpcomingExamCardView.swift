//
//  UpcomingExamCardView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import SwiftUI

struct UpcomingExamCardView: View {

    let courses: [Course]

    private var nextExam: Course? {
        courses
            .filter { $0.examDate >= Date() }
            .sorted { $0.examDate < $1.examDate }
            .first
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            Label("Yaklaşan Sınav",
                  systemImage: "calendar")

                .font(.headline)

            if let exam = nextExam {

                Text(exam.name)
                    .font(.title2)
                    .bold()

                let days = Calendar.current.dateComponents(
                    [.day],
                    from: Date(),
                    to: exam.examDate
                ).day ?? 0

                Text("⏳ \(max(days, 0)) gün kaldı")
                    .foregroundStyle(.secondary)

            } else {

                Text("Yaklaşan sınav bulunmuyor.")
                    .foregroundStyle(.secondary)

            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20))

    }
}

#Preview {
    UpcomingExamCardView(courses: [])
}
