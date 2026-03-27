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
    @ObservedObject var skillRuntimeManager: SkillRuntimeProcessManager

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(AppTheme.border)
                .padding(.horizontal, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    navSection(
                        title: "CONTROL",
                        items: [
                            ("Resumen", "chart.bar", SidebarRoute.summary),
                            ("Canales", "link", SidebarRoute.channels)
                        ]
                    )
                    navSection(
                        title: "CHAT",
                        items: [
                            ("Chat", "message", SidebarRoute.chat)
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
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }

            footer
        }
        .frame(width: 280)
        .background(AppTheme.sidebarBackground)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            appLogo

            VStack(alignment: .leading, spacing: 3) {
                Text("OpenAsis Control")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Angora Dev Team")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var appLogo: some View {
        ZStack {
            Image(systemName: "apple.meditate.circle.fill")
                .symbolEffect(.breathe.pulse.byLayer, options: .repeat(.continuous))
                .font(Font.system(size: 32, weight: .regular))
            Circle()
                .stroke(AppTheme.accent.opacity(0.38), lineWidth: 1)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.accent.opacity(0.28),
                            AppTheme.accent.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
        }
        .shadow(color: AppTheme.accent.opacity(0.22), radius: 8, y: 4)
    }

    private func navSection(title: String, items: [(String, String, SidebarRoute)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(spacing: 10) {
                ForEach(items, id: \.0) { item in
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

    private var footer: some View {
        VStack(spacing: 12) {
            Divider()
                .overlay(AppTheme.border)

            VStack(spacing: 10) {
                statusCard(
                    title: "BOT",
                    versionOrStatus: botManager.isRunning ? "Activo" : "Detenido",
                    isRunning: botManager.isRunning
                )

                statusCard(
                    title: "RUNTIME",
                    versionOrStatus: skillRuntimeManager.isRunning ? "Gateway activo" : "Gateway detenido",
                    isRunning: skillRuntimeManager.isRunning
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
    }

    private func statusCard(title: String, versionOrStatus: String, isRunning: Bool) -> some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(AppTheme.textSecondary)
            
            Text(versionOrStatus)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            
            Spacer()
            
            Circle()
                .fill(isRunning ? AppTheme.greenStatus : AppTheme._redAccent)
                .frame(width: 14, height: 14)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
}

#Preview {
    SidebarView(
        selection: .constant(SidebarRoute.summary),
        botManager: {
            let manager = BotProcessManager()
            return manager
        }(),
        skillRuntimeManager: {
            let manager = SkillRuntimeProcessManager()
            return manager
        }()
    )
}
