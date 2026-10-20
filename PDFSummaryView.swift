//
//  PDFSummaryView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 18.07.2026.
//

import SwiftUI

struct PDFSummaryView: View {

    @State private var selectedURL: URL?
    @State private var showPicker = false
    @State private var showChat = false

    @State private var extractedText = ""
    @State private var summary = ""

    @State private var quiz: [QuizQuestion] = []
    @State private var selectedAnswers: [UUID: Int] = [:]

    @State private var flashcards: [Flashcard] = []

    @State private var isLoading = false
    @State private var isExtractingPDF = false
    @State private var ocrPagesRead = 0
    @State private var errorMessage = ""

    private var quizScore: Int {
        quiz.filter {
            selectedAnswers[$0.id] == $0.answer
        }.count
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 25) {

                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {

                    Text("PDF Notunu Seç")
                        .font(.title2)
                        .bold()

                    Text("PDF içeriğinden özet, quiz, flashcard ve AI sohbet oluştur.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                }

                if let url = selectedURL {

                    Label(
                        url.lastPathComponent,
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)

                }

                Button {

                    showPicker = true

                } label: {

                    Label(
                        "PDF Seç",
                        systemImage: "folder"
                    )
                    .frame(maxWidth: .infinity)

                }
                .buttonStyle(.borderedProminent)

                if !errorMessage.isEmpty {

                    Label(
                        errorMessage,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.red.opacity(0.08))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )

                }

                if isExtractingPDF {
                    ProgressView("PDF sayfaları okunuyor; taranmış sayfalara OCR uygulanıyor…")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }

                if extractedText.isEmpty,
                   selectedURL != nil,
                   !isExtractingPDF {

                    ContentUnavailableView(
                        "PDF Metni Okunamadı",
                        systemImage: "doc.badge.questionmark",
                        description: Text(
                            "PDF’de okunabilir metin bulunamadı. Sayfanın net olduğundan emin ol veya başka bir PDF dene."
                        )
                    )

                }

                if !extractedText.isEmpty {

                    if ocrPagesRead > 0 {
                        Label("\(ocrPagesRead) taranmış sayfa OCR ile okundu.", systemImage: "viewfinder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    pdfTextPreview

                    aiButtons

                    loadingView

                    summaryView

                    quizView

                    flashcardReadyView

                }

            }
            .padding()

        }
        .navigationTitle("PDF AI")

        .sheet(isPresented: $showPicker) {

            PDFPicker(
                selectedURL: $selectedURL
            )

        }

        .sheet(isPresented: $showChat) {

            NavigationStack {

                AIChatView(
                    pdfText: extractedText
                )

            }

        }

        .task(id: selectedURL) {
            guard let url = selectedURL else { return }
            extractedText = ""
            summary = ""
            quiz = []
            flashcards = []
            selectedAnswers = [:]
            ocrPagesRead = 0
            errorMessage = ""
            isExtractingPDF = true
            let result = await PDFReader.extractText(from: url)
            guard !Task.isCancelled else { return }
            extractedText = result.text
            ocrPagesRead = result.scannedPagesRead
            isExtractingPDF = false
        }

    }
}
// MARK: - PDF Preview

private extension PDFSummaryView {

    var pdfTextPreview: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("📄 PDF İçeriği")
                .font(.headline)

            ScrollView {

                Text(extractedText)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding()

            }
            .frame(height: 260)
            .background(Color(.systemGray6))
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )

        }

    }

    // MARK: - AI Buttons

    var aiButtons: some View {

        VStack(spacing: 12) {

            Button {

                Task {

                    await runAIAction {

                        summary = try await AIService.shared
                            .summarizePDF(
                                text: extractedText
                            )

                    }

                }

            } label: {

                Label(
                    summary.isEmpty
                    ? "✨ AI Özet Oluştur"
                    : "🔄 Özeti Yeniden Oluştur",
                    systemImage: "sparkles"
                )
                .frame(maxWidth: .infinity)

            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Button {

                Task {

                    await runAIAction {

                        quiz = try await AIService.shared
                            .generateQuizFromPDF(
                                text: extractedText
                            )

                        selectedAnswers = [:]

                    }

                }

            } label: {

                Label(
                    "📝 AI Quiz Oluştur",
                    systemImage: "questionmark.circle.fill"
                )
                .frame(maxWidth: .infinity)

            }
            .buttonStyle(.bordered)
            .disabled(isLoading)

            Button {

                Task {

                    await runAIAction {

                        flashcards = try await AIService.shared
                            .generateFlashcardsFromPDF(
                                text: extractedText
                            )
                        FlashcardReviewStore.saveDeck(
                            title: selectedURL?.deletingPathExtension().lastPathComponent ?? "PDF Notları",
                            questions: flashcards.map { ($0.question, $0.answer) }
                        )

                    }

                }

            } label: {

                Label(
                    "🗂 AI Flashcards Oluştur",
                    systemImage: "rectangle.stack.fill"
                )
                .frame(maxWidth: .infinity)

            }
            .buttonStyle(.bordered)
            .disabled(isLoading)

            Button {

                showChat = true

            } label: {

                Label(
                    "💬 AI ile Sohbet Et",
                    systemImage: "message.fill"
                )
                .frame(maxWidth: .infinity)

            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(isLoading)

        }

    }
}
// MARK: - Loading

private extension PDFSummaryView {

    var loadingView: some View {

        Group {

            if isLoading {

                ProgressView("🤖 AI analiz ediyor...")
                    .padding(.vertical)

            }

        }

    }

    // MARK: - Summary

    var summaryView: some View {

        Group {

            if !summary.isEmpty {

                VStack(alignment: .leading, spacing: 15) {

                    Label(
                        "AI Özeti",
                        systemImage: "sparkles"
                    )
                    .font(.title3)
                    .bold()

                    Text(summary)
                        .textSelection(.enabled)

                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(Color(.systemGray6))
                .clipShape(
                    RoundedRectangle(cornerRadius: 15)
                )

            }

        }

    }

    // MARK: - Quiz

    var quizView: some View {

        Group {

            if !quiz.isEmpty {

                VStack(alignment: .leading, spacing: 18) {

                    HStack {

                        Label(
                            "AI Quiz",
                            systemImage: "questionmark.circle.fill"
                        )
                        .font(.title3)
                        .bold()

                        Spacer()

                        Text("\(quizScore)/\(quiz.count)")
                            .bold()
                            .foregroundStyle(.blue)

                    }

                    ForEach(quiz) { question in

                        VStack(alignment: .leading, spacing: 12) {

                            Text(question.question)
                                .bold()

                            ForEach(question.options.indices, id: \.self) { index in

                                QuizOptionRow(
                                    title: question.options[index],
                                    isSelected:
                                        selectedAnswers[question.id] == index
                                )
                                .onTapGesture {

                                    selectedAnswers[question.id] = index

                                }

                            }

                            Divider()

                        }

                    }

                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(
                    RoundedRectangle(cornerRadius: 15)
                )

            }

        }

    }

}
// MARK: - Flashcards

private extension PDFSummaryView {

    var flashcardReadyView: some View {

        Group {

            if !flashcards.isEmpty {

                VStack(alignment: .leading, spacing: 18) {

                    Label(
                        "AI Flashcards",
                        systemImage: "rectangle.stack.fill"
                    )
                    .font(.title3)
                    .bold()

                    ForEach(flashcards) { card in

                        FlashcardRow(card: card)

                    }

                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(
                    RoundedRectangle(cornerRadius: 15)
                )

            }

        }

    }

    // MARK: - AI Helper

    func runAIAction(
        _ action: @escaping () async throws -> Void
    ) async {

        isLoading = true
        errorMessage = ""

        do {

            try await action()

        } catch {

            errorMessage = error.localizedDescription

        }

        isLoading = false

    }

}

// MARK: - Quiz Option Row

struct QuizOptionRow: View {

    let title: String
    let isSelected: Bool

    var body: some View {

        HStack {

            Image(
                systemName:
                    isSelected
                ? "largecircle.fill.circle"
                : "circle"
            )

            Text(title)

            Spacer()

        }
        .padding()
        .background(
            isSelected
            ? Color.blue.opacity(0.15)
            : Color(.systemGray6)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )

    }

}

// MARK: - Preview

#Preview {

    NavigationStack {

        PDFSummaryView()

    }

}
