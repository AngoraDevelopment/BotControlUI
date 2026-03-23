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

    private var isSelected: Bool {
        selection == route
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 22)
                .foregroundStyle(isSelected ? AppTheme.redAccent : AppTheme.textMuted)

            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture {
            selection = route
        }
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 15)
                .fill(AppTheme.redAccentSoft.opacity(0.50))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(AppTheme.redAccentBorder, lineWidth: 2)
                )
        } else if hovering {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.03))
        } else {
            Color.clear
        }
    }
}
#Preview {
    NavItem(
        title: "Home",
        icon: "house",
        route: .chat,
        selection: .constant(.chat)
    )
}
