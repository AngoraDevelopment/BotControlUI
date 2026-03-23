//
//  SidebarView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/19/26.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarRoute
    @ObservedObject var botManager: BotProcessManager

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    navSection(
                        title: "CHAT",
                        items: [
                            ("Chat", "message", SidebarRoute.chat)
                        ]
                    )

                    navSection(
                        title: "CONTROL",
                        items: [
                            ("Resumen", "chart.bar", SidebarRoute.summary),
                            ("Canales", "link", SidebarRoute.channels)
                        ]
                    )

                    navSection(
                        title: "AGENTE",
                        items: [
                            ("Agentes", "folder", SidebarRoute.agent),
                            ("Habilidades", "bolt", SidebarRoute.skills)
                        ]
                    )

                    navSection(
                        title: "AJUSTES",
                        items: []
                    )

                    Divider()
                        .overlay(AppTheme.border)
                        .padding(.top, -6)

                    docsRow
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 20)
            }

            footer
        }
        .frame(width: 300)
        .background(AppTheme.sidebarBackground)
        .overlay(
            Rectangle()
                .fill(AppTheme.border)
                .frame(width: 1),
            alignment: .trailing
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.panelBackground)
                    .frame(width: 54, height: 54)

                Image(systemName: "ladybug.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppTheme.redAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("CONTROL")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(AppTheme.textSecondary)

                Text("AngoraDev")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.panelBackground)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Circle().stroke(AppTheme.borderStrong, lineWidth: 1)
                    )

                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private func navSection(title: String, items: [(String, String, SidebarRoute)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    NavItem(
                        title: item.0,
                        icon: item.1,
                        route: item.2,
                        selection: $selection
                    )
                }
            }
        }
    }

    private var docsRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "book.closed")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            Text("Docs")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().overlay(AppTheme.border)

            HStack(spacing: 14) {
                Text("VERSIÓN")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(AppTheme.textSecondary)

                Text("v2026.3.13")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Circle()
                    .fill(botManager.isRunning ? AppTheme.greenStatus : AppTheme.redAccent)
                    .frame(width: 16, height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(botManager.isRunning ? AppTheme.greenStatus.opacity(0.50) : AppTheme.redAccent.opacity(0.50), lineWidth: 5)
                    )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(AppTheme.panelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
            .padding(18)

            Button {
                botManager.toggle()
            } label: {
                HStack {
                    Image(systemName: botManager.isRunning ? "stop.fill" : "play.fill")
                    Text(botManager.isRunning ? "Apagar bot" : "Encender bot")
                    Spacer()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(botManager.isRunning ? AppTheme.redAccentSoft : AppTheme.panelBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    botManager.isRunning ? AppTheme.redAccentBorder : AppTheme.border,
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
    }
}
#Preview {
    SidebarView(
        selection: .constant(.chat),
        botManager: {
            let manager = BotProcessManager()
            manager.isRunning = true
            return manager
        }()
    )
    .frame(height: 600)
}
