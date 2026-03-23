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
    var primaryModel: String = "ollama/qwen2.5:7b"
    var fallbackModels: [String] = ["ollama/qwen2.5:7b"]
}

struct AppConfig: Codable, Equatable {
    var telegram: TelegramConfig = .init()
    var ollama: OllamaConfig = .init()
}
