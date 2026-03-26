//
//  AppConfigStore.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation
import SwiftUI
internal import Combine

struct RuntimeConfigFile: Codable {
    let telegramBotToken: String
    let allowedUserID: String
    let ollamaModel: String
    let ollamaUrl: String
    let ollamaFallbackModels: [String]
}

@MainActor
final class AppConfigStore: ObservableObject {
    @Published var config: AppConfig
    @Published var telegramBotToken: String

    private let defaultsKey = "bot_control_app_config"
    private let keychainService = "BotControlUI"
    private let keychainAccount = "telegram_bot_token"

    init() {
        let savedConfig = Self.loadConfig(defaultsKey: defaultsKey) ?? AppConfig()
        let savedToken = KeychainHelper.load(service: keychainService, account: keychainAccount)

        self.config = savedConfig
        self.telegramBotToken = savedToken
    }

    func saveAll() {
        saveConfig()
        saveToken()
        saveRuntimeConfigFile()
    }

    func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    func saveToken() {
        _ = KeychainHelper.save(
            service: keychainService,
            account: keychainAccount,
            value: telegramBotToken
        )
    }

    func botEnvironment() -> [String: String] {
        [
            "TELEGRAM_BOT_TOKEN": telegramBotToken,
            "ALLOWED_USER_ID": config.telegram.allowedUserID,
            "OLLAMA_MODEL": normalizedPrimaryModel(config.ollama.primaryModel),
            "OLLAMA_FALLBACK_MODELS": config.ollama.fallbackModels.joined(separator: ",")
        ]
    }

    private func normalizedPrimaryModel(_ raw: String) -> String {
        raw.replacingOccurrences(of: "ollama/", with: "")
    }

    private static func loadConfig(defaultsKey: String) -> AppConfig? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(AppConfig.self, from: data)
    }
    
    func saveRuntimeConfigFile() {
        let runtimeConfig = RuntimeConfigFile(
            telegramBotToken: telegramBotToken,
            allowedUserID: config.telegram.allowedUserID,
            ollamaModel: config.ollama.primaryModel,
            ollamaUrl: "http://127.0.0.1:11434/api/chat",
            ollamaFallbackModels: config.ollama.fallbackModels
        )

        let stateDirectory = "/Users/edgardoramos/telegram-ollama-bot/state"
        let filePath = "\(stateDirectory)/runtime-config.json"

        do {
            try FileManager.default.createDirectory(
                atPath: stateDirectory,
                withIntermediateDirectories: true
            )

            let data = try JSONEncoder().encode(runtimeConfig)
            try data.write(to: URL(fileURLWithPath: filePath))
        } catch {
            print("No se pudo guardar runtime-config.json: \(error.localizedDescription)")
        }
    }
}
