//
//  Flashcard.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 18.07.2026.
//

import Foundation

struct Flashcard: Codable, Identifiable {

    let id = UUID()

    let question: String
    let answer: String

    enum CodingKeys: String, CodingKey {
        case question
        case answer
    }
}
