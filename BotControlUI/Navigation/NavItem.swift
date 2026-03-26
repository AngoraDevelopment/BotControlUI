//
//  NavItem.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/19/26.
//

import SwiftUI

struct NavItem: View {
    let title: String
    let icon: String
    let route: SidebarRoute

    @Binding var selection: SidebarRoute
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.accent,
                                    AppTheme.accent.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3)
                        .shadow(color: AppTheme.accent.opacity(0.6), radius: 6)
                } else {
                    Color.clear
                        .frame(width: 3)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 18)

                Text(title)

                Spacer()
            }
            .padding(10)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
            .padding(.leading, 6)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: hovering)
        .onHover { hovering = $0 }
        .onTapGesture {
            selection = route
        }
    }

    private var isSelected: Bool {
        selection == route
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.accent.opacity(0.15),
                            AppTheme.accent.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
        } else if hovering {
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.panelBackgroundSoft)
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.clear)
        }
    }

    private var foreground: Color {
        isSelected ? AppTheme.textPrimary : AppTheme.textSecondary
    }
}

#Preview {
    VStack(spacing: 10) {
        NavItem(
            title: "Chat",
            icon: "message",
            route: .chat,
            selection: .constant(.chat)
        )

        NavItem(
            title: "Resumen",
            icon: "chart.bar",
            route: .summary,
            selection: .constant(.chat)
        )

        NavItem(
            title: "Habilidades",
            icon: "bolt",
            route: .skills,
            selection: .constant(.chat)
        )
    }
    .padding()
    .frame(width: 260)
    .background(AppTheme.sidebarBackground)
}
