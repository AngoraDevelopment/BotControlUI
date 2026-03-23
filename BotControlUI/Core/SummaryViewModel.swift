//
//  SummaryViewModel.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/20/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class SummaryViewModel: ObservableObject {
    @Published var profileName: String = "—"
    @Published var callName: String = "—"
    @Published var timezone: String = "—"
    @Published var language: String = "—"
    @Published var lastUpdated: String = "—"

    @Published var currentFocus: [String] = []
    @Published var recentTopics: [String] = []
    @Published var projects: [String] = []
    @Published var decisions: [String] = []
    @Published var lessons: [String] = []
    @Published var openLoops: [String] = []
    @Published var milestones: [String] = []

    @Published var profileText: String = ""
    @Published var summaryText: String = ""

    private let rootPath = "/Users/edgardoramos/telegram-ollama-bot"

    private var profilePath: String { "\(rootPath)/memory/profile.json" }
    private var summaryPath: String { "\(rootPath)/memory/summary.json" }
    private var recentPath: String { "\(rootPath)/memory/recent.json" }
    private var dailyDir: String { "\(rootPath)/memory/daily" }

    func reload() {
        loadProfile()
        loadSummary()
    }

    func recentSessionsPreview() -> [SessionPreview] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: recentPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messages = json["messages"] as? [[String: Any]] else {
            return []
        }

        let grouped = messages.suffix(8).compactMap { item -> SessionPreview? in
            let role = item["role"] as? String ?? "unknown"
            let content = (item["content"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let timestamp = item["timestamp"] as? String ?? ""
            guard !content.isEmpty else { return nil }

            let title = role == "user"
                ? String(content.prefix(50))
                : "Respuesta del assistant"

            return SessionPreview(
                title: title.isEmpty ? "Sin contenido" : title,
                detail: role == "user" ? "Usuario" : "Assistant",
                time: relativeTimeString(from: timestamp)
            )
        }

        return Array(grouped.reversed())
    }

    func recentDailyLogText() -> String {
        let file = latestDailyLogPath()
        guard let file else { return "No hay logs diarios todavía." }
        return (try? String(contentsOfFile: file, encoding: .utf8)) ?? "No se pudo leer el log diario."
    }

    private func loadProfile() {
        profileText = readText(profilePath)

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: profilePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        profileName = (json["botName"] as? String)?.nonEmpty ?? "—"
        callName = (json["userCallName"] as? String)?.nonEmpty ?? "—"
        timezone = (json["mainTimezone"] as? String)?.nonEmpty ?? "—"
        language = (json["mainLanguage"] as? String)?.nonEmpty ?? "—"
    }

    private func loadSummary() {
        summaryText = readText(summaryPath)

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: summaryPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        lastUpdated = (json["lastUpdated"] as? String)?.nonEmpty ?? "—"

        if let shortContext = json["shortContext"] as? [String: Any] {
            currentFocus = (shortContext["currentFocus"] as? [String]) ?? []
            recentTopics = (shortContext["recentTopics"] as? [String]) ?? []
        }

        if let longTerm = json["longTerm"] as? [String: Any] {
            projects = (longTerm["projects"] as? [String]) ?? []
            decisions = (longTerm["decisions"] as? [String]) ?? []
            lessons = (longTerm["lessons"] as? [String]) ?? []
            openLoops = (longTerm["openLoops"] as? [String]) ?? []
            milestones = (longTerm["milestones"] as? [String]) ?? []
        }
    }

    private func latestDailyLogPath() -> String? {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dailyDir) else {
            return nil
        }

        let markdowns = files.filter { $0.hasSuffix(".md") }.sorted()
        guard let last = markdowns.last else { return nil }
        return "\(dailyDir)/\(last)"
    }

    private func readText(_ path: String) -> String {
        (try? String(contentsOfFile: path, encoding: .utf8)) ?? "No se pudo leer el archivo."
    }

    private func relativeTimeString(from iso: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: iso) else { return "—" }

        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "ahora" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}

struct SessionPreview: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let time: String
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
