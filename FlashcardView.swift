//
//  FlashcardView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 18.07.2026.
//

import SwiftUI

struct FlashcardView: View {

    let topic: String

    @StateObject private var viewModel = FlashcardViewModel()

    var body: some View {

        VStack {

            if viewModel.isLoading {

                Spacer()

                ProgressView("🤖 Flashcard oluşturuluyor...")

                Spacer()

            }

            else if !viewModel.errorMessage.isEmpty {

                Spacer()

                Text(viewModel.errorMessage)
                    .foregroundStyle(.red)

                Spacer()

            }

            else if !viewModel.flashcards.isEmpty {

                let card = viewModel.flashcards[viewModel.currentIndex]

                VStack(spacing: 30) {

                    Text("Kart \(viewModel.currentIndex + 1) / \(viewModel.flashcards.count)")
                        .font(.headline)

                    ProgressView(
                        value: Double(viewModel.currentIndex + 1),
                        total: Double(viewModel.flashcards.count)
                    )

                    Button {

                        withAnimation(.easeInOut(duration: 0.5)) {

                            viewModel.flipCard()

                        }

                    } label: {

                        ZStack {

                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.blue.opacity(0.15))
                                .frame(height: 320)

                            VStack(spacing: 20) {

                                Image(systemName: viewModel.showAnswer ? "checkmark.circle.fill" : "questionmark.circle.fill")
                                    .font(.system(size: 45))
                                    .foregroundStyle(.blue)

                                Text(viewModel.showAnswer ? "Cevap" : "Soru")
                                    .font(.headline)

                                Text(
                                    viewModel.showAnswer
                                    ? card.answer
                                    : card.question
                                )
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .padding()

                                Text("Dokunarak çevir")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                            }

                        }

                    }
                    .buttonStyle(.plain)

                    HStack {

                        Button {

                            viewModel.previousCard()

                        } label: {

                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 40))

                        }
                        .disabled(viewModel.currentIndex == 0)

                        Spacer()

                        Button {

                            viewModel.nextCard()

                        } label: {

                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 40))

                        }
                        .disabled(
                            viewModel.currentIndex == viewModel.flashcards.count - 1
                        )

                    }

                }
                .padding()

            }

        }
        .navigationTitle("AI Flashcards")
        .task {

            if viewModel.flashcards.isEmpty {

                await viewModel.load(topic: topic)

            }

        }

    }

}

#Preview {

    NavigationStack {

        FlashcardView(topic: "Pointer")

    }

}
