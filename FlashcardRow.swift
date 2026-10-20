//
//  FlashcardRow.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 19.07.2026.
//

import SwiftUI

struct FlashcardRow: View {

    let card: Flashcard

    @State private var flipped = false

    var body: some View {

        ZStack {

            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: flipped
                        ? [.green.opacity(0.8), .green]
                        : [.blue.opacity(0.8), .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 18) {

                Image(systemName:
                        flipped
                      ? "checkmark.circle.fill"
                      : "questionmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)

                Text(flipped ? "Cevap" : "Soru")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))

                Text(flipped ? card.answer : card.question)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Dokunarak Çevir")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

            }
            .padding()

        }
        .frame(height: 240)
        .rotation3DEffect(
            .degrees(flipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeInOut(duration: 0.6), value: flipped)
        .onTapGesture {

            flipped.toggle()

        }
        .shadow(radius: 8)

    }

}

#Preview {

    FlashcardRow(
        card: Flashcard(
            question: "Pointer nedir?",
            answer: "Bellek adresini tutan değişkendir."
        )
    )

}
