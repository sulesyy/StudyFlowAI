//
//  QuizQuestion.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import Foundation

struct QuizQuestion: Codable, Identifiable {

    let id = UUID()

    let question: String
    let options: [String]
    let answer: Int

    var optionLetters: [String] {
        ["A", "B", "C", "D"]
    }

    enum CodingKeys: String, CodingKey {
        case question
        case options
        case answer
    }
}
