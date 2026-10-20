import SwiftUI
import UniformTypeIdentifiers

struct StudyFlowBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data = Data()) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct StudyFlowBackupView: View {
    @ObservedObject var viewModel: StudyPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var document = StudyFlowBackupDocument()
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var showRestoreConfirmation = false
    @State private var showResult = false
    @State private var pendingData: Data?
    @State private var resultMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Verilerin cihazında saklanır.", systemImage: "lock.shield")
                .font(.headline)
            Text("Yedeği Dosyalar uygulamasında iCloud Drive’a kaydedebilir, yeni cihazında buradan geri yükleyebilirsin. Geri yükleme mevcut ders ve ilerleme verilerinin yerine geçer.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                do {
                    document = StudyFlowBackupDocument(data: try StudyPlanStorage.createBackup())
                    showExporter = true
                } catch {
                    showResult("Yedek hazırlanamadı: \(error.localizedDescription)")
                }
            } label: {
                Label("iCloud Drive’a yedekle", systemImage: "icloud.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("exportStudyFlowBackup")

            Button {
                showImporter = true
            } label: {
                Label("Yedekten geri yükle", systemImage: "arrow.clockwise.icloud")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("importStudyFlowBackup")

            Spacer()
        }
        .padding(22)
        .navigationTitle("Yedekleme")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Kapat") { dismiss() }
            }
        }
        .fileExporter(isPresented: $showExporter, document: document, contentType: .json,
                      defaultFilename: "StudyFlowAI-Yedek") { result in
            switch result {
            case .success: showResult("Yedek dosyası kaydedildi.")
            case .failure(let error): showResult("Yedek kaydedilemedi: \(error.localizedDescription)")
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                pendingData = try Data(contentsOf: url)
                showRestoreConfirmation = true
            } catch {
                showResult("Yedek dosyası açılamadı: \(error.localizedDescription)")
            }
        }
        .confirmationDialog("Bu yedek mevcut verilerinin yerine geçecek. Devam edilsin mi?",
                            isPresented: $showRestoreConfirmation, titleVisibility: .visible) {
            Button("Geri yükle", role: .destructive) { restore() }
            Button("Vazgeç", role: .cancel) { pendingData = nil }
        }
        .alert("Yedekleme", isPresented: $showResult) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(resultMessage)
        }
    }

    @MainActor
    private func restore() {
        guard let pendingData else { return }
        do {
            let backup = try StudyPlanStorage.restoreBackup(from: pendingData)
            viewModel.courses = backup.courses
            viewModel.statistics = backup.statistics
            self.pendingData = nil
            showResult("Yedek geri yüklendi. Derslerin, kartların ve çalışma verilerin hazır.")
        } catch {
            self.pendingData = nil
            showResult("Yedek geri yüklenemedi: \(error.localizedDescription)")
        }
    }

    private func showResult(_ message: String) {
        resultMessage = message
        showResult = true
    }
}
