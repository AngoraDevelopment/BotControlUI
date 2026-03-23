//
//  ChatMessage.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    var text: String
    let createdAt: Date

    init(id: UUID = UUID(), role: Role, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }

    enum Role: String, Codable {
        case user
        case assistant
    }
}
