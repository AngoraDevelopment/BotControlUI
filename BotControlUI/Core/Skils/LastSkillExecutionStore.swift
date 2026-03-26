//
//  LastSkillExecutionStore.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/25/26.
//

import Foundation

struct LastSkillExecutionRecord: Codable {
    let skill: String
    let action: String
    let ok: Bool
    let timestamp: String
}

enum LastSkillExecutionStore {
    private static let filePath = "/Users/edgardoramos/telegram-ollama-bot/runtime/last_skill_execution.json"

    static func save(skill: String, action: String, ok: Bool) {
        let record = LastSkillExecutionRecord(
            skill: skill,
            action: action,
            ok: ok,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        guard let data = try? JSONEncoder().encode(record) else { return }

        let dir = "/Users/edgardoramos/telegram-ollama-bot/runtime"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? data.write(to: URL(fileURLWithPath: filePath))
    }

    static func load() -> LastSkillExecutionRecord? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
        return try? JSONDecoder().decode(LastSkillExecutionRecord.self, from: data)
    }
}
