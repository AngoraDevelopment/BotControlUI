//
//  SummaryView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/19/26.
//

import SwiftUI

struct SummaryView: View {
    @ObservedObject var botManager: BotProcessManager
    @ObservedObject var skillRuntimeManager: SkillRuntimeProcessManager
    @State private var isOllamaConnected: Bool = false
    @State private var ollamaStatusText: String = "Desconocido"
    @State private var refreshTimer: Timer?
    @State private var activeSkillsCount: Int = 0
    @State private var memoryStatusText: String = "Desconocida"
    @State private var sessionsCount: Int = 0
    @State private var currentModelText: String = "Sin modelo"
    @State private var lastSkillExecution: LastSkillExecutionRecord?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                systemStatusRow
                lastSkillExecutionCard
                processControlsCard
                botLogsCard
                gatewayLogsCard
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        .background(AppTheme.shellBackground)
        .onAppear {
            checkOllamaStatus()
            loadActiveSkillsCount()
            loadMemoryStatus()
            loadSessionsCount()
            loadCurrentModel()
            loadLastSkillExecution()

            refreshTimer?.invalidate()
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                checkOllamaStatus()
                loadActiveSkillsCount()
                loadMemoryStatus()
                loadSessionsCount()
                loadCurrentModel()
                loadLastSkillExecution()
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Resumen")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Estado general del bot, runtime y salida de logs.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var botLogsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bot Logs")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Salida actual del proceso del bot.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Circle()
                        .fill(botManager.isRunning ? AppTheme.greenStatus : AppTheme.redAccent)
                        .frame(width: 10, height: 10)

                    Text(botManager.statusText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            ScrollView {
                Text(botManager.shortLogPreview)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
            .frame(minHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.shellBackground.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
    
    private var processControlsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("System Controls")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Gestiona los procesos principales del assistant desde aquí.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(alignment: .top, spacing: 16) {
                processTile(
                    title: "Telegram Bot",
                    subtitle: "Controla el proceso principal que responde en Telegram.",
                    isRunning: botManager.isRunning,
                    statusText: botManager.statusText,
                    activeLabel: "Activo",
                    inactiveLabel: "Detenido",
                    primaryTitle: botManager.isRunning ? "Apagar bot" : "Encender bot",
                    primarySystemImage: botManager.isRunning ? "stop.fill" : "play.fill",
                    onPrimary: {
                        botManager.toggle()
                    },
                    secondaryTitle: "Reiniciar",
                    secondarySystemImage: "arrow.clockwise",
                    onSecondary: {
                        if botManager.isRunning {
                            botManager.stop()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                botManager.start()
                            }
                        } else {
                            botManager.start()
                        }
                    }
                )

                processTile(
                    title: "Skill Runtime Gateway",
                    subtitle: "Mantiene activo el runtime que descubre y ejecuta skills.",
                    isRunning: skillRuntimeManager.isRunning,
                    statusText: skillRuntimeManager.statusText,
                    activeLabel: "Gateway activo",
                    inactiveLabel: "Gateway detenido",
                    primaryTitle: skillRuntimeManager.isRunning ? "Apagar gateway" : "Encender gateway",
                    primarySystemImage: skillRuntimeManager.isRunning ? "stop.circle.fill" : "bolt.circle.fill",
                    onPrimary: {
                        skillRuntimeManager.toggle()
                    },
                    secondaryTitle: "Reiniciar",
                    secondarySystemImage: "arrow.clockwise",
                    onSecondary: {
                        if skillRuntimeManager.isRunning {
                            skillRuntimeManager.stop()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                skillRuntimeManager.start()
                            }
                        } else {
                            skillRuntimeManager.start()
                        }
                    }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
    
    private var gatewayLogsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gateway Logs")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Estado y salida del skill runtime.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Circle()
                        .fill(skillRuntimeManager.isRunning ? AppTheme.greenStatus : AppTheme.redAccent)
                        .frame(width: 10, height: 10)

                    Text(skillRuntimeManager.statusText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            ScrollView {
                Text(skillRuntimeManager.shortLogPreview)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
            .frame(minHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.shellBackground.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
    
    private var systemStatusRow: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                statusKPI(
                    title: "Bot",
                    value: botManager.isRunning ? "Activo" : "Detenido",
                    isPositive: botManager.isRunning,
                    systemImage: "paperplane.fill"
                )

                statusKPI(
                    title: "Gateway",
                    value: skillRuntimeManager.isRunning ? "Activo" : "Detenido",
                    isPositive: skillRuntimeManager.isRunning,
                    systemImage: "bolt.horizontal.fill"
                )

                statusKPI(
                    title: "Ollama",
                    value: ollamaStatusText,
                    isPositive: isOllamaConnected,
                    systemImage: "cpu.fill"
                )

                statusKPI(
                    title: "Modelo",
                    value: currentModelText,
                    isPositive: !currentModelText.isEmpty && currentModelText != "Sin modelo",
                    systemImage: "cube.fill"
                )
            }

            HStack(spacing: 14) {
                statusKPI(
                    title: "Skills activas",
                    value: "\(activeSkillsCount)",
                    isPositive: activeSkillsCount > 0,
                    systemImage: "bolt.badge.a.fill"
                )

                statusKPI(
                    title: "Memoria",
                    value: memoryStatusText,
                    isPositive: memoryStatusText == "Cargada",
                    systemImage: "brain.head.profile"
                )

                statusKPI(
                    title: "Sesiones",
                    value: "\(sessionsCount)",
                    isPositive: sessionsCount > 0,
                    systemImage: "bubble.left.and.bubble.right.fill"
                )
            }
        }
    }
    
    private func statusKPI(
        title: String,
        value: String,
        isPositive: Bool,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Circle()
                    .fill(isPositive ? AppTheme.greenStatus : AppTheme.redAccent)
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
    
    private var lastSkillExecutionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Última Skill Ejecutada")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("La última herramienta real que usó el assistant.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                if let lastSkillExecution {
                    Circle()
                        .fill(lastSkillExecution.ok ? AppTheme.greenStatus : AppTheme.redAccent)
                        .frame(width: 10, height: 10)
                }
            }

            if let lastSkillExecution {
                VStack(alignment: .leading, spacing: 10) {
                    executionRow(label: "Skill", value: lastSkillExecution.skill)
                    executionRow(label: "Acción", value: lastSkillExecution.action)
                    executionRow(label: "Estado", value: lastSkillExecution.ok ? "OK" : "Error")
                    executionRow(label: "Timestamp", value: lastSkillExecution.timestamp)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppTheme.shellBackground.opacity(0.24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
            } else {
                Text("Todavía no se ha ejecutado ninguna skill.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppTheme.shellBackground.opacity(0.24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
    
    // MARK: Funciones
    
    private func checkOllamaStatus() {
        guard let url = URL(string: "http://127.0.0.1:11434/api/tags") else {
            ollamaStatusText = "Error URL"
            isOllamaConnected = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    ollamaStatusText = "Offline"
                    isOllamaConnected = false
                    return
                }

                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    ollamaStatusText = "Conectado"
                    isOllamaConnected = true
                } else {
                    ollamaStatusText = "Offline"
                    isOllamaConnected = false
                }
            }
        }.resume()
    }
    
    private func controlButton(
        title: String,
        systemImage: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isActive ? AppTheme.redAccentSoft : AppTheme.panelBackgroundSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isActive ? AppTheme.redAccentBorder : AppTheme.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func processTile(
        title: String,
        subtitle: String,
        isRunning: Bool,
        statusText: String,
        activeLabel: String,
        inactiveLabel: String,
        primaryTitle: String,
        primarySystemImage: String,
        onPrimary: @escaping () -> Void,
        secondaryTitle: String,
        secondarySystemImage: String,
        onSecondary: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Circle()
                    .fill(isRunning ? AppTheme.greenStatus : AppTheme.redAccent)
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)
            }

            HStack(spacing: 8) {
                statusCapsule(
                    text: isRunning ? activeLabel : inactiveLabel,
                    isPositive: isRunning
                )

                statusCapsule(
                    text: statusText,
                    isPositive: isRunning
                )
            }

            HStack(spacing: 10) {
                dashboardControlButton(
                    title: primaryTitle,
                    systemImage: primarySystemImage,
                    isPrimaryActive: isRunning,
                    action: onPrimary
                )

                dashboardSecondaryButton(
                    title: secondaryTitle,
                    systemImage: secondarySystemImage,
                    action: onSecondary
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.shellBackground.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
    private func dashboardControlButton(
        title: String,
        systemImage: String,
        isPrimaryActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isPrimaryActive ? AppTheme.redAccentSoft : AppTheme.panelBackgroundSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isPrimaryActive ? AppTheme.redAccentBorder : AppTheme.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func dashboardSecondaryButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.panelBackgroundSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    private func statusCapsule(text: String, isPositive: Bool) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isPositive ? AppTheme.greenStatus : AppTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppTheme.panelBackgroundSoft)
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
    }
    private func loadActiveSkillsCount() {
        let skillsPath = "/Users/edgardoramos/telegram-ollama-bot/skills"
        let fm = FileManager.default

        guard let folders = try? fm.contentsOfDirectory(atPath: skillsPath) else {
            activeSkillsCount = 0
            return
        }

        var count = 0

        for folder in folders {
            let configPath = "\(skillsPath)/\(folder)/config.json"

            guard fm.fileExists(atPath: configPath),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let isActive = json["isActive"] as? Bool,
                  isActive else {
                continue
            }

            count += 1
        }

        activeSkillsCount = count
    }
    private func loadMemoryStatus() {
        let memoryPath = "/Users/edgardoramos/telegram-ollama-bot/persona/MEMORY.md"
        let summaryPath = "/Users/edgardoramos/telegram-ollama-bot/memory/summary.json"

        let fm = FileManager.default
        let hasMemory = fm.fileExists(atPath: memoryPath)
        let hasSummary = fm.fileExists(atPath: summaryPath)

        if hasMemory && hasSummary {
            memoryStatusText = "Cargada"
        } else if hasMemory || hasSummary {
            memoryStatusText = "Parcial"
        } else {
            memoryStatusText = "Vacía"
        }
    }
    private func loadSessionsCount() {
        let telegramUserID = UserDefaults.standard.string(forKey: "last_known_telegram_user_id") ?? ""
        sessionsCount = telegramUserID.isEmpty ? 1 : 2
    }
    private func loadCurrentModel() {
        let defaultsKey = "mac_assistant_app_config"

        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ollama = json["ollama"] as? [String: Any],
              let model = ollama["primaryModel"] as? String,
              !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            currentModelText = "Sin modelo"
            return
        }

        currentModelText = model.replacingOccurrences(of: "ollama/", with: "")
    }
    private func loadLastSkillExecution() {
        lastSkillExecution = LastSkillExecutionStore.load()
    }
    private func executionRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .textSelection(.enabled)

            Spacer()
        }
    }
}
