//
//  StatisticsView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import SwiftUI
import Charts

struct StatisticsView: View {

    @ObservedObject var viewModel: StudyPlannerViewModel

    var totalTopics: Int {
        viewModel.courses.reduce(0) { $0 + $1.topics.count }
    }

    var completedTopics: Int {
        viewModel.courses.reduce(0) {
            $0 + $1.topics.filter { $0.isCompleted }.count
        }
    }

    var progress: Double {
        guard totalTopics > 0 else { return 0 }
        return Double(completedTopics) / Double(totalTopics)
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                // MARK: Genel Durum

                VStack(alignment: .leading, spacing: 15) {

                    Text("Genel Durum")
                        .font(.title2)
                        .bold()

                    StatRow(
                        title: "📚 Toplam Ders",
                        value: "\(viewModel.courses.count)"
                    )

                    StatRow(
                        title: "📖 Toplam Konu",
                        value: "\(totalTopics)"
                    )

                    StatRow(
                        title: "✅ Tamamlanan",
                        value: "\(completedTopics)"
                    )

                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // MARK: İlerleme

                VStack(alignment: .leading, spacing: 12) {

                    Text("Genel İlerleme")
                        .font(.title3)
                        .bold()

                    ProgressView(value: progress)

                    Text("%\(Int(progress * 100)) tamamlandı")
                        .foregroundStyle(.secondary)

                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // MARK: Konu Sayısı

                VStack(alignment: .leading) {

                    Text("Derslere Göre Konu Sayısı")
                        .font(.title3)
                        .bold()

                    Chart(viewModel.courses) { course in

                        BarMark(
                            x: .value("Ders", course.name),
                            y: .value("Konu", course.topics.count)
                        )

                    }
                    .frame(height: 220)

                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // MARK: Tamamlanan Konular

                VStack(alignment: .leading) {

                    Text("Tamamlanan Konular")
                        .font(.title3)
                        .bold()

                    Chart(viewModel.courses) { course in

                        let completed = course.topics.filter {
                            $0.isCompleted
                        }.count

                        BarMark(
                            x: .value("Ders", course.name),
                            y: .value("Tamamlanan", completed)
                        )

                    }
                    .frame(height: 220)

                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            }
            .padding()

        }
        .navigationTitle("İstatistikler")

    }
}

#Preview {
    StatisticsView(viewModel: StudyPlannerViewModel())
}
