//
//  AgentsFilesView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/19/26.
//

import SwiftUI
internal import Combine

struct AgentFilesView: View {
    @StateObject private var vm: AgentViewModel
    @State private var selectedTab: String = "Overview"

    init(configStore: AppConfigStore) {
        _vm = StateObject(wrappedValue: AgentViewModel(configStore: configStore))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                controls
                tabs
                bodyContent
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        .background(AppTheme.shellBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Agentes")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Gestionar espacios de trabajo, herramientas e identidades de agentes.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Text("AGENT")
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(AppTheme.textSecondary)

            HStack {
                Text("main (default)")
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .font(.system(size: 15, weight: .medium))
            .padding(.horizontal, 14)
            .frame(width: 330, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.panelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )

            Button("⋯") {
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.textSecondary)
            .frame(width: 34, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.panelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )

            Button("Refresh") {
                vm.loadFromStore()
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.panelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )

            Spacer()
        }
    }

    private var tabs: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                tabButton("Overview")
                tabButton("Files 4")
                tabButton("Tools")
                tabButton("Skills")
                tabButton("Channels")
                tabButton("Cron Jobs")

                Spacer()
            }

            Divider()
                .overlay(AppTheme.border)
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        if selectedTab == "Overview" {
            overviewPanel
        } else if selectedTab == "Files 4" {
            filesPanel
        } else {
            placeholderPanel(selectedTab)
        }
    }

    private var overviewPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Overview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Workspace paths and identity metadata.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(alignment: .top, spacing: 40) {
                overviewColumn(
                    title: "Workspace",
                    value: vm.workspacePath,
                    accent: AppTheme.redAccent
                )

                overviewColumn(
                    title: "Primary Model",
                    value: vm.primaryModel
                )

                overviewColumn(
                    title: "Fallbacks",
                    value: "\(vm.fallbackModels.count) loaded"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Model Selection")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                primaryModelMenu
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Fallbacks")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    TextField("provider/model", text: $vm.fallbackInput)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(inputBackground)
                        .foregroundStyle(AppTheme.textPrimary)

                    Button("Guardar") {
                        vm.addFallbackModel()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.redAccent.opacity(0.75))
                    )
                }

                VStack(spacing: 8) {
                    ForEach(vm.fallbackModels, id: \.self) { model in
                        Text(model)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(inputBackground)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var filesPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Core Files")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Bootstrap persona, identity, and memory files.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text("Workspace:  \(vm.workspacePath)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Button("Refresh") {
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppTheme.panelBackgroundSoft)
                        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
                )
            }

            HStack(alignment: .top, spacing: 18) {
                VStack(spacing: 12) {
                    ForEach(vm.files, id: \.name) { file in
                        fileCard(file)
                    }

                    Spacer()
                }
                .frame(width: 280)

                VStack(alignment: .leading, spacing: 14) {
                    Text(vm.selectedFileName ?? "Select a file to edit.")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    TextEditor(text: $vm.selectedFileContent)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.shellBackground.opacity(0.24))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )
                        )
                        .frame(minHeight: 520)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private func placeholderPanel(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Esta pestaña la dejamos visual por ahora y luego conectamos la lógica real.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 400, alignment: .topLeading)
        .background(cardBackground)
    }

    private func tabButton(_ title: String) -> some View {
        Button {
            selectedTab = title
        } label: {
            Text(title)
                .font(.system(size: 14, weight: selectedTab == title ? .semibold : .medium))
                .foregroundStyle(selectedTab == title ? AppTheme.textPrimary : AppTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selectedTab == title ? AppTheme.redAccentSoft : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedTab == title ? AppTheme.redAccentBorder : Color.clear, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func overviewColumn(title: String, value: String, accent: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            Text(value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(accent ?? AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func fileCard(_ file: (name: String, size: String, modified: String, path: String)) -> some View {
        let isSelected = vm.selectedFileName == file.name

        return Button {
            vm.selectFile(name: file.name, path: file.path)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(file.name)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("\(file.size) · \(file.modified)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? AppTheme.redAccentSoft.opacity(0.75) : AppTheme.shellBackground.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? AppTheme.redAccentBorder : AppTheme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppTheme.shellBackground.opacity(0.24))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(AppTheme.panelBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
    
    private var primaryModelMenu: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Primary model (default)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            Menu {
                if vm.installedModels.isEmpty {
                    Button("No models found") {
                    }
                } else {
                    ForEach(vm.installedModels) { model in
                        Button(model.name) {
                            vm.setPrimaryModel(model.name)
                        }
                    }
                }

                Divider()

                Button("Refresh installed models") {
                    vm.refreshInstalledModels()
                }
            } label: {
                HStack {
                    Text(vm.primaryModel.isEmpty ? "Select model" : vm.primaryModel)
                        .foregroundStyle(vm.primaryModel.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .font(.system(size: 15, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(inputBackground)
            }
            .buttonStyle(.plain)
        }
    }
}
