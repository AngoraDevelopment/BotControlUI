//
//  MemorySyncService.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/22/26.
//

import Foundation

struct MemoryRecentStore: Codable {
    var messages: [MemoryRecentMessage]
    var turnsSinceLastSummary: Int
}

struct MemoryRecentMessage: Codable {
    let role: String
    let content: String
    let timestamp: String
}

struct MemorySummaryStore: Codable {
    struct Identity: Codable {
        var botName: String
        var userCallName: String
        var vibe: String
    }

    struct Communication: Codable {
        var language: String
        var style: String
    }

    struct LongTerm: Codable {
        var projects: [String]
        var decisions: [String]
        var lessons: [String]
        var openLoops: [String]
        var milestones: [String]
    }

    struct ShortContext: Codable {
        var currentFocus: [String]
        var recentTopics: [String]
    }

    var identity: Identity
    var communication: Communication
    var longTerm: LongTerm
    var shortContext: ShortContext
    var lastUpdated: String
}

enum MemorySyncService {
    static let botRootPath = "/Users/edgardoramos/telegram-ollama-bot"
    static let recentPath = "\(botRootPath)/memory/recent.json"
    static let summaryPath = "\(botRootPath)/memory/summary.json"
    static let profilePath = "\(botRootPath)/memory/profile.json"
    static let memoryMarkdownPath = "\(botRootPath)/persona/MEMORY.md"

    static let summaryTriggerEvery = 4
    static let maxRecentMessages = 16

    static func appendLocalTurn(userText: String, assistantText: String) async {
        var recent = loadRecent()

        recent.messages.append(
            MemoryRecentMessage(
                role: "user",
                content: userText,
                timestamp: nowISO()
            )
        )

        recent.messages.append(
            MemoryRecentMessage(
                role: "assistant",
                content: assistantText,
                timestamp: nowISO()
            )
        )

        recent.messages = Array(recent.messages.suffix(maxRecentMessages))
        recent.turnsSinceLastSummary += 1
        saveRecent(recent)

        if recent.turnsSinceLastSummary >= summaryTriggerEvery {
            await refreshSummaryAndMirror(from: recent)
        }
    }

    static func refreshSummaryAndMirror(from recent: MemoryRecentStore? = nil) async {
        let profile = loadProfileRaw()
        let currentSummary = loadSummary()
        let recentStore = recent ?? loadRecent()

        guard let updatedSummary = await buildUpdatedSummary(
            profileJSON: profile,
            currentSummary: currentSummary,
            recent: recentStore
        ) else {
            return
        }

        saveSummary(updatedSummary)
        syncMemoryMarkdown(profileJSON: profile, summary: updatedSummary)

        var resetRecent = recentStore
        resetRecent.turnsSinceLastSummary = 0
        saveRecent(resetRecent)
    }

    static func syncMemoryMarkdownNow() {
        let profile = loadProfileRaw()
        let summary = loadSummary()
        syncMemoryMarkdown(profileJSON: profile, summary: summary)
    }

    // MARK: - Summary generation

    private static func buildUpdatedSummary(
        profileJSON: [String: Any],
        currentSummary: MemorySummaryStore,
        recent: MemoryRecentStore
    ) async -> MemorySummaryStore? {
        guard let url = URL(string: "http://127.0.0.1:11434/api/chat") else { return nil }

        let model = loadPrimaryModel()

        let systemPrompt = """
        Eres un motor de memoria resumida.

        Tu trabajo es actualizar un JSON de memoria útil y compacta para un assistant personal.
        No guardes relleno ni charla trivial.

        Extrae solo cosas duraderas o relevantes:
        - proyectos activos
        - decisiones técnicas
        - lecciones / errores a no repetir
        - pendientes abiertos
        - hitos
        - foco actual
        - temas recientes

        Devuelve SOLO JSON válido con esta forma exacta:
        {
          "identity": { "botName": "", "userCallName": "", "vibe": "" },
          "communication": { "language": "", "style": "" },
          "longTerm": {
            "projects": [],
            "decisions": [],
            "lessons": [],
            "openLoops": [],
            "milestones": []
          },
          "shortContext": {
            "currentFocus": [],
            "recentTopics": []
          },
          "lastUpdated": ""
        }

        Mantén lo que siga siendo válido. Elimina lo obsoleto. Sé conciso.
        """

        let userPrompt = """
        PROFILE:
        \(jsonString(profileJSON))

        CURRENT SUMMARY:
        \(jsonString(currentSummary))

        RECENT MESSAGES:
        \(jsonString(recent))
        """

        let payload: [String: Any] = [
            "model": normalizedModel(model),
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "stream": false
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }

            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let message = json["message"] as? [String: Any],
                let content = message["content"] as? String,
                let parsed = parseFirstJSONObject(content),
                let parsedData = try? JSONSerialization.data(withJSONObject: parsed),
                var decoded = try? JSONDecoder().decode(MemorySummaryStore.self, from: parsedData)
            else {
                return nil
            }

            decoded.lastUpdated = nowISO()
            return decoded
        } catch {
            return nil
        }
    }

    // MARK: - Markdown mirror

    private static func syncMemoryMarkdown(profileJSON: [String: Any], summary: MemorySummaryStore) {
        let botName = stringValue(profileJSON["botName"], fallback: "Nova")
        let userCallName = stringValue(profileJSON["userCallName"], fallback: "Jefe")
        let mainLanguage = stringValue(profileJSON["mainLanguage"], fallback: "español")
        let mainTimezone = stringValue(profileJSON["mainTimezone"], fallback: TimeZone.current.identifier)
        let assistantBehavior = stringValue(profileJSON["assistantBehavior"], fallback: "directo, útil, humano y con personalidad")
        let vibe = stringValue(profileJSON["vibe"], fallback: "25% casual, 25% nerd, 30% directa y 20% cálida")

        let content = """
        # MEMORY.md - Memoria de largo plazo

        > Memoria curada para continuidad entre sesiones.
        > Diario operativo: `memory/YYYY-MM-DD.md`.

        ## 1) Perfil operativo
        - Asistente: **\(botName)**.
        - Forma de dirigirme al usuario: **\(userCallName)**.
        - Vibe acordada: **\(vibe)**.
        - Emoji preferido: ✨
        - Zona horaria principal: **\(mainTimezone)**.

        ## 2) Preferencias de comunicación
        - Idioma principal: **\(mainLanguage)**.
        - Estilo base: **\(assistantBehavior)**.
        - Formato preferido para avances: resumen corto + siguiente paso accionable.

        ## 3) Foco actual
        \(toMarkdownBullets(summary.shortContext.currentFocus))

        ## 4) Temas recientes
        \(toMarkdownBullets(summary.shortContext.recentTopics))

        ## 5) Proyectos activos
        \(toMarkdownBullets(summary.longTerm.projects))

        ## 6) Decisiones técnicas importantes
        \(toMarkdownBullets(summary.longTerm.decisions))

        ## 7) Lecciones / No repetir
        \(toMarkdownBullets(summary.longTerm.lessons))

        ## 8) Pendientes abiertos
        \(toMarkdownBullets(summary.longTerm.openLoops))

        ## 9) Hitos relevantes
        \(toMarkdownBullets(summary.longTerm.milestones))

        ## 10) Qué no guardar aquí
        - Logs diarios completos.
        - Conversaciones largas sin valor futuro.
        - Datos sensibles innecesarios.

        ## 11) Mantenimiento
        - Actualizar cuando haya decisiones, cambios de rumbo o lecciones reales.
        - Eliminar información obsoleta para mantener esta memoria corta y útil.

        ---

        _Last sync: \(summary.lastUpdated)_
        """

        try? content.write(toFile: memoryMarkdownPath, atomically: true, encoding: .utf8)
    }

    // MARK: - Storage

    private static func loadRecent() -> MemoryRecentStore {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: recentPath)),
            let decoded = try? JSONDecoder().decode(MemoryRecentStore.self, from: data)
        else {
            return MemoryRecentStore(messages: [], turnsSinceLastSummary: 0)
        }
        return decoded
    }

    private static func saveRecent(_ value: MemoryRecentStore) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: URL(fileURLWithPath: recentPath))
    }

    private static func loadSummary() -> MemorySummaryStore {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: summaryPath)),
            let decoded = try? JSONDecoder().decode(MemorySummaryStore.self, from: data)
        else {
            return MemorySummaryStore(
                identity: .init(botName: "Nova", userCallName: "Jefe", vibe: ""),
                communication: .init(language: "español", style: ""),
                longTerm: .init(projects: [], decisions: [], lessons: [], openLoops: [], milestones: []),
                shortContext: .init(currentFocus: [], recentTopics: []),
                lastUpdated: nowISO()
            )
        }
        return decoded
    }

    private static func saveSummary(_ value: MemorySummaryStore) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: URL(fileURLWithPath: summaryPath))
    }

    private static func loadProfileRaw() -> [String: Any] {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: profilePath)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return json
    }

    // MARK: - Helpers

    private static func loadPrimaryModel() -> String {
        let defaultsKey = "mac_assistant_app_config"

        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let ollama = json["ollama"] as? [String: Any],
            let model = ollama["primaryModel"] as? String,
            !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return "ollama/phi4-mini:latest"
        }

        return model
    }

    private static func normalizedModel(_ raw: String) -> String {
        raw.replacingOccurrences(of: "ollama/", with: "")
    }

    private static func toMarkdownBullets(_ items: [String]) -> String {
        let clean = items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if clean.isEmpty { return "- _(vacío por ahora)_" }
        return clean.map { "- \($0)" }.joined(separator: "\n")
    }

    private static func stringValue(_ any: Any?, fallback: String) -> String {
        guard let value = any as? String else { return fallback }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private static func nowISO() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static func jsonString<T: Encodable>(_ value: T) -> String {
        guard
            let data = try? JSONEncoder().encode(value),
            let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }

    private static func jsonString(_ value: [String: Any]) -> String {
        guard
            let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted]),
            let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }

    private static func parseFirstJSONObject(_ text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }

        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return nil
        }

        let candidate = String(text[start...end])
        guard let data = candidate.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json
    }
}
