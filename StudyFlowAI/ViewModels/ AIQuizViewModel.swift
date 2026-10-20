//
//   AIQuizViewModel.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import Foundation

@MainActor
final class AIQuizViewModel: ObservableObject {

    @Published var questions: [QuizQuestion] = []

    @Published var isLoading = false

    @Published var errorMessage = ""

    @Published var currentQuestion = 0

    @Published var selectedAnswer: Int? = nil

    @Published var showAnswer = false

    @Published var score = 0

    @Published var quizFinished = false

    func loadQuiz(topic: String) async {

        isLoading = true
        errorMessage = ""

        do {

            questions = try await AIService.shared.generateQuiz(for: topic)

        } catch {

            errorMessage = error.localizedDescription

        }

        isLoading = false

    }

    func checkAnswer() {

        guard let selected = selectedAnswer else { return }

        if selected == questions[currentQuestion].answer {

            score += 1

        }

        showAnswer = true

    }

    func nextQuestion() {

        selectedAnswer = nil
        showAnswer = false

        if currentQuestion < questions.count - 1 {

            currentQuestion += 1

        } else {

            quizFinished = true

        }

    }

    func restartQuiz() {

        currentQuestion = 0
        selectedAnswer = nil
        showAnswer = false
        score = 0
        quizFinished = false

    }

}
