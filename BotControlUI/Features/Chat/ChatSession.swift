//
//  ChatSession.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation

struct ChatSession: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var messages: [ChatMessage]
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, messages: [ChatMessage] = [], updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.messages = messages
        self.updatedAt = updatedAt
    }
}
