//
//  AppConfig.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation

struct TelegramConfig: Codable, Equatable {
    var allowedUserID: String = ""
    var allowFromItems: [String] = []
    var accountLabel: String = "Default"
    var ackReaction: String = ""
    var actionsText: String = ""
}

struct OllamaConfig: Codable, Equatable {
    var primaryModel: String = "ollama/phi4-mini:latest"
    var fallbackModels: [String] = ["ollama/phi4-mini:latest"]
}

struct AppConfig: Codable, Equatable {
    var telegram: TelegramConfig = .init()
    var ollama: OllamaConfig = .init()
}
