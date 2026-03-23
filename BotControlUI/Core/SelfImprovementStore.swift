//
//  SelfImprovementStore.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/22/26.
//

import Foundation
internal import Combine

struct LearnedCorrection: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let sourceText: String
    let learnedRule: String

    init(id: UUID = UUID(), createdAt: Date = Date(), sourceText: String, learnedRule: String) {
        self.id = id
        self.createdAt = createdAt
        self.sourceText = sourceText
        self.learnedRule = learnedRule
    }
}

struct LearnedBehaviorRule: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let rule: String
    let evidenceCount: Int

    init(id: UUID = UUID(), createdAt: Date = Date(), rule: String, evidenceCount: Int = 1) {
        self.id = id
        self.createdAt = createdAt
        self.rule = rule
        self.evidenceCount = evidenceCount
    }
}

@MainActor
final class SelfImprovementStore: ObservableObject {
    @Published private(set) var corrections: [LearnedCorrection] = []
    @Published private(set) var behaviorRules: [LearnedBehaviorRule] = []

    private let botRootPath = "/Users/edgardoramos/telegram-ollama-bot"
    private var correctionsPath: String { "\(botRootPath)/memory/corrections.json" }
    private var rulesPath: String { "\(botRootPath)/memory/behavior_rules.json" }

    init() {
        ensureFiles()
        load()
    }

    func load() {
        corrections = loadFile([LearnedCorrection].self, path: correctionsPath) ?? []
        behaviorRules = loadFile([LearnedBehaviorRule].self, path: rulesPath) ?? []
    }

    func addCorrection(sourceText: String, learnedRule: String) {
        let normalized = learnedRule.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        let correction = LearnedCorrection(
            sourceText: sourceText,
            learnedRule: normalized
        )

        corrections.insert(correction, at: 0)
        corrections = Array(corrections.prefix(100))
        saveCorrections()

        promoteRuleIfNeeded(normalized)
    }

    func promptBlock() -> String {
        let latestCorrections = corrections.prefix(8).map(\.learnedRule)
        let stableRules = behaviorRules
            .sorted { $0.evidenceCount > $1.evidenceCount }
            .prefix(8)
            .map(\.rule)

        var lines: [String] = []

        if !stableRules.isEmpty {
            lines.append("# LEARNED BEHAVIOR RULES")
            for rule in stableRules {
                lines.append("- \(rule)")
            }
            lines.append("")
        }

        if !latestCorrections.isEmpty {
            lines.append("# RECENT CORRECTIONS")
            for rule in latestCorrections {
                lines.append("- \(rule)")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func promoteRuleIfNeeded(_ rule: String) {
        let matches = corrections.filter {
            normalizeRule($0.learnedRule) == normalizeRule(rule)
        }.count

        guard matches >= 2 else { return }

        if let idx = behaviorRules.firstIndex(where: { normalizeRule($0.rule) == normalizeRule(rule) }) {
            let existing = behaviorRules[idx]
            behaviorRules[idx] = LearnedBehaviorRule(
                id: existing.id,
                createdAt: existing.createdAt,
                rule: existing.rule,
                evidenceCount: existing.evidenceCount + 1
            )
        } else {
            behaviorRules.insert(
                LearnedBehaviorRule(rule: rule, evidenceCount: matches),
                at: 0
            )
        }

        behaviorRules = Array(behaviorRules.prefix(50))
        saveRules()
    }

    private func normalizeRule(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
    }

    private func ensureFiles() {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: "\(botRootPath)/memory", withIntermediateDirectories: true)

        if !fm.fileExists(atPath: correctionsPath) {
            let emptyCorrections: [LearnedCorrection] = []
            saveFile(emptyCorrections, path: correctionsPath)
        }

        if !fm.fileExists(atPath: rulesPath) {
            let emptyRules: [LearnedBehaviorRule] = []
            saveFile(emptyRules, path: rulesPath)
        }
    }

    private func saveCorrections() {
        saveFile(corrections, path: correctionsPath)
    }

    private func saveRules() {
        saveFile(behaviorRules, path: rulesPath)
    }

    private func saveFile<T: Encodable>(_ value: T, path: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: URL(fileURLWithPath: path))
    }

    private func loadFile<T: Decodable>(_ type: T.Type, path: String) -> T? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }
}
