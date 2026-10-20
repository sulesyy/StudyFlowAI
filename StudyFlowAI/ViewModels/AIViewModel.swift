//
//  AIViewModel.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import Foundation

@MainActor
final class AIViewModel: ObservableObject {

    @Published var summary = ""
    @Published var isLoading = false
    @Published var errorMessage = ""

    func generateSummary(topic: String) async {

        isLoading = true
        errorMessage = ""

        do {

            summary = try await AIService.shared.generateSummary(for: topic)


        } catch {

            errorMessage = error.localizedDescription

        }

        isLoading = false

    }

    func retrySummary(topic: String) async {
        await generateSummary(topic: topic)
    }

}
