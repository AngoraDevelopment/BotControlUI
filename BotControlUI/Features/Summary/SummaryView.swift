//
//  SummaryView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/19/26.
//

import SwiftUI

struct SummaryView: View {
    @ObservedObject var botManager: BotProcessManager
    @StateObject private var vm = SummaryViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                headerSection
                gatewayCard
                snapshotCard
                metricsRow
                recentSessionsSection
                attentionSection
                bottomPanels
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        .background(AppTheme.shellBackground)
        .onAppear {
            vm.reload()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Resumen")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Estado del bot, memoria resumida y lectura rápida de salud.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var gatewayCard: some View {
        summaryCard(
            title: "Acceso al assistant",
            subtitle: "Identidad base, idioma y configuración principal."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                infoField(label: "Nombre del bot", value: vm.profileName)
                infoField(label: "Cómo te llama", value: vm.callName)

                HStack(spacing: 14) {
                    infoField(label: "Timezone", value: vm.timezone)
                    infoField(label: "Idioma", value: vm.language)
                    infoField(label: "Última actualización", value: vm.lastUpdated)
                }

                HStack(spacing: 12) {
                    actionButton("Recargar") {
                        vm.reload()
                    }

                    actionButton(botManager.isRunning ? "Bot activo" : "Bot detenido", highlighted: botManager.isRunning) {
                    }
                    .disabled(true)

                    Spacer()

                    Text("Usa esta vista para vigilar el estado general del assistant.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var snapshotCard: some View {
        summaryCard(
            title: "Instantánea",
            subtitle: "Lectura rápida del estado actual y foco del assistant."
        ) {
            VStack(spacing: 16) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    statTile("Estado", value: botManager.isRunning ? "Correcto" : "Detenido", accent: botManager.isRunning ? AppTheme.greenStatus : AppTheme.redAccent)
                    statTile("Tiempo local", value: vm.timezone)
                    statTile("Foco actual", value: vm.currentFocus.first ?? "Sin foco")
                    statTile("Topics recientes", value: "\(vm.recentTopics.count)")
                }

                inlineNotice(
                    title: "Current Focus",
                    text: vm.currentFocus.isEmpty
                        ? "No hay foco actual resumido todavía."
                        : vm.currentFocus.joined(separator: " • ")
                )
            }
        }
    }

    private var metricsRow: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            metricCard(title: "PROYECTOS", value: "\(vm.projects.count)", detail: vm.projects.first ?? "Sin proyectos")
            metricCard(title: "DECISIONES", value: "\(vm.decisions.count)", detail: vm.decisions.first ?? "Sin decisiones")
            metricCard(title: "LECCIONES", value: "\(vm.lessons.count)", detail: vm.lessons.first ?? "Sin lecciones")
            metricCard(title: "PENDIENTES", value: "\(vm.openLoops.count)", detail: vm.openLoops.first ?? "Sin pendientes")
        }
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT SESSIONS")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(spacing: 10) {
                ForEach(vm.recentSessionsPreview()) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)

                            Text(session.detail)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Text(session.time)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.panelBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                    )
                }

                if vm.recentSessionsPreview().isEmpty {
                    emptyLine("No hay sesiones recientes todavía.")
                }
            }
        }
    }

    private var attentionSection: some View {
        summaryCard(title: "Attention") {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(attentionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(attentionSubtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.yellow.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.24), lineWidth: 1)
                    )
            )
        }
    }

    private var bottomPanels: some View {
        HStack(alignment: .top, spacing: 18) {
            largeLogPanel(
                title: "Event Log",
                text: vm.recentDailyLogText()
            )

            largeLogPanel(
                title: "Gateway Logs",
                text: botManager.logs.isEmpty ? "Sin logs todavía." : botManager.logs
            )
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var attentionTitle: String {
        if !vm.openLoops.isEmpty {
            return "Hay pendientes abiertos"
        }
        if !vm.lessons.isEmpty {
            return "Hay lecciones registradas"
        }
        return "El assistant está estable"
    }

    private var attentionSubtitle: String {
        if !vm.openLoops.isEmpty {
            return vm.openLoops.prefix(3).joined(separator: ", ")
        }
        if !vm.lessons.isEmpty {
            return vm.lessons.prefix(3).joined(separator: ", ")
        }
        return "No hay alertas relevantes en este momento."
    }

    private func summaryCard<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            content()
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

    private func infoField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.shellBackground.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statTile(_ title: String, value: String, accent: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textSecondary)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accent ?? AppTheme.textPrimary)
                .lineLimit(2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.shellBackground.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func metricCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(AppTheme.textSecondary)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(detail)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func inlineNotice(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.shellBackground.opacity(0.24))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func largeLogPanel(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            ScrollView {
                Text(text)
                    .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 420, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func emptyLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.panelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
    }

    private func actionButton(_ title: String, highlighted: Bool = false, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(highlighted ? AppTheme.textPrimary : AppTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(highlighted ? AppTheme.panelBackgroundSoft : AppTheme.shellBackground.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(highlighted ? AppTheme.borderStrong : AppTheme.border, lineWidth: 1)
                    )
            )
    }
}
