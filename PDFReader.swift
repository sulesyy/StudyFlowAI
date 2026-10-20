//
//  PDFReader.swift
//  StudyFlowAI
//

import Foundation
import PDFKit
import UIKit
import Vision

struct PDFTextExtractionResult: Sendable {
    let text: String
    let scannedPagesRead: Int
}

enum PDFReader {

    static func extractText(from url: URL) async -> PDFTextExtractionResult {
        await Task.detached(priority: .userInitiated) {
            extractTextSynchronously(from: url)
        }.value
    }

    private static func extractTextSynchronously(from url: URL) -> PDFTextExtractionResult {
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let document = PDFDocument(url: url) else {
            return PDFTextExtractionResult(text: "", scannedPagesRead: 0)
        }

        var pages: [String] = []
        var scannedPagesRead = 0

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }

            if let selectableText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
               !selectableText.isEmpty {
                pages.append(selectableText)
                continue
            }

            if let recognizedText = recognizeText(in: page), !recognizedText.isEmpty {
                pages.append(recognizedText)
                scannedPagesRead += 1
            }
        }

        return PDFTextExtractionResult(
            text: pages.joined(separator: "\n\n"),
            scannedPagesRead: scannedPagesRead
        )
    }

    private static func recognizeText(in page: PDFPage) -> String? {
        let bounds = page.bounds(for: .mediaBox)
        let longestSide = max(bounds.width, bounds.height)
        guard longestSide > 0 else { return nil }

        // Keep OCR images legible while avoiding enormous allocations for oversized pages.
        let scale = min(2.0, 2_400 / longestSide)
        let targetSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let image = page.thumbnail(of: targetSize, for: .mediaBox)
        guard let cgImage = image.cgImage else { return nil }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.revision = VNRecognizeTextRequestRevision3

        let availableLanguages = (try? request.supportedRecognitionLanguages()) ?? []
        let preferredLanguages = ["tr-TR", "en-US"].filter(availableLanguages.contains)
        if !preferredLanguages.isEmpty {
            request.recognitionLanguages = preferredLanguages
        }

        do {
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
        } catch {
            return nil
        }

        return (request.results ?? [])
            .sorted {
                if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.015 {
                    return $0.boundingBox.midY > $1.boundingBox.midY
                }
                return $0.boundingBox.minX < $1.boundingBox.minX
            }
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
