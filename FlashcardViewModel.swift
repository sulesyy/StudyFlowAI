//
//  FlashcardViewModel.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 18.07.2026.
//

import Foundation

@MainActor
final class FlashcardViewModel: ObservableObject {

    @Published var flashcards: [Flashcard] = []

    @Published var currentIndex = 0
    @Published var showAnswer = false

    @Published var isLoading = false
    @Published var errorMessage = ""

    func load(topic: String) async {

        isLoading = true
        errorMessage = ""

        do {

            flashcards = try await AIService.shared.generateFlashcards(for: topic)
            FlashcardReviewStore.saveDeck(
                title: topic,
                questions: flashcards.map { ($0.question, $0.answer) }
            )

        } catch {

            errorMessage = error.localizedDescription

        }

        isLoading = false

    }

    func flipCard() {

        showAnswer.toggle()

    }

    func nextCard() {

        guard currentIndex < flashcards.count - 1 else { return }

        currentIndex += 1
        showAnswer = false

    }

    func previousCard() {

        guard currentIndex > 0 else { return }

        currentIndex -= 1
        showAnswer = false

    }

}
