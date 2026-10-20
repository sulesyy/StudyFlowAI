//
//  StudyTopic.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 12.07.2026.
//

import Foundation

struct StudyTopic: Identifiable, Codable {

    let id: UUID
    var title: String
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}
