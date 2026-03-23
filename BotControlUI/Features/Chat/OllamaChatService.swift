//
//  OllamaChatService.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation

struct OllamaChatResponse: Decodable {
    struct Message: Decodable {
        let role: String
        let content: String
    }

    let message: Message?
}

enum OllamaChatService {
    static func send(
        model: String,
        messages: [ChatMessage],
        botRootPath: String,
        learnedBehaviorBlock: String
    ) async throws -> String {
        guard let url = URL(string: "http://127.0.0.1:11434/api/chat") else {
            throw NSError(domain: "OllamaChatService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No se pudo construir la URL de Ollama."
            ])
        }

        let systemPrompt = buildSystemPrompt(
            botRootPath: botRootPath,
            learnedBehaviorBlock: learnedBehaviorBlock
        )

        var payloadMessages: [[String: String]] = [
            [
                "role": "system",
                "content": systemPrompt
            ]
        ]

        payloadMessages += messages.map {
            [
                "role": $0.role == .user ? "user" : "assistant",
                "content": $0.text
            ]
        }

        let payload: [String: Any] = [
            "model": normalizedModel(model),
            "messages": payloadMessages,
            "stream": false
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "OllamaChatService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Respuesta inválida de Ollama."
            ])
        }

        guard (200...299).contains(http.statusCode) else {
            let raw = String(data: data, encoding: .utf8) ?? "Sin detalle"
            throw NSError(domain: "OllamaChatService", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Ollama devolvió HTTP \(http.statusCode): \(raw)"
            ])
        }

        let decoded = try JSONDecoder().decode(OllamaChatResponse.self, from: data)

        guard let text = decoded.message?.content.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw NSError(domain: "OllamaChatService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Ollama respondió sin contenido."
            ])
        }

        return text
    }

    private static func normalizedModel(_ raw: String) -> String {
        raw.replacingOccurrences(of: "ollama/", with: "")
    }

    private static func buildSystemPrompt(
        botRootPath: String,
        learnedBehaviorBlock: String
    ) -> String {
        let identity = read("\(botRootPath)/persona/IDENTITY.md")
        let user = read("\(botRootPath)/persona/USER.md")
        let soul = read("\(botRootPath)/persona/SOUL.md")
        let memory = read("\(botRootPath)/persona/MEMORY.md")
        let profile = read("\(botRootPath)/memory/profile.json")
        let summary = read("\(botRootPath)/memory/summary.json")

        return [
            soul,
            identity,
            user,
            memory,
            "# PROFILE JSON",
            profile,
            "# SUMMARY JSON",
            summary,
            learnedBehaviorBlock,
            """
            # OUTPUT RULES

            - Responde solo al último mensaje del usuario.
            - No inventes conversaciones pasadas, ejemplos ficticios ni escenarios interactivos.
            - No escribas diálogos tipo "Usuario:" / "Asistente:" a menos que el usuario lo pida explícitamente.
            - No hagas roleplay por tu cuenta.
            - No añadas "[End of Interactive Scenario]" ni textos parecidos.
            - No inventes enlaces.
            - No repitas la pregunta del usuario en formato transcript.
            - Sé natural, directa y útil.
            - Si el usuario pide pasos, da pasos reales y concretos.
            - Si no sabes algo, dilo claro.
            """
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: "\n\n---\n\n")
    }

    private static func read(_ path: String) -> String {
        (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
    }
}
