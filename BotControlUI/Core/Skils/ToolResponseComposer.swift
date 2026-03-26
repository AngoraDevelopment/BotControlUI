//
//  ToolResponseComposer.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/23/26.
//

import Foundation

enum ToolResponseComposer {
    static func compose(
        userText: String,
        toolResult: SkillExecutionResult,
        model: String,
        botRootPath: String
    ) async -> String {
        guard let url = URL(string: "http://127.0.0.1:11434/api/chat") else {
            return fallback(toolResult)
        }

        let systemPrompt = """
        Eres un asistente que redacta respuestas naturales usando resultados REALES de herramientas.

        Reglas:
        - Usa únicamente el resultado de la herramienta para responder.
        - No inventes archivos, rutas, apps ni datos no presentes.
        - Responde de forma natural, clara y útil.
        - Si la herramienta falló, explica el fallo claramente.
        - Si el resultado tiene muchos ítems, resume lo importante sin perder precisión.
        - Mantén la personalidad del assistant, pero no inventes nada.
        """

        let toolPayload = """
        USER REQUEST:
        \(userText)

        TOOL RESULT:
        \(toolResult.rawData)

        TOOL SUMMARY:
        \(toolResult.summary)

        TOOL NAME:
        \(toolResult.tool)

        ACTION:
        \(toolResult.action)
        """

        let payload: [String: Any] = [
            "model": normalizedModel(model),
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": toolPayload]
            ],
            "stream": false
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            return fallback(toolResult)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let message = json["message"] as? [String: Any],
                  let content = message["content"] as? String,
                  !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return fallback(toolResult)
            }

            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return fallback(toolResult)
        }
    }

    static func fallback(_ result: SkillExecutionResult) -> String {
        if result.ok {
            return result.summary
        } else {
            return "No pude completar esa acción. \(result.summary)"
        }
    }

    private static func normalizedModel(_ raw: String) -> String {
        raw.replacingOccurrences(of: "ollama/", with: "")
    }
}
