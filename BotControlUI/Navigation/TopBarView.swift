//
//  TopBarView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/20/26.
//

import SwiftUI

struct TopBarView: View {
    let selection: SidebarRoute

    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 10) {
                Text("OpenClaw")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                Text("›")
                    .foregroundStyle(AppTheme.textMuted)

                Text(currentTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()

            HStack(spacing: 12) {
                searchPill

                HStack(spacing: 8) {
                    circleButton("display")
                    circleButton("sun.max")
                    circleButton("moon")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.panelBackground)
                        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
                )
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 14)
        .background(AppTheme.topbarBackground)
        .overlay(
            Rectangle().fill(AppTheme.border).frame(height: 1),
            alignment: .bottom
        )
    }

    private var currentTitle: String {
        switch selection {
        case .chat: return "Chat"
        case .summary: return "Resumen"
        case .channels: return "Canales"
        case .agent: return "Agentes"
        case .skills: return "Habilidades"
        }
    }

    private var searchPill: some View {
        HStack(spacing: 10) {
            Text("Search")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Text("⌘K")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.04))
                )
        }
        .padding(.horizontal, 16)
        .frame(width: 320, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func circleButton(_ icon: String) -> some View {
        Button {
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
