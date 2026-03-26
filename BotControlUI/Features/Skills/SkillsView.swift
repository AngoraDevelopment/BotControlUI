//
//  SkillsView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/22/26.
//

import SwiftUI

struct SkillsView: View {
    @StateObject private var vm = SkillsViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                skillsCard
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        .background(AppTheme.shellBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Habilidades")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Gestionar disponibilidad de habilidades y leer skills instaladas.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var skillsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Skills")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Installed skills and their status.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Button("Refresh") {
                    vm.refresh()
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.panelBackgroundSoft)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
            }

            topControls

            Text("INSTALLED SKILLS")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(AppTheme.textSecondary)

            if vm.filteredSkills.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.filteredSkills) { skill in
                        skillRow(skill)
                    }
                }
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

    private var topControls: some View {
        HStack(spacing: 12) {
            HStack {
                TextField("Search skills", text: $vm.searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text("\(vm.filteredSkills.count) shown")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.shellBackground.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No hay skills todavía.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Cuando agregues carpetas de skills dentro de telegram-ollama-bot/skills, aparecerán aquí con su nombre, descripción y estado.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
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

    private func skillRow(_ skill: SkillItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(skill.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(skill.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(3)

                HStack(spacing: 10) {
                    capsuleLabel(skill.folderName, foreground: AppTheme.textSecondary)
                    capsuleLabel(skill.isActive ? "active" : "inactive",
                                 foreground: skill.isActive ? AppTheme.greenStatus : AppTheme.textSecondary)
                    capsuleLabel(skill.isReady ? "ready" : "incomplete",
                                 foreground: skill.isReady ? AppTheme.greenStatus : AppTheme.redAccent)
                }

                HStack(spacing: 8) {
                    miniFlag("SKILL.md", ok: true)
                    miniFlag("config", ok: skill.hasConfig)
                    miniFlag("executor", ok: skill.hasExecutor)
                }

                Text(skill.path)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { skill.isActive },
                set: { vm.toggle(skill, to: $0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.shellBackground.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func capsuleLabel(_ text: String, foreground: Color) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(foreground)
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

    private func miniFlag(_ label: String, ok: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ok ? AppTheme.greenStatus : AppTheme.redAccent)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
