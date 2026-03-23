//
//  OllamaModelService.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation

struct OllamaInstalledModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

enum OllamaModelService {
    static func fetchInstalledModels() -> [OllamaInstalledModel] {
        let possiblePaths = [
            "/usr/local/bin/ollama",
            "/opt/homebrew/bin/ollama",
            "/usr/bin/env"
        ]

        for path in possiblePaths {
            if let models = runListCommand(at: path), !models.isEmpty {
                return models
            }
        }

        return []
    }

    private static func runListCommand(at executablePath: String) -> [OllamaInstalledModel]? {
        let process = Process()
        let pipe = Pipe()

        if executablePath == "/usr/bin/env" {
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = ["ollama", "list"]
        } else {
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = ["list"]
        }

        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
            return nil
        }

        return parseModels(from: text)
    }

    private static func parseModels(from output: String) -> [OllamaInstalledModel] {
        let lines = output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard lines.count > 1 else { return [] }

        let body = lines.dropFirst()

        let models = body.compactMap { line -> OllamaInstalledModel? in
            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard let first = parts.first else { return nil }
            return OllamaInstalledModel(name: "ollama/\(first)")
        }

        return models
    }
}
