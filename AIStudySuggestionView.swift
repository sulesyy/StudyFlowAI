//
//  AIStudySuggestionView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 18.07.2026.
//

import SwiftUI

struct AIStudySuggestionView: View {

    @State private var suggestion = ""
    @State private var isLoading = false

    var body: some View {

        GroupBox {

            VStack(alignment: .leading, spacing: 18) {

                HStack {

                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.yellow)

                    Text("Bugünün AI Tavsiyesi")
                        .font(.headline)

                }

                if isLoading {

                    HStack {

                        ProgressView()

                        Text("AI düşünüyor...")

                    }

                } else if suggestion.isEmpty {

                    Text("""
                    AI sana bugünkü çalışma planını hazırlasın.

                    • Hangi konu?
                    • Kaç dakika?
                    • Hangi sırayla?

                    Tek tuşla oluştur.
                    """)
                    .foregroundStyle(.secondary)

                } else {

                    Text(suggestion)
                        .textSelection(.enabled)

                }

                Button {

                    Task {

                        isLoading = true

                        do {

                            suggestion = try await AIService.shared.generateDailySuggestion()

                        } catch {

                            suggestion = error.localizedDescription

                        }

                        isLoading = false

                    }

                } label: {

                    Label(
                        "AI Tavsiyesi Oluştur",
                        systemImage: "brain.head.profile"
                    )
                    .frame(maxWidth: .infinity)

                }
                .buttonStyle(.borderedProminent)

            }

        }

    }

}

#Preview {

    AIStudySuggestionView()

}
