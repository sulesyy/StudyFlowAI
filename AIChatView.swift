//
//  AIChatView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 20.07.2026.
//

import SwiftUI

struct AIChatView: View {

    let pdfText: String

    @State private var messages: [ChatMessage] = []

    @State private var currentMessage = ""

    @State private var isLoading = false

    var body: some View {

        VStack {

            ScrollViewReader { proxy in

                ScrollView {

                    LazyVStack(spacing: 15) {

                        ForEach(messages) { message in

                            HStack {

                                if message.isUser {

                                    Spacer()

                                    Text(message.text)
                                        .padding()
                                        .foregroundStyle(.white)
                                        .background(Color.blue)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 18)
                                        )

                                } else {

                                    Text(message.text)
                                        .padding()
                                        .background(Color(.systemGray5))
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 18)
                                        )

                                    Spacer()

                                }

                            }
                            .id(message.id)

                        }

                        if isLoading {

                            ProgressView("AI düşünüyor...")

                        }

                    }
                    .padding()

                }
                .onChange(of: messages.count) { _, _ in

                    if let last = messages.last {

                        withAnimation {

                            proxy.scrollTo(last.id)

                        }

                    }

                }

            }
            Divider()

            HStack {

                TextField(
                    "PDF hakkında soru sor...",
                    text: $currentMessage,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)

                Button {

                    Task {

                        let question = currentMessage.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )

                        guard !question.isEmpty else { return }

                        messages.append(
                            ChatMessage(
                                text: question,
                                isUser: true
                            )
                        )

                        currentMessage = ""

                        isLoading = true

                        do {

                            let answer = try await AIService.shared.askPDF(
                                question: question,
                                pdfText: pdfText,
                                history: messages
                            )

                            messages.append(
                                ChatMessage(
                                    text: answer,
                                    isUser: false
                                )
                            )

                        } catch {

                            messages.append(
                                ChatMessage(
                                    text: error.localizedDescription,
                                    isUser: false
                                )
                            )

                        }

                        isLoading = false

                    }

                } label: {

                    Image(systemName: "paperplane.fill")
                        .font(.title2)

                }

            }
            .padding()

        }
        .navigationTitle("🤖 AI Chat")

    }

}
#Preview {

    NavigationStack {

        AIChatView(
            pdfText: "Örnek PDF metni"
        )

    }

}
