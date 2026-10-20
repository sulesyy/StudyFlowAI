//
//  ProgressSummaryView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 14.07.2026.
//

import SwiftUI

struct ProgressSummaryView: View {

    let completed: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text("İlerleme")
                .font(.headline)

            ProgressView(value: progress)

            Text("\(completed) / \(total) konu tamamlandı")
                .font(.caption)
                .foregroundStyle(.gray)

        }

    }

}

#Preview {
    ProgressSummaryView(completed: 2, total: 5)
}
