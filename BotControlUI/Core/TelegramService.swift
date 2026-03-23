//
//  TelegramService.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation
internal import Combine

struct TelegramBotInfo: Decodable {
    let id: Int
    let is_bot: Bool
    let first_name: String
    let username: String?
    let can_join_groups: Bool?
    let can_read_all_group_messages: Bool?
    let supports_inline_queries: Bool?
}

struct TelegramGetMeResponse: Decodable {
    let ok: Bool
    let result: TelegramBotInfo?
    let description: String?
}

enum TelegramValidationError: LocalizedError {
    case invalidURL
    case emptyToken
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "No se pudo construir la URL de Telegram."
        case .emptyToken:
            return "El token está vacío."
        case .invalidResponse:
            return "La respuesta de Telegram no fue válida."
        case .apiError(let message):
            return message
        }
    }
}

enum TelegramService {
    static func validateBotToken(_ token: String) async throws -> TelegramBotInfo {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TelegramValidationError.emptyToken
        }

        guard let url = URL(string: "https://api.telegram.org/bot\(trimmed)/getMe") else {
            throw TelegramValidationError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw TelegramValidationError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw TelegramValidationError.apiError("Telegram devolvió HTTP \(http.statusCode).")
        }

        let decoded = try JSONDecoder().decode(TelegramGetMeResponse.self, from: data)

        if decoded.ok, let result = decoded.result {
            return result
        } else {
            throw TelegramValidationError.apiError(decoded.description ?? "Telegram rechazó el token.")
        }
    }
}

struct TelegramSendMessageResponse: Decodable {
    let ok: Bool
    let description: String?
}

extension TelegramService {

    static func sendTestMessage(token: String, userID: String) async throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserID = userID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedToken.isEmpty else {
            throw TelegramValidationError.emptyToken
        }

        guard let chatID = Int64(trimmedUserID) else {
            throw TelegramValidationError.apiError("User ID inválido.")
        }

        guard let url = URL(string: "https://api.telegram.org/bot\(trimmedToken)/sendMessage") else {
            throw TelegramValidationError.invalidURL
        }

        let payload: [String: Any] = [
            "chat_id": chatID,
            "text": "✅ Conexión exitosa.\nEl bot está correctamente configurado desde tu app."
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TelegramValidationError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw TelegramValidationError.apiError("HTTP \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(TelegramSendMessageResponse.self, from: data)

        if !decoded.ok {
            throw TelegramValidationError.apiError(decoded.description ?? "Error enviando mensaje.")
        }
    }
}
