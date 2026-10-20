//
//  StudyTask.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 12.07.2026.
//

import Foundation

struct StudyTask: Identifiable, Codable {

    let id: UUID
    let date: Date
    let topicTitle: String

    init(
        id: UUID = UUID(),
        date: Date,
        topicTitle: String
    ) {
        self.id = id
        self.date = date
        self.topicTitle = topicTitle
    }
}
