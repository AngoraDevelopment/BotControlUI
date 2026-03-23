//
//  AgentsFilesViewModel.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/20/26.
//

import Foundation
import SwiftUI
import AppKit
internal import Combine

@MainActor
final class AgentFilesViewModel: ObservableObject {
    @Published var selectedFile: AgentFile = .identity
    @Published var content: String = ""
    @Published var statusMessage: String = "Listo"
    @Published var hasUnsavedChanges = false

    private var lastLoadedContent: String = ""

    init() {
        loadSelectedFile()
    }

    func select(_ file: AgentFile) {
        if selectedFile == file { return }
        selectedFile = file
        loadSelectedFile()
    }

    func loadSelectedFile() {
        let path = selectedFile.path
        do {
            let text = try String(contentsOfFile: path, encoding: .utf8)
            content = text
            lastLoadedContent = text
            hasUnsavedChanges = false
            statusMessage = "Cargado: \(selectedFile.rawValue)"
        } catch {
            content = ""
            lastLoadedContent = ""
            hasUnsavedChanges = false
            statusMessage = "No se pudo leer \(selectedFile.rawValue)"
        }
    }

    func updateContent(_ newValue: String) {
        content = newValue
        hasUnsavedChanges = newValue != lastLoadedContent
    }

    func save() {
        do {
            try content.write(toFile: selectedFile.path, atomically: true, encoding: .utf8)
            lastLoadedContent = content
            hasUnsavedChanges = false
            statusMessage = "Guardado: \(selectedFile.rawValue)"
        } catch {
            statusMessage = "Error al guardar: \(error.localizedDescription)"
        }
    }

    func reload() {
        loadSelectedFile()
    }

    func openFolder() {
        let folder = URL(fileURLWithPath: "/Users/edgardoramos/telegram-ollama-bot/persona")
        NSWorkspace.shared.open(folder)
    }
}
