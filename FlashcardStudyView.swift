//
//  FlashcardStudyView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 19.07.2026.
//

import SwiftUI

struct FlashcardStudyView: View {

    let flashcards: [Flashcard]

    @State private var currentIndex = 0

    var body: some View {

        VStack(spacing: 25) {

            Text("Kart \(currentIndex + 1) / \(flashcards.count)")
                .font(.headline)

            ProgressView(
                value: Double(currentIndex + 1),
                total: Double(max(flashcards.count, 1))
            )
            .padding(.horizontal)

            FlashcardRow(
                card: flashcards[currentIndex]
            )

            HStack {

                Button {

                    if currentIndex > 0 {

                        currentIndex -= 1

                    }

                } label: {

                    Label("Önceki", systemImage: "arrow.left")

                }
                .disabled(currentIndex == 0)

                Spacer()

                Button {

                    if currentIndex < flashcards.count - 1 {

                        currentIndex += 1

                    }

                } label: {

                    Label("Sonraki", systemImage: "arrow.right")

                }
                .disabled(currentIndex == flashcards.count - 1)

            }
            .padding(.horizontal)

            Spacer()

        }
        .padding()
        .navigationTitle("Flashcards")

    }

}

#Preview {

    NavigationStack {

        FlashcardStudyView(
            flashcards: [
                Flashcard(
                    question: "Pointer nedir?",
                    answer: "Bellek adresini tutar."
                ),
                Flashcard(
                    question: "Array nedir?",
                    answer: "Aynı tipte verileri tutar."
                )
            ]
        )

    }

}
