//
//  AIResponse.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import Foundation

struct AIResponse: Codable {

    let candidates: [Candidate]

}

struct Candidate: Codable {

    let content: ContentResponse

}

struct ContentResponse: Codable {

    let parts: [PartResponse]

}

struct PartResponse: Codable {

    let text: String

}
