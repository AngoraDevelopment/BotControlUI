//
//  AgentViewModel.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/20/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class AgentViewModel: ObservableObject {
    @Published var primaryModel: String = ""
    @Published var fallbackInput: String = ""
    @Published var fallbackModels: [String] = []

    @Published var workspacePath: String = "/Users/edgardoramos/telegram-ollama-bot"
    @Published var installedModels: [OllamaInstalledModel] = []

    @Published var selectedFileName: String? = nil
    @Published var selectedFileContent: String = ""

    private let configStore: AppConfigStore

    let files: [(name: String, size: String, modified: String, path: String)] = [
        ("IDENTITY.md", "214 B", "3d ago", "/Users/edgardoramos/telegram-ollama-bot/persona/IDENTITY.md"),
        ("USER.md", "292 B", "3d ago", "/Users/edgardoramos/telegram-ollama-bot/persona/USER.md"),
        ("SOUL.md", "1.6 KB", "3d ago", "/Users/edgardoramos/telegram-ollama-bot/persona/SOUL.md"),
        ("MEMORY.md", "860 B", "3d ago", "/Users/edgardoramos/telegram-ollama-bot/persona/MEMORY.md")
    ]

    init(configStore: AppConfigStore) {
        self.configStore = configStore
        loadFromStore()
        refreshInstalledModels()
    }

    func loadFromStore() {
        primaryModel = configStore.config.ollama.primaryModel
        fallbackModels = configStore.config.ollama.fallbackModels
    }

    func saveModelConfig() {
        configStore.config.ollama.primaryModel = primaryModel
        configStore.config.ollama.fallbackModels = fallbackModels
        configStore.saveAll()
    }

    func addFallbackModel() {
        let trimmed = fallbackInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        fallbackModels.append(trimmed)
        fallbackInput = ""
        saveModelConfig()
    }

    func refreshInstalledModels() {
        installedModels = OllamaModelService.fetchInstalledModels()

        if primaryModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let first = installedModels.first {
            primaryModel = first.name
            saveModelConfig()
        }
    }

    func setPrimaryModel(_ model: String) {
        primaryModel = model
        saveModelConfig()
    }

    func selectFile(name: String, path: String) {
        selectedFileName = name
        selectedFileContent = (try? String(contentsOfFile: path, encoding: .utf8)) ?? "No se pudo leer el archivo."
    }
}
