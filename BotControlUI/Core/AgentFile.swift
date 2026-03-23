//
//  AgentFile.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/20/26.
//

import Foundation

enum AgentFile: String, CaseIterable, Identifiable {
    case identity = "IDENTITY.md"
    case user = "USER.md"
    case soul = "SOUL.md"
    case memory = "MEMORY.md"

    var id: String { rawValue }

    var title: String { rawValue }

    var path: String {
        "/Users/edgardoramos/telegram-ollama-bot/persona/\(rawValue)"
    }
}
