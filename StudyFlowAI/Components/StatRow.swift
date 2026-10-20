//
//  StatRow.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import SwiftUI

struct StatRow: View {

    let title: String
    let value: String

    var body: some View {

        HStack {

            Text(title)

            Spacer()

            Text(value)
                .bold()

        }

    }

}
