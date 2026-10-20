import Foundation
import PDFKit
import Testing
import UIKit
@testable import StudyFlowAI

struct StudyFlowAITests {

    @Test func scannedPDFUsesOnDeviceOCR() async throws {
        let pageSize = CGSize(width: 612, height: 792)
        let imageSize = CGSize(width: 1_224, height: 1_584)
        let scannedImage = UIGraphicsImageRenderer(size: imageSize).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))

            let title = "FOTOSENTEZ" as NSString
            title.draw(
                at: CGPoint(x: 100, y: 260),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 96),
                    .foregroundColor: UIColor.black
                ]
            )

            let body = "Bitkiler güneş ışığını kullanarak besin üretir." as NSString
            body.draw(
                in: CGRect(x: 100, y: 430, width: 1_050, height: 120),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 42),
                    .foregroundColor: UIColor.black
                ]
            )
        }

        // Drawing the text into a bitmap first creates an image-only PDF page,
        // like a scan, with no selectable PDF text layer.
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            scannedImage.draw(in: CGRect(origin: .zero, size: pageSize))
        }

        let pdfURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("studyflow-scanned-\(UUID().uuidString).pdf")
        try pdfData.write(to: pdfURL)
        defer { try? FileManager.default.removeItem(at: pdfURL) }

        let sourcePageText = PDFDocument(url: pdfURL)?.page(at: 0)?.string
        #expect(sourcePageText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false)

        let result = await PDFReader.extractText(from: pdfURL)
        #expect(result.scannedPagesRead == 1)
        #expect(result.text.localizedCaseInsensitiveContains("fotosentez"))
    }

    @Test func studyPlanIncludesEveryTopicInOrder() {
        let topics = [
            StudyTopic(title: "Hücre"),
            StudyTopic(title: "Fotosentez"),
            StudyTopic(title: "Ekosistem")
        ]
        let examDate = Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now

        let tasks = StudyPlanGenerator.generateTasks(topics: topics, examDate: examDate)

        #expect(tasks.count == topics.count)
        #expect(tasks.map(\.topicTitle) == topics.map(\.title))
        #expect(tasks.allSatisfy { $0.date <= examDate })
    }

    @Test func flashcardReviewSchedulesSpacedIntervals() {
        let previousCards = FlashcardReviewStore.allCards()
        defer { FlashcardReviewStore.restore(previousCards) }

        let title = "Aralıklı tekrar testi \(UUID().uuidString)"
        let now = Date()
        FlashcardReviewStore.saveDeck(title: title, questions: [("Soru", "Cevap")])
        guard let newCard = FlashcardReviewStore.allCards().first(where: { $0.deckTitle == title }) else {
            Issue.record("Yeni çalışma kartı saklanmadı.")
            return
        }

        FlashcardReviewStore.review(id: newCard.id, remembered: true, now: now)
        let firstReview = FlashcardReviewStore.allCards().first(where: { $0.id == newCard.id })
        #expect(firstReview?.intervalDays == 1)
        #expect(firstReview.map { $0.dueAt > now } ?? false)
        #expect(!FlashcardReviewStore.dueCards(now: now).contains(where: { $0.id == newCard.id }))

        FlashcardReviewStore.review(id: newCard.id, remembered: true, now: now.addingTimeInterval(86_400))
        let secondReview = FlashcardReviewStore.allCards().first(where: { $0.id == newCard.id })
        #expect(secondReview?.intervalDays == 3)
    }

    @Test func aiTopicResponsesAreCachedLocally() {
        let previousCache = AIContentCache.backupData()
        let previousLibrary = AIContentCache.libraryBackupData()
        defer { AIContentCache.restore(previousCache) }
        defer { AIContentCache.restoreLibrary(previousLibrary) }

        let prompt = "cache test \(UUID().uuidString)"
        AIContentCache.save("saklanan içerik", for: prompt)
        #expect(AIContentCache.response(for: prompt) == "saklanan içerik")
        #expect(AIContentCache.response(for: prompt, now: Date().addingTimeInterval(31 * 24 * 60 * 60)) == nil)

        AIContentCache.saveToLibrary(title: "Test konusu", kind: "Konu özeti", text: "Önceki özet")
        #expect(AIContentCache.savedContent().contains { $0.title == "Test konusu" && $0.text == "Önceki özet" })
    }
}
