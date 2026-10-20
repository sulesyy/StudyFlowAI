import SwiftUI

private struct TodayTaskItem: Identifiable {
    let course: Course
    let task: StudyTask
    var id: UUID { task.id }
}

struct DashboardView: View {
    @ObservedObject var viewModel: StudyPlannerViewModel
    let onOpenCourses: () -> Void
    let onOpenAI: () -> Void

    @State private var activeSheet: DashboardSheet?

    private var totalTopics: Int {
        viewModel.courses.reduce(0) { $0 + $1.topics.count }
    }

    private var completedTopics: Int {
        viewModel.courses.reduce(0) { $0 + $1.topics.filter(\.isCompleted).count }
    }

    private var progress: Double {
        guard totalTopics > 0 else { return 0 }
        return Double(completedTopics) / Double(totalTopics)
    }

    private var nextTopic: (course: Course, topic: StudyTopic)? {
        for course in viewModel.courses {
            if let topic = course.topics.first(where: { !$0.isCompleted }) {
                return (course, topic)
            }
        }
        return nil
    }

    private var todayTasks: [TodayTaskItem] {
        viewModel.courses.flatMap { course in
            course.studyTasks
                .filter { Calendar.current.isDateInToday($0.date) }
                .map { TodayTaskItem(course: course, task: $0) }
        }
    }

    private var nextExam: (course: Course, days: Int)? {
        let today = Calendar.current.startOfDay(for: .now)
        return viewModel.courses
            .filter { Calendar.current.startOfDay(for: $0.examDate) >= today }
            .sorted { $0.examDate < $1.examDate }
            .first
            .map { course in
                let days = Calendar.current.dateComponents(
                    [.day],
                    from: today,
                    to: Calendar.current.startOfDay(for: course.examDate)
                ).day ?? 0
                return (course, days)
            }
    }

    private var localizedToday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: .now)
    }

    private var emptyPlanMessage: String {
        if viewModel.courses.isEmpty {
            return "İlk dersini ekleyince günlük planın burada görünür."
        }
        if let nextTopic { return "Devam et: \(nextTopic.topic.title)" }
        return "Bugün için görev eklenmedi."
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Günaydın" }
        if hour < 18 { return "İyi günler" }
        return "İyi akşamlar"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                progressCard
                if let nextExam {
                    examCard(nextExam)
                }
                todayPlanSection
                coursesSection
                aiBanner
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Bugün")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    activeSheet = .focusTimer
                } label: {
                    Image(systemName: "timer")
                }
                .accessibilityLabel("Odak sayacı")
                .accessibilityIdentifier("openFocusTimer")

                Button {
                    activeSheet = .backup
                } label: {
                    Image(systemName: "icloud.and.arrow.up")
                }
                .accessibilityLabel("Yedekleme")
                .accessibilityIdentifier("openBackup")

                Button {
                    activeSheet = .addCourse
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Yeni ders ekle")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addCourse:
                AddCourseView(viewModel: viewModel)
            case .focusTimer:
                NavigationStack { FocusTimerView() }
            case .backup:
                NavigationStack { StudyFlowBackupView(viewModel: viewModel) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localizedToday)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text(greeting)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .tracking(-0.5)

                Spacer()

                if viewModel.statistics.streak > 0 {
                    Label("\(viewModel.statistics.streak) gün", systemImage: "flame.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.12), in: Capsule())
                }
            }

            Text("Bugün kendin için güzel bir adım at.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("BUGÜNÜN ODAĞI", systemImage: "sparkle")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.76))
                Spacer()
                Image(systemName: "circle.grid.2x2.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.55))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(totalTopics == 0 ? "İlk hedefini belirle" : "Derslerinde ilerliyorsun")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text(totalTopics == 0
                     ? "Derslerini ekle, çalışma planını birlikte oluşturalım."
                     : "\(completedTopics) / \(totalTopics) konu tamamlandı")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            }

            if totalTopics > 0 {
                ProgressView(value: progress)
                    .tint(.white)
                    .background(.white.opacity(0.22), in: Capsule())
                    .accessibilityLabel("Ders ilerlemesi yüzde \(Int(progress * 100))")
            }

            if let nextTopic {
                NavigationLink {
                    CourseDetailView(viewModel: viewModel, courseID: nextTopic.course.id)
                } label: {
                    primaryButtonLabel("Çalışmaya başla")
                }
                .accessibilityHint("\(nextTopic.course.name) dersindeki \(nextTopic.topic.title) konusunu açar")
            } else if totalTopics == 0, let course = viewModel.courses.first {
                NavigationLink {
                    CourseDetailView(viewModel: viewModel, courseID: course.id)
                } label: {
                    primaryButtonLabel("Konularını ekle")
                }
            } else if viewModel.courses.isEmpty {
                Button {
                    activeSheet = .addCourse
                } label: {
                    primaryButtonLabel("İlk dersini ekle")
                }
            } else {
                Label("Tüm konular tamamlandı", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [StudyFlowPalette.ink, StudyFlowPalette.ink.opacity(0.86), Color.indigo.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .shadow(color: StudyFlowPalette.ink.opacity(0.16), radius: 18, x: 0, y: 10)
    }

    private func primaryButtonLabel(_ title: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
            Image(systemName: "arrow.up.right")
        }
        .font(.subheadline.weight(.bold))
        .foregroundStyle(StudyFlowPalette.ink)
        .padding(.horizontal, 17)
        .padding(.vertical, 12)
        .background(.white, in: Capsule())
    }

    private func examCard(_ exam: (course: Course, days: Int)) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar")
                .font(.title3.weight(.semibold))
                .foregroundStyle(StudyFlowPalette.accent)
                .frame(width: 46, height: 46)
                .background(StudyFlowPalette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 4) {
                Text("YAKLAŞAN SINAV")
                    .font(.caption2.weight(.bold))
                    .tracking(0.9)
                    .foregroundStyle(.secondary)
                Text(exam.course.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(exam.course.examDate.formatted(.dateTime.locale(Locale(identifier: "tr_TR")).day().month(.abbreviated)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 6)

            Text(exam.days == 0 ? "Bugün" : "\(exam.days) gün")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(exam.days <= 3 ? .orange : StudyFlowPalette.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background((exam.days <= 3 ? Color.orange : StudyFlowPalette.accent).opacity(0.12), in: Capsule())
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var todayPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Bugünkü plan", detail: todayTasks.isEmpty ? nil : "\(todayTasks.count) görev")

            if todayTasks.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.title3)
                        .foregroundStyle(StudyFlowPalette.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(nextTopic == nil ? "Bugün için planlı görev yok" : "Bugün için görev eklenmedi")
                            .font(.subheadline.weight(.semibold))
                        Text(emptyPlanMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todayTasks.prefix(3))) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "circle")
                                .foregroundStyle(StudyFlowPalette.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.task.topicTitle)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.course.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.task.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        if item.id != todayTasks.prefix(3).last?.id {
                            Divider().padding(.leading, 30)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeading("Derslerin", detail: "\(viewModel.courses.count)")
                Spacer()
                Button("Tümünü gör", action: onOpenCourses)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(StudyFlowPalette.accent)
            }

            if viewModel.courses.isEmpty {
                Button {
                    activeSheet = .addCourse
                } label: {
                    Label("Ders ekleyerek başla", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.courses.prefix(2)) { course in
                        NavigationLink {
                            CourseDetailView(viewModel: viewModel, courseID: course.id)
                        } label: {
                            CompactCourseRow(course: course)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var aiBanner: some View {
        Button(action: onOpenAI) {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI ile çalış")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Özet, quiz ve çalışma kartları")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.74))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(17)
            .background(
                LinearGradient(
                    colors: [StudyFlowPalette.accent, StudyFlowPalette.accent.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionHeading(_ title: String, detail: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .tracking(-0.2)
            if let detail {
                Text(detail)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CompactCourseRow: View {
    let course: Course

    private var completed: Int {
        course.topics.filter(\.isCompleted).count
    }

    private var progress: Double {
        guard !course.topics.isEmpty else { return 0 }
        return Double(completed) / Double(course.topics.count)
    }

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "book.closed.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(StudyFlowPalette.accent)
                .frame(width: 42, height: 42)
                .background(StudyFlowPalette.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(course.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: progress)
                    .tint(StudyFlowPalette.accent)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
    }
}

private enum DashboardSheet: String, Identifiable {
    case addCourse
    case focusTimer
    case backup
    var id: String { rawValue }
}

private enum StudyFlowPalette {
    static let ink = Color(red: 0.12, green: 0.17, blue: 0.27)
    static let accent = Color(red: 0.27, green: 0.36, blue: 0.46)
}

#Preview {
    NavigationStack {
        DashboardView(viewModel: StudyPlannerViewModel(), onOpenCourses: {}, onOpenAI: {})
    }
}
