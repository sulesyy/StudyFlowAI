import SwiftUI
import Combine

@MainActor
final class FocusTimerModel: ObservableObject {
    static let shared = FocusTimerModel()

    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning = false
    @Published private(set) var selectedMinutes = 25
    @Published private(set) var totalMinutes: Int
    @Published private(set) var completedSessions: Int
    private var endDate: Date?

    private let defaults = UserDefaults.standard
    private let durationKey = "StudyFlowFocusDuration"
    private let remainingKey = "StudyFlowFocusRemaining"
    private let runningKey = "StudyFlowFocusRunning"
    private let endDateKey = "StudyFlowFocusEndDate"
    private let totalKey = "StudyFlowFocusTotalMinutes"
    private let sessionsKey = "StudyFlowFocusSessions"

    private init() {
        let initialMinutes = defaults.object(forKey: durationKey) as? Int ?? 25
        selectedMinutes = initialMinutes
        remainingSeconds = defaults.object(forKey: remainingKey) as? Int ?? initialMinutes * 60
        totalMinutes = defaults.object(forKey: totalKey) as? Int ?? 0
        completedSessions = defaults.object(forKey: sessionsKey) as? Int ?? 0
        isRunning = defaults.bool(forKey: runningKey)
        endDate = defaults.object(forKey: endDateKey) as? Date
        refresh()
    }

    func select(minutes: Int) {
        guard !isRunning, [25, 50].contains(minutes) else { return }
        selectedMinutes = minutes
        remainingSeconds = minutes * 60
        defaults.set(minutes, forKey: durationKey)
        persistTimer()
    }

    func start() {
        guard !isRunning else { return }
        if remainingSeconds <= 0 { remainingSeconds = selectedMinutes * 60 }
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        persistTimer()
    }

    func pause() {
        refresh()
        guard isRunning else { return }
        isRunning = false
        endDate = nil
        persistTimer()
    }

    func reset() {
        isRunning = false
        endDate = nil
        remainingSeconds = selectedMinutes * 60
        persistTimer()
    }

    func refresh() {
        guard isRunning, let endDate else { return }
        remainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        if remainingSeconds == 0 {
            isRunning = false
            self.endDate = nil
            totalMinutes += selectedMinutes
            completedSessions += 1
            defaults.set(totalMinutes, forKey: totalKey)
            defaults.set(completedSessions, forKey: sessionsKey)
            remainingSeconds = selectedMinutes * 60
        }
        persistTimer()
    }

    func restore(totalMinutes: Int, sessions: Int) {
        self.totalMinutes = max(0, totalMinutes)
        completedSessions = max(0, sessions)
        defaults.set(self.totalMinutes, forKey: totalKey)
        defaults.set(completedSessions, forKey: sessionsKey)
    }

    private func persistTimer() {
        defaults.set(remainingSeconds, forKey: remainingKey)
        defaults.set(isRunning, forKey: runningKey)
        defaults.set(endDate, forKey: endDateKey)
    }
}

struct FocusTimerView: View {
    @ObservedObject private var timer = FocusTimerModel.shared
    @Environment(\.dismiss) private var dismiss
    private let pulse = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 26) {
            Text("Dikkatini tek bir derse ver.")
                .font(.subheadline).foregroundStyle(.secondary)

            Picker("Oturum süresi", selection: Binding(
                get: { timer.selectedMinutes },
                set: { timer.select(minutes: $0) }
            )) {
                Text("25 dk").tag(25)
                Text("50 dk").tag(50)
            }
            .pickerStyle(.segmented)
            .disabled(timer.isRunning)

            ZStack {
                Circle().stroke(Color.indigo.opacity(0.12), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: CGFloat(timer.remainingSeconds) / CGFloat(max(timer.selectedMinutes * 60, 1)))
                    .stroke(Color.indigo, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(timeText)
                    .font(.system(size: 52, weight: .semibold, design: .rounded).monospacedDigit())
                    .accessibilityIdentifier("focusTimerCountdown")
            }
            .frame(width: 250, height: 250)
            .padding(.vertical, 8)

            HStack(spacing: 16) {
                Button(timer.isRunning ? "Duraklat" : "Başlat") {
                    timer.isRunning ? timer.pause() : timer.start()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("focusTimerStartPause")

                Button("Sıfırla", systemImage: "arrow.counterclockwise") { timer.reset() }
                    .buttonStyle(.bordered)
                    .disabled(timer.isRunning)
            }

            Label("\(timer.completedSessions) oturum · \(timer.totalMinutes) dakika tamamlandı", systemImage: "chart.bar.fill")
                .font(.footnote).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
        .navigationTitle("Odak sayacı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Kapat") { dismiss() }
            }
        }
        .onReceive(pulse) { _ in timer.refresh() }
        .onAppear { timer.refresh() }
    }

    private var timeText: String {
        String(format: "%02d:%02d", timer.remainingSeconds / 60, timer.remainingSeconds % 60)
    }
}
