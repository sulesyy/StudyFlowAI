//
//  AISummaryView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import SwiftUI

struct AISummaryView: View {

    let topic: String

    @StateObject private var viewModel = AIViewModel()

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                Text(topic)
                    .font(.largeTitle)
                    .bold()

                if viewModel.isLoading {
                    ProgressView("AI düşünüyor...")
                } else if !viewModel.errorMessage.isEmpty {
                    ContentUnavailableView {
                        Label("Özet oluşturulamadı", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(viewModel.errorMessage)
                    } actions: {
                        Button("Tekrar dene") {
                            Task { await viewModel.retrySummary(topic: topic) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Text(viewModel.summary)
                        .textSelection(.enabled)
                }

            }
            .padding()

        }
        .navigationTitle("AI Özeti")
        .task {

            await viewModel.generateSummary(topic: topic)

        }

    }

}

#Preview {

    NavigationStack {

        AISummaryView(topic: "Pointer")

    }

}
