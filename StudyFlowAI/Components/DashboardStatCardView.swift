//
//  DashboardStatCardView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 15.07.2026.
//

import SwiftUI

struct DashboardStatCardView: View {

    let title: String
    let value: String
    let icon: String

    var body: some View {

        VStack(spacing: 10) {

            Image(systemName: icon)
                .font(.title)

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
