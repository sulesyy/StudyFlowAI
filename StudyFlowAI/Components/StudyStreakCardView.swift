//
//  StudyStreakCardView.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import SwiftUI

struct StudyStreakCardView: View {

    let streak: Int

    var body: some View {

        HStack {

            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            VStack(alignment: .leading) {

                Text("Study Streak")
                    .font(.headline)

                Text("\(streak) Gün")
                    .font(.title)
                    .bold()

                Text("Her gün en az bir konu tamamla.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Spacer()

        }
        .padding()
        .background(.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20))

    }

}
