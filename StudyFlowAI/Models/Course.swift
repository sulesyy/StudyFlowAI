//
//  Course.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 12.07.2026.
//

import Foundation

struct Course: Identifiable, Codable {

    let id: UUID
    var name: String
    var examDate: Date
    var difficulty: Int
    var topics: [StudyTopic]
    var studyTasks: [StudyTask]

    init(
        id: UUID = UUID(),
        name: String,
        examDate: Date,
        difficulty: Int,
        topics: [StudyTopic],
        studyTasks: [StudyTask] = []
    ) {
        self.id = id
        self.name = name
        self.examDate = examDate
        self.difficulty = difficulty
        self.topics = topics
        self.studyTasks = studyTasks
    }
}
