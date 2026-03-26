//
//  ChatViewModel.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var draft: String = ""
    @Published var selectedChannel: ChatChannel = .app
    @Published var appMessages: [ChatMessage] = []
    @Published var telegramMessages: [ChatMessage] = []
    @Published var isThinking = false
    @Published var botName = "Nova"
    @Published var installedModels: [OllamaInstalledModel] = []
    @Published var currentModel: String = ""
    @Published var errorMessage: String = ""
    @Published var telegramUserID: String = "unknown"

    private let configStore: AppConfigStore
    private let selfImprovementStore = SelfImprovementStore()
    private let appMessagesKey = "mac_assistant_app_chat_messages"
    private let botRootPath = "/Users/edgardoramos/telegram-ollama-bot"

    init(configStore: AppConfigStore) {
        self.configStore = configStore
        self.currentModel = configStore.config.ollama.primaryModel
        self.telegramUserID = configStore.config.telegram.allowedUserID.isEmpty ? "unknown" : configStore.config.telegram.allowedUserID

        loadBotName()
        loadAppMessages()
        loadTelegramMirror()
        refreshInstalledModels()
    }

    var channelTitle: String {
        switch selectedChannel {
        case .app:
            return "main: AngoraDevUI"
        case .telegram:
            return "main: telegram:\(telegramUserID)"
        }
    }

    var messages: [ChatMessage] {
        switch selectedChannel {
        case .app:
            return appMessages
        case .telegram:
            return telegramMessages
        }
    }

    var isEmpty: Bool {
        messages.isEmpty
    }

    func selectChannel(_ channel: ChatChannel) {
        selectedChannel = channel
        if channel == .telegram {
            loadTelegramMirror()
        }
    }

    func refreshInstalledModels() {
        installedModels = OllamaModelService.fetchInstalledModels()

        if currentModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let first = installedModels.first {
            currentModel = first.name
            persistModelSelection()
        }
    }

    func setModel(_ model: String) {
        currentModel = model
        persistModelSelection()
    }

    func refreshTelegramMirror() {
        telegramUserID = configStore.config.telegram.allowedUserID.isEmpty ? "unknown" : configStore.config.telegram.allowedUserID
        loadTelegramMirror()
    }

    func sendCurrentDraft() async {
        guard selectedChannel == .app else { return }

        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = ""

        let userMessage = ChatMessage(role: .user, text: trimmed)
        appMessages.append(userMessage)
        saveAppMessages()

        draft = ""

        do {
            let skillResponse = try await SkillRuntimeClient.execute(from: trimmed)

            if skillResponse.matched, let skillResult = skillResponse.result {
                let naturalReply = await ToolResponseComposer.compose(
                    userText: trimmed,
                    toolResult: skillResult,
                    model: currentModel,
                    botRootPath: botRootPath
                )

                let assistantMessage = ChatMessage(role: .assistant, text: naturalReply)
                appMessages.append(assistantMessage)
                saveAppMessages()

                LastSkillExecutionStore.save(
                    skill: skillResponse.skill ?? skillResult.tool,
                    action: skillResult.action,
                    ok: skillResult.ok
                )

                await MemorySyncService.appendLocalTurn(
                    userText: trimmed,
                    assistantText: naturalReply
                )

                detectAndStoreCorrection(from: trimmed)
                return
            }
        } catch {
            print("Skill runtime not available: \(error.localizedDescription)")
        }

        isThinking = true

        do {
            let rawReply = try await OllamaChatService.send(
                model: currentModel,
                messages: appMessages,
                botRootPath: botRootPath,
                learnedBehaviorBlock: selfImprovementStore.promptBlock()
            )

            let reply = sanitizeAssistantReply(rawReply)

            let assistantMessage = ChatMessage(role: .assistant, text: reply)
            appMessages.append(assistantMessage)
            saveAppMessages()

            await MemorySyncService.appendLocalTurn(
                userText: trimmed,
                assistantText: reply
            )

            detectAndStoreCorrection(from: trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }

        isThinking = false
    }

    private func persistModelSelection() {
        configStore.config.ollama.primaryModel = currentModel
        configStore.saveConfig()
    }

    private func loadBotName() {
        let path = "\(botRootPath)/memory/profile.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let value = json["botName"] as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        botName = value
    }

    private func loadAppMessages() {
        guard let data = UserDefaults.standard.data(forKey: appMessagesKey) else {
            appMessages = []
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let decoded = try? decoder.decode([ChatMessage].self, from: data) {
            appMessages = decoded
        } else {
            appMessages = []
        }
    }

    private func saveAppMessages() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(appMessages) {
            UserDefaults.standard.set(data, forKey: appMessagesKey)
        }
    }

    private func loadTelegramMirror() {
        let userID = configStore.config.telegram.allowedUserID
        guard !userID.isEmpty else {
            telegramMessages = []
            return
        }

        let path = "\(botRootPath)/runtime/chats/telegram_\(userID).json"

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            telegramMessages = []
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let decoded = try? decoder.decode([ChatMessage].self, from: data) else {
            telegramMessages = []
            return
        }

        telegramMessages = decoded
    }

    private func sanitizeAssistantReply(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let bannedFragments = [
            "[End of Interactive Scenario]",
            "End of Interactive Scenario",
            "Interactive Scenario"
        ]

        for fragment in bannedFragments {
            cleaned = cleaned.replacingOccurrences(of: fragment, with: "")
        }

        let transcriptMarkers = [
            "**Jefe:**",
            "**Iris:**",
            "Usuario:",
            "Asistente:",
            "User:",
            "Assistant:"
        ]

        let transcriptCount = transcriptMarkers.reduce(0) { partial, marker in
            partial + (cleaned.contains(marker) ? 1 : 0)
        }

        if transcriptCount >= 2 {
            if let range = cleaned.range(of: "\n\n") {
                cleaned = String(cleaned[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return cleaned
    }

    private func detectAndStoreCorrection(from userText: String) {
        guard let learnedRule = extractCorrectionRule(from: userText) else { return }
        selfImprovementStore.addCorrection(
            sourceText: userText,
            learnedRule: learnedRule
        )
    }

    private func extractCorrectionRule(from text: String) -> String? {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let directPatterns: [(String, String)] = [
            ("no inventes", "No inventes información, escenarios ni conversaciones."),
            ("no hagas roleplay", "No hagas roleplay ni simules diálogos por cuenta propia."),
            ("sé más directo", "Sé más directo en las respuestas."),
            ("se mas directo", "Sé más directo en las respuestas."),
            ("sin rodeos", "Responde sin rodeos."),
            ("más corto", "Haz las respuestas más cortas."),
            ("mas corto", "Haz las respuestas más cortas."),
            ("más técnico", "Usa un estilo más técnico cuando respondas."),
            ("mas tecnico", "Usa un estilo más técnico cuando respondas."),
            ("no repitas", "No repitas innecesariamente lo que dijo el usuario."),
            ("no me hables como principiante", "No me trates como principiante salvo que yo lo pida."),
            ("dame pasos reales", "Cuando dé instrucciones, da pasos reales y concretos."),
            ("no inventes links", "No inventes enlaces ni recursos falsos.")
        ]

        for (needle, learnedRule) in directPatterns where lower.contains(needle) {
            return learnedRule
        }

        if lower.hasPrefix("prefiero que ") {
            let rule = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return "Preferencia del usuario: \(rule)"
        }

        if lower.hasPrefix("quiero que ") {
            let rule = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return "Preferencia del usuario: \(rule)"
        }

        if lower.contains("eso está mal") || lower.contains("eso esta mal") {
            return "Cuando el usuario marque algo como incorrecto, prioriza precisión y evita repetir ese error."
        }

        return nil
    }
}
