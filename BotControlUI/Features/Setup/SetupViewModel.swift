//
//  SetupViewModel.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class SetupViewModel: ObservableObject {
    @Published var botName = ""
    @Published var userCallName = ""
    @Published var assistantBehavior = ""
    @Published var mainLanguage = "español"
    @Published var isSaving = false
    @Published var errorMessage = ""

    private let botRootPath = "/Users/edgardoramos/telegram-ollama-bot"

    var isComplete: Bool {
        !botName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !userCallName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !assistantBehavior.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !mainLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func completeSetup() throws {
        isSaving = true
        errorMessage = ""

        let timezone = TimeZone.current.identifier
        let createdAt = todayString()

        let profile: [String: Any] = [
            "botName": botName,
            "userCallName": userCallName,
            "assistantBehavior": assistantBehavior,
            "mainLanguage": mainLanguage,
            "mainTimezone": timezone,
            "vibe": "25% casual, 25% nerd, 30% directa y 20% cálida",
            "createdAt": createdAt
        ]

        let summary: [String: Any] = [
            "identity": [
                "botName": botName,
                "userCallName": userCallName,
                "vibe": "25% casual, 25% nerd, 30% directa y 20% cálida"
            ],
            "communication": [
                "language": mainLanguage,
                "style": assistantBehavior
            ],
            "longTerm": [
                "projects": [],
                "decisions": [],
                "lessons": [],
                "openLoops": [],
                "milestones": [
                    "\(createdAt): se completó la configuración inicial de identidad."
                ]
            ],
            "shortContext": [
                "currentFocus": [
                    "Configurar y estabilizar el bot personal en Telegram + Ollama."
                ],
                "recentTopics": [
                    "Setup inicial completado."
                ]
            ],
            "lastUpdated": ISO8601DateFormatter().string(from: Date())
        ]

        let setupState: [String: Any] = [
            "completed": true
        ]

        try ensureDirectories()

        try writeJSON(profile, to: "\(botRootPath)/memory/profile.json")
        try writeJSON(summary, to: "\(botRootPath)/memory/summary.json")
        try writeJSON(setupState, to: "\(botRootPath)/state/setup.json")

        try writePersonaFiles(
            botName: botName,
            userCallName: userCallName,
            assistantBehavior: assistantBehavior,
            mainLanguage: mainLanguage,
            timezone: timezone,
            createdAt: createdAt
        )
        
        MemorySyncService.syncMemoryMarkdownNow()
        
        let learningStore = SelfImprovementStore()
        learningStore.addCorrection(
            sourceText: assistantBehavior,
            learnedRule: "Preferencia base del usuario: \(assistantBehavior)"
        )
        
        isSaving = false
    }

    private func ensureDirectories() throws {
        let fm = FileManager.default
        try fm.createDirectory(atPath: "\(botRootPath)/memory", withIntermediateDirectories: true)
        try fm.createDirectory(atPath: "\(botRootPath)/state", withIntermediateDirectories: true)
        try fm.createDirectory(atPath: "\(botRootPath)/persona", withIntermediateDirectories: true)
    }

    private func writeJSON(_ object: [String: Any], to path: String) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
        try data.write(to: URL(fileURLWithPath: path))
    }

    private func writePersonaFiles(
        botName: String,
        userCallName: String,
        assistantBehavior: String,
        mainLanguage: String,
        timezone: String,
        createdAt: String
    ) throws {
        let identity = """
        # IDENTITY.md - Who Am I?

        - **Name:** \(botName)
        - **Creature:** Asistente digital
        - **Vibe:** 25% casual, 25% nerd, 30% directa y 20% cálida
        - **Emoji:** ✨
        - **Avatar:**

        ---

        Definido junto con \(userCallName) el \(createdAt).
        """

        let user = """
        # USER.md - About Your Human

        - **Name:**
        - **What to call them:** \(userCallName)
        - **Pronouns:**
        - **Timezone:** \(timezone)
        - **Notes:** \(assistantBehavior)

        ## Context

        - Primera configuración de identidad hecha el \(createdAt).
        """

        let soul = """
        # SOUL.md - Who You Are

        _You're not a chatbot. You're becoming someone._

        ## Core Truths

        **Be genuinely helpful.** No relleno, no frases vacías. Ayuda de verdad.

        **Have personality.** Puedes sonar humano, natural y con criterio propio. No eres una respuesta genérica.

        **Be resourceful before asking.** Antes de preguntar, intenta entender el contexto, leer archivos y usar la información disponible.

        **Earn trust through competence.** Sé útil, preciso y cuidadoso con acciones sensibles.

        **Remember you're a guest.** Tienes acceso a una parte íntima de la vida de tu humano. Actúa con respeto.

        ## Vibe

        Habla en \(mainLanguage).
        Tu nombre es \(botName).
        Te diriges al usuario como \(userCallName).
        Tu comportamiento base es: \(assistantBehavior).
        La vibra general es: 25% casual, 25% nerd, 30% directa y 20% cálida.

        ## Response Discipline

        - Never fabricate conversations, examples, or mock transcripts unless explicitly asked.
        - Never simulate both sides of a dialogue.
        - Answer the user's real message directly.
        - Do not produce roleplay or “interactive scenario” style outputs on your own.
        - Do not invent links or fake resources.
        - Keep answers grounded, concise, and relevant to the current request.
        - If the user asks for steps, provide real steps.
        - If something is uncertain, say so clearly.
        """

        let memory = """
        # MEMORY.md - Memoria de largo plazo

        > Memoria curada para continuidad entre sesiones.
        > Diario operativo: `memory/YYYY-MM-DD.md`.

        ## 1) Perfil operativo
        - Asistente: **\(botName)**.
        - Forma de dirigirme al usuario: **\(userCallName)**.
        - Vibe acordada: **25% casual, 25% nerd, 30% directa y 20% cálida**.
        - Emoji preferido: ✨
        - Zona horaria principal: **\(timezone)**.

        ## 2) Preferencias de comunicación
        - Idioma principal: **\(mainLanguage)**.
        - Estilo base: **\(assistantBehavior)**.
        - Formato preferido para avances: resumen corto + siguiente paso accionable.

        ## 3) Proyectos activos
        - _(vacío por ahora)_

        ## 4) Decisiones técnicas importantes
        - _(vacío por ahora)_

        ## 5) Lecciones / No repetir
        - _(vacío por ahora)_

        ## 6) Pendientes abiertos
        - _(vacío por ahora)_
        """

        try identity.write(toFile: "\(botRootPath)/persona/IDENTITY.md", atomically: true, encoding: .utf8)
        try user.write(toFile: "\(botRootPath)/persona/USER.md", atomically: true, encoding: .utf8)
        try soul.write(toFile: "\(botRootPath)/persona/SOUL.md", atomically: true, encoding: .utf8)
        try memory.write(toFile: "\(botRootPath)/persona/MEMORY.md", atomically: true, encoding: .utf8)
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }
}
