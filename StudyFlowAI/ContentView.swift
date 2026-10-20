import SwiftUI

enum StudyFlowTab: Hashable {
    case today
    case courses
    case ai
    case statistics
}

struct ContentView: View {
    @StateObject private var viewModel = StudyPlannerViewModel()
    @State private var selectedTab: StudyFlowTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(
                    viewModel: viewModel,
                    onOpenCourses: { selectedTab = .courses },
                    onOpenAI: { selectedTab = .ai }
                )
            }
            .tabItem { Label("Bugün", systemImage: "sun.max.fill") }
            .tag(StudyFlowTab.today)

            NavigationStack {
                CoursesTabView(viewModel: viewModel)
            }
            .tabItem { Label("Dersler", systemImage: "books.vertical.fill") }
            .tag(StudyFlowTab.courses)

            NavigationStack {
                AIAssistantTabView()
            }
            .tabItem { Label("AI", systemImage: "sparkles") }
            .tag(StudyFlowTab.ai)

            NavigationStack {
                StatisticsView(viewModel: viewModel)
            }
            .tabItem { Label("İstatistik", systemImage: "chart.bar.fill") }
            .tag(StudyFlowTab.statistics)
        }
        .tint(Color(red: 0.27, green: 0.36, blue: 0.46))
    }
}

private struct CoursesTabView: View {
    @ObservedObject var viewModel: StudyPlannerViewModel
    @State private var showAddCourse = false

    var body: some View {
        Group {
            if viewModel.courses.isEmpty {
                ContentUnavailableView {
                    Label("Henüz dersin yok", systemImage: "books.vertical")
                } description: {
                    Text("Derslerini ve sınav tarihlerini ekleyerek kişisel çalışma alanını oluştur.")
                } actions: {
                    Button {
                        showAddCourse = true
                    } label: {
                        Label("İlk dersi ekle", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Tüm derslerin ve ilerlemen burada.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)

                        ForEach(viewModel.courses) { course in
                            NavigationLink {
                                CourseDetailView(viewModel: viewModel, courseID: course.id)
                            } label: {
                                CourseCardView(course: course) {
                                    viewModel.deleteCourse(id: course.id)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("courseCard-\(course.name)")
                        }
                    }
                    .padding(20)
                }
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
        .navigationTitle("Dersler")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddCourse = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Yeni ders ekle")
            }
        }
        .sheet(isPresented: $showAddCourse) {
            AddCourseView(viewModel: viewModel)
        }
    }
}

private struct AIAssistantTabView: View {
    @State private var topic = ""

    private var cleanedTopic: String {
        topic.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Neye çalışıyorsun?")
                        .font(.title2.weight(.bold))
                    Text("Konunu yaz, sana uygun çalışma aracını seç.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("DERS KONUSU")
                        .font(.caption.weight(.bold))
                        .tracking(0.9)
                        .foregroundStyle(.secondary)
                    TextField("Örn. Fotosentez", text: $topic)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled()
                        .padding(15)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("Ders konusu")
                }

                VStack(spacing: 11) {
                    if cleanedTopic.isEmpty {
                        Label("Devam etmek için önce bir konu yaz.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 2)
                    }

                    NavigationLink {
                        AISummaryView(topic: cleanedTopic)
                    } label: {
                        AIToolRow(title: "Konu özeti", subtitle: "Kısa ve anlaşılır anlatım", symbol: "text.alignleft", tint: .indigo)
                    }
                    .disabled(cleanedTopic.isEmpty)

                    NavigationLink {
                        AIQuizView(topic: cleanedTopic)
                    } label: {
                        AIToolRow(title: "Quiz oluştur", subtitle: "Bilgini çoktan seçmeli sorularla dene", symbol: "checkmark.circle", tint: .teal)
                    }
                    .disabled(cleanedTopic.isEmpty)

                    NavigationLink {
                        FlashcardView(topic: cleanedTopic)
                    } label: {
                        AIToolRow(title: "Çalışma kartları", subtitle: "Soru-cevap kartlarıyla tekrar yap", symbol: "rectangle.stack", tint: .orange)
                    }
                    .disabled(cleanedTopic.isEmpty)

                    NavigationLink {
                        FlashcardReviewView()
                    } label: {
                        AIToolRow(title: "Akıllı tekrar", subtitle: "Hazır kartlarını aralıklı tekrar et", symbol: "rectangle.stack.badge.clock", tint: .purple)
                    }

                    NavigationLink {
                        AIContentLibraryView()
                    } label: {
                        AIToolRow(title: "Kaydedilen içerikler", subtitle: "Daha önce oluşturduklarını çevrimdışı aç", symbol: "books.vertical.fill", tint: .blue)
                    }
                }

                NavigationLink {
                    PDFSummaryView()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 15))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PDF’den çalış")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Notlarından özet, quiz ve sohbet")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.78))
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.12, green: 0.17, blue: 0.27), Color.indigo.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

                AIStudySuggestionView()
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("AI çalışma alanı")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AIToolRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
    }
}

#Preview {
    ContentView()
}
