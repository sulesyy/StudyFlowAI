//
//  AIQuizView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//
import SwiftUI

struct AIQuizView: View {

    let topic: String

    @StateObject private var viewModel = AIQuizViewModel()

    var body: some View {

        ScrollView {

            VStack(spacing: 25) {

                if viewModel.isLoading {

                    VStack(spacing: 20) {

                        ProgressView()
                            .scaleEffect(1.6)

                        Text("🤖 AI Quiz hazırlanıyor...")
                            .font(.headline)

                        Text("Bu işlem birkaç saniye sürebilir.")
                            .foregroundStyle(.secondary)

                    }
                    .padding(.top, 100)

                } else if !viewModel.errorMessage.isEmpty {

                    VStack(spacing: 20) {

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 55))
                            .foregroundStyle(.orange)

                        Text(viewModel.errorMessage)
                            .multilineTextAlignment(.center)

                        Button("Tekrar Dene") {

                            Task {
                                await viewModel.loadQuiz(topic: topic)
                            }

                        }
                        .buttonStyle(.borderedProminent)

                    }

                } else if viewModel.quizFinished {

                    VStack(spacing: 25) {

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)

                        Text("Quiz Tamamlandı")
                            .font(.largeTitle)
                            .bold()

                        Text("Puanın")
                            .foregroundStyle(.secondary)

                        Text("\(viewModel.score) / \(viewModel.questions.count)")
                            .font(.system(size: 55))
                            .bold()

                        Button("Tekrar Çöz") {

                            viewModel.restartQuiz()

                        }
                        .buttonStyle(.borderedProminent)

                    }
                    .padding(.top, 60)

                } else if !viewModel.questions.isEmpty {

                    let question = viewModel.questions[viewModel.currentQuestion]

                    VStack(alignment: .leading, spacing: 25) {

                        ProgressView(
                            value: Double(viewModel.currentQuestion + 1),
                            total: Double(viewModel.questions.count)
                        )
                        .tint(.blue)

                        Text("Soru \(viewModel.currentQuestion + 1) / \(viewModel.questions.count)")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 10) {

                            Text("Soru")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(question.question)
                                .font(.title3)
                                .bold()

                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                        ForEach(question.options.indices, id: \.self) { index in

                            Button {

                                guard !viewModel.showAnswer else { return }

                                viewModel.selectedAnswer = index

                            } label: {

                                HStack(spacing: 15) {

                                    ZStack {

                                        Circle()
                                            .fill(
                                                viewModel.selectedAnswer == index
                                                ? Color.blue
                                                : Color.gray.opacity(0.25)
                                            )
                                            .frame(width: 34, height: 34)

                                        Text(question.optionLetters[index])
                                            .bold()
                                            .foregroundStyle(
                                                viewModel.selectedAnswer == index
                                                ? .white
                                                : .primary
                                            )

                                    }

                                    Text(question.options[index])
                                        .foregroundStyle(.primary)

                                    Spacer()

                                }
                                .padding()
                                .background(
                                    backgroundColor(
                                        index: index,
                                        question: question
                                    )
                                )
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 16)
                                )

                            }
                            .buttonStyle(.plain)

                        }

                        if !viewModel.showAnswer {

                            Button("Kontrol Et") {

                                viewModel.checkAnswer()

                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.selectedAnswer == nil)

                        } else {

                            Button(
                                viewModel.currentQuestion == viewModel.questions.count - 1
                                ? "Sonucu Gör"
                                : "Sonraki Soru"
                            ) {

                                viewModel.nextQuestion()

                            }
                            .buttonStyle(.borderedProminent)

                        }

                    }

                }

            }
            .padding()

        }
        .navigationTitle("AI Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .task {

            if viewModel.questions.isEmpty {

                await viewModel.loadQuiz(topic: topic)

            }

        }

    }

    private func backgroundColor(
        index: Int,
        question: QuizQuestion
    ) -> Color {

        guard viewModel.showAnswer else {

            if viewModel.selectedAnswer == index {

                return .blue.opacity(0.18)

            }

            return .gray.opacity(0.08)

        }

        if index == question.answer {

            return .green.opacity(0.25)

        }

        if index == viewModel.selectedAnswer {

            return .red.opacity(0.25)

        }

        return .gray.opacity(0.08)

    }

}

#Preview {

    NavigationStack {

        AIQuizView(topic: "Pointer")

    }

}
