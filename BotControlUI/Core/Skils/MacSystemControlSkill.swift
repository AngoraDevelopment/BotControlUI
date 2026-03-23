//
//  MacSystemControlSkill.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/23/26.
//


import Foundation
import AppKit

enum MacSystemControlSkill {
    private static let skillConfigPath = "/Users/edgardoramos/telegram-ollama-bot/skills/mac-system-control/config.json"

    static func isActive() -> Bool {
        SkillToggleService.readIsActive(at: skillConfigPath)
    }

    static func handle(_ text: String) -> String? {
        guard isActive() else { return nil }

        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if lower.hasPrefix("listar carpeta ") {
            let targetPath = String(text.dropFirst("listar carpeta ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return listDirectory(targetPath)
        }

        if lower.hasPrefix("abrir carpeta ") {
            let targetPath = String(text.dropFirst("abrir carpeta ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return openFolder(targetPath)
        }

        if lower.hasPrefix("revelar archivo ") {
            let targetPath = String(text.dropFirst("revelar archivo ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return revealInFinder(targetPath)
        }

        if lower.hasPrefix("buscar app ") {
            let appName = String(text.dropFirst("buscar app ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return findApp(appName)
        }

        if lower.hasPrefix("abrir app ") {
            let appName = String(text.dropFirst("abrir app ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return openApp(appName)
        }

        return nil
    }

    private static func loadConfig() -> [String: Any] {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: skillConfigPath)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return json
    }

    private static func allowedFolders() -> [String] {
        loadConfig()["allowedFolders"] as? [String] ?? []
    }

    private static func allowedApps() -> [String] {
        loadConfig()["allowedApps"] as? [String] ?? []
    }

    private static func isPathAllowed(_ path: String) -> Bool {
        let target = URL(fileURLWithPath: path).standardized.path
        return allowedFolders().contains { folder in
            let allowed = URL(fileURLWithPath: folder).standardized.path
            return target == allowed || target.hasPrefix(allowed + "/")
        }
    }

    private static func listDirectory(_ path: String) -> String {
        guard isPathAllowed(path) else { return "❌ Path not allowed." }

        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            return "❌ Path does not exist or is not a directory."
        }

        let items = (try? fm.contentsOfDirectory(atPath: path)) ?? []
        if items.isEmpty {
            return "📂 \(path)\n\n(vacía)"
        }

        let lines = items.prefix(30).map { "- \($0)" }.joined(separator: "\n")
        return "📂 \(path)\n\n\(lines)"
    }

    private static func openFolder(_ path: String) -> String {
        guard isPathAllowed(path) else { return "❌ Path not allowed." }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
        return "✅ Abierto: \(path)"
    }

    private static func revealInFinder(_ path: String) -> String {
        guard isPathAllowed(path) else { return "❌ Path not allowed." }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        return "✅ Revelado en Finder: \(path)"
    }

    private static func findApp(_ name: String) -> String {
        let appsPath = "/Applications"
        let items = (try? FileManager.default.contentsOfDirectory(atPath: appsPath)) ?? []
        let matches = items
            .filter { $0.lowercased().hasSuffix(".app") }
            .filter { $0.lowercased().contains(name.lowercased()) }
            .map { $0.replacingOccurrences(of: ".app", with: "") }

        if matches.isEmpty {
            return "No encontré apps para: \(name)"
        }

        return "Apps encontradas para \"\(name)\":\n\n" + matches.prefix(10).map { "- \($0)" }.joined(separator: "\n")
    }

    private static func openApp(_ name: String) -> String {
        guard allowedApps().contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else {
            return "❌ App not allowed."
        }

        let ok = NSWorkspace.shared.launchApplication(name)
        return ok ? "✅ Abierto: \(name)" : "❌ No se pudo abrir \(name)."
    }
}
