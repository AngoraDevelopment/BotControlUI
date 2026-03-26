//
//  SkillsViewModel.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/22/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class SkillsViewModel: ObservableObject {
    @Published var skills: [SkillItem] = []
    @Published var searchText: String = ""

    let skillsDirectory = "/Users/edgardoramos/telegram-ollama-bot/skills"

    var filteredSkills: [SkillItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return skills }

        return skills.filter {
            $0.name.lowercased().contains(query) ||
            $0.description.lowercased().contains(query) ||
            $0.fileName.lowercased().contains(query) ||
            $0.folderName.lowercased().contains(query)
        }
    }

    init() {
        refresh()
    }

    func refresh() {
        ensureDirectoryExists()

        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: skillsDirectory) else {
            skills = []
            return
        }

        let directories = entries.sorted().filter {
            var isDir: ObjCBool = false
            let fullPath = "\(skillsDirectory)/\($0)"
            return fm.fileExists(atPath: fullPath, isDirectory: &isDir) && isDir.boolValue
        }

        skills = directories.compactMap { folderName in
            let folderPath = "\(skillsDirectory)/\(folderName)"
            let skillMarkdownPath = "\(folderPath)/SKILL.md"
            let configPath = "\(folderPath)/config.json"
            let executorPath = "\(folderPath)/executor.js"

            guard fm.fileExists(atPath: skillMarkdownPath) else { return nil }

            let content = (try? String(contentsOfFile: skillMarkdownPath, encoding: .utf8)) ?? ""
            let name = parseName(from: content, fallback: folderName)
            let description = parseDescription(from: content, fallback: "Sin descripción todavía.")
            let isActive = SkillToggleService.readIsActive(at: configPath)

            return SkillItem(
                folderName: folderName,
                fileName: "SKILL.md",
                name: name,
                description: description,
                path: folderPath,
                configPath: configPath,
                isActive: isActive,
                hasExecutor: fm.fileExists(atPath: executorPath),
                hasConfig: fm.fileExists(atPath: configPath),
                isReady: fm.fileExists(atPath: executorPath) && fm.fileExists(atPath: configPath) && fm.fileExists(atPath: skillMarkdownPath)
            )
        }
    }

    func toggle(_ skill: SkillItem, to newValue: Bool) {
        do {
            try SkillToggleService.setIsActive(at: skill.configPath, to: newValue)
            refresh()
        } catch {
            print("No se pudo cambiar isActive en \(skill.configPath): \(error)")
        }
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(
            atPath: skillsDirectory,
            withIntermediateDirectories: true
        )
    }

    private func parseName(from content: String, fallback: String) -> String {
        let lines = content.components(separatedBy: .newlines)

        if let yamlName = lines.first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("name:") }) {
            return yamlName
                .components(separatedBy: "name:")
                .dropFirst()
                .joined(separator: "name:")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let heading = lines.first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("# ") }) {
            return heading
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "# ", with: "")
        }

        return fallback
    }

    private func parseDescription(from content: String, fallback: String) -> String {
        let lines = content.components(separatedBy: .newlines)

        if let yamlDescription = lines.first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("description:") }) {
            return yamlDescription
                .components(separatedBy: "description:")
                .dropFirst()
                .joined(separator: "description:")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return fallback
    }
}
