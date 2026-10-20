//
//  ChatMessage.swift
//  StudyFlowAI
//
//  Created by Şule Yılmaz on 20.07.2026.
//

import Foundation

struct ChatMessage: Identifiable {

    let id = UUID()

    let text: String

    let isUser: Bool

}
