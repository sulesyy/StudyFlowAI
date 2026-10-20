//
//  CourseCardView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 15.07.2026.
//

import SwiftUI

struct CourseCardView: View {

    let course: Course
    var onDelete: (() -> Void)? = nil

    private var completed: Int {
        course.topics.filter { $0.isCompleted }.count
    }

    private var progress: Double {
        guard !course.topics.isEmpty else { return 0 }
        return Double(completed) / Double(course.topics.count)
    }

    private var daysLeft: Int {
        max(
            Calendar.current.dateComponents(
                [.day],
                from: Date(),
                to: course.examDate
            ).day ?? 0,
            0
        )
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            // MARK: Başlık

            HStack {

                HStack(spacing: 10) {

                    Image(systemName: "book.closed.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    Text(course.name)
                        .font(.title3)
                        .fontWeight(.bold)

                }

                Spacer()

                Text("⭐️ \(course.difficulty)/5")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(Capsule())

            }

            // MARK: İlerleme

            VStack(alignment: .leading, spacing: 8) {

                HStack {

                    Text("İlerleme")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .fontWeight(.bold)

                }

                ProgressView(value: progress)
                    .tint(.green)

                Text("\(completed) / \(course.topics.count) konu tamamlandı")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Divider()

            // MARK: Alt Bilgiler

            HStack {

                Label(
                    course.examDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    ),
                    systemImage: "calendar"
                )

                Spacer()

                Label(
                    "\(daysLeft) gün kaldı",
                    systemImage: "clock.fill"
                )
                .foregroundStyle(daysLeft <= 7 ? .red : .orange)

            }
            .font(.subheadline)

        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(
            color: .black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )

        // MARK: Menü

        .overlay(alignment: .topTrailing) {

            Menu {

                Button(role: .destructive) {

                    onDelete?()

                } label: {

                    Label(
                        "Sil",
                        systemImage: "trash"
                    )

                }

            } label: {

                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding()
                    .accessibilityLabel("Ders seçenekleri")
                    .accessibilityIdentifier("courseMenu-\(course.id)")

            }

        }

    }

}

#Preview {

    CourseCardView(
        course: Course(
            name: "Algoritma",
            examDate: Calendar.current.date(
                byAdding: .day,
                value: 5,
                to: .now
            )!,
            difficulty: 4,
            topics: [
                StudyTopic(title: "C++"),
                StudyTopic(title: "Pointer"),
                StudyTopic(title: "Class"),
                StudyTopic(title: "Tree")
            ]
        )
    )

}
