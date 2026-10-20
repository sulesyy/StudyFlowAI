import SwiftUI

struct CourseDetailView: View {

    @ObservedObject var viewModel: StudyPlannerViewModel

    let courseID: UUID

    private var course: Course? {
        viewModel.courses.first(where: { $0.id == courseID })
    }

    private var completedTopics: Int {
        course?.topics.filter { $0.isCompleted }.count ?? 0
    }

    var body: some View {

        Group {

            if let course {

                List {

                    // MARK: - Sınav Bilgileri

                    Section("Sınav Bilgileri") {

                        HStack {

                            Text("📅 Sınav Tarihi")

                            Spacer()

                            Text(
                                course.examDate.formatted(
                                    date: .long,
                                    time: .omitted
                                )
                            )

                        }

                        HStack {

                            Text("⭐️ Zorluk")

                            Spacer()

                            Text("\(course.difficulty)/5")

                        }

                    }

                    // MARK: - İlerleme

                    Section("İlerleme") {

                        ProgressView(
                            value: Double(completedTopics),
                            total: Double(max(course.topics.count, 1))
                        )

                        Text("\(completedTopics) / \(course.topics.count) konu tamamlandı")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    }

                    // MARK: - Konular

                    Section("Konular") {

                        ForEach(course.topics) { topic in

                            HStack {

                                Button {

                                    viewModel.toggleTopic(
                                        courseID: course.id,
                                        topicID: topic.id
                                    )

                                } label: {

                                    HStack {

                                        Image(systemName:
                                                topic.isCompleted
                                                ? "checkmark.circle.fill"
                                                : "circle")

                                        Text(topic.title)

                                    }

                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("topicCompletion-\(topic.title)")

                                Spacer()

                                NavigationLink {

                                    AISummaryView(topic: topic.title)

                                } label: {

                                    Image(systemName: "brain.head.profile.fill")
                                        .foregroundStyle(.blue)

                                }

                                NavigationLink {

                                    FlashcardView(topic: topic.title)

                                } label: {

                                    Image(systemName: "rectangle.stack.fill")
                                        .foregroundStyle(.orange)

                                }

                                NavigationLink {

                                    AIQuizView(topic: topic.title)

                                } label: {

                                    Image(systemName: "questionmark.circle.fill")
                                        .foregroundStyle(.green)

                                }

                            }

                        }

                    }

                    // MARK: - Çalışma Planı

                    Section {

                        NavigationLink {

                            StudyPlanView(course: course)

                        } label: {

                            Label(
                                "Çalışma Planını Gör",
                                systemImage: "calendar"
                            )

                        }
                        .accessibilityIdentifier("studyPlanLink")

                    }

                }
                .navigationTitle(course.name)

            } else {

                ContentUnavailableView(
                    "Ders Bulunamadı",
                    systemImage: "exclamationmark.triangle"
                )

            }

        }

    }

}

#Preview {

    let viewModel = StudyPlannerViewModel()

    let sampleCourse = Course(
        name: "Swift Programlama",
        examDate: Date(),
        difficulty: 3,
        topics: [
            StudyTopic(title: "Variables"),
            StudyTopic(title: "Functions"),
            StudyTopic(title: "Classes")
        ],
        studyTasks: []
    )

    viewModel.courses = [sampleCourse]

    return NavigationStack {

        CourseDetailView(
            viewModel: viewModel,
            courseID: sampleCourse.id
        )

    }

}
