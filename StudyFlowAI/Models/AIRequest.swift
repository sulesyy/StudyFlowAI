//
//  AIRequest.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 16.07.2026.
//

import Foundation

struct AIRequest: Codable {

    let contents: [Content]

}

struct Content: Codable {

    let parts: [Part]

}

struct Part: Codable {

    let text: String

}
