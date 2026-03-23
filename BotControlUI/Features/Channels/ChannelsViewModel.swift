//
//  ChannelsViewModel.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/20/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class ChannelsViewModel: ObservableObject {
    @Published var telegramConfigured = false
    @Published var telegramRunning = false
    @Published var telegramMode = "polling"
    @Published var lastStart = "—"
    @Published var lastProbe = "—"
    @Published var probeStatus = "No probe yet"

    @Published var telegramBotToken = ""
    @Published var allowedUserID = ""
    @Published var accountLabel = "Default"
    @Published var ackReaction = ""
    @Published var actionsText = ""
    @Published var allowFromItems: [String] = []

    @Published var isSaving = false
    @Published var isProbing = false
    @Published var botDisplayName = "—"
    @Published var botUsername = "—"
    @Published var validationMessage = "Aún no validado."
    
    @Published var isSendingTest = false
    @Published var lastSendStatus = "No test yet"
    @Published var lastSendMessage = ""

    private let configStore: AppConfigStore

    init(configStore: AppConfigStore) {
        self.configStore = configStore
        loadFromStore()
    }

    func loadFromStore() {
        telegramBotToken = configStore.telegramBotToken
        allowedUserID = configStore.config.telegram.allowedUserID
        accountLabel = configStore.config.telegram.accountLabel
        ackReaction = configStore.config.telegram.ackReaction
        actionsText = configStore.config.telegram.actionsText
        allowFromItems = configStore.config.telegram.allowFromItems

        telegramConfigured = !telegramBotToken.isEmpty && !allowedUserID.isEmpty
    }

    func saveToStore() {
        isSaving = true

        configStore.telegramBotToken = telegramBotToken
        configStore.config.telegram.allowedUserID = allowedUserID
        configStore.config.telegram.accountLabel = accountLabel
        configStore.config.telegram.ackReaction = ackReaction
        configStore.config.telegram.actionsText = actionsText
        configStore.config.telegram.allowFromItems = allowFromItems
        configStore.saveAll()

        telegramConfigured = !telegramBotToken.isEmpty && !allowedUserID.isEmpty
        isSaving = false
    }

    func addAllowItem() {
        allowFromItems.append("new-user-id")
    }

    func validateTelegram() async {
        let trimmedUserID = allowedUserID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUserID.isEmpty, Int64(trimmedUserID) != nil else {
            validationMessage = "Allow User ID no es válido."
            probeStatus = "User ID inválido"
            lastProbe = nowString()
            telegramRunning = false
            return
        }

        isProbing = true
        probeStatus = "Validando..."
        validationMessage = "Consultando Telegram..."
        lastProbe = nowString()

        do {
            let info = try await TelegramService.validateBotToken(telegramBotToken)

            botDisplayName = info.first_name
            botUsername = info.username.map { "@\($0)" } ?? "—"
            telegramConfigured = true
            telegramRunning = true
            probeStatus = "Probe ok"
            validationMessage = "Token válido y bot accesible."
        } catch {
            telegramRunning = false
            probeStatus = "Probe failed"
            validationMessage = error.localizedDescription
        }

        lastProbe = nowString()
        isProbing = false
    }

    private func nowString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    func sendTestMessage() async {
        isSendingTest = true
        lastSendStatus = "Sending..."
        lastSendMessage = ""

        do {
            try await TelegramService.sendTestMessage(
                token: telegramBotToken,
                userID: allowedUserID
            )

            lastSendStatus = "Success"
            lastSendMessage = "Mensaje enviado correctamente."
        } catch {
            lastSendStatus = "Failed"
            lastSendMessage = error.localizedDescription
        }

        isSendingTest = false
    }
}
