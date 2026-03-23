//
//  ChannelsView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/20/26.
//

import SwiftUI

struct ChannelsView: View {
    @StateObject private var vm: ChannelsViewModel
    @State private var revealToken = false

    init(configStore: AppConfigStore) {
        _vm = StateObject(wrappedValue: ChannelsViewModel(configStore: configStore))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                telegramCard
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        .background(AppTheme.shellBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Canales")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Gestionar canales y ajustes.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var telegramCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Telegram")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Bot status and channel configuration.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        Task {
                            await vm.validateTelegram()
                        }
                    } label: {
                        Text(vm.isProbing ? "Probando..." : "Probar")
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
                    .buttonStyle(.plain)
                    .disabled(vm.isProbing)
                    
                    Button {
                        Task {
                            await vm.sendTestMessage()
                        }
                    } label: {
                        Text(vm.isSendingTest ? "Enviando..." : "Enviar prueba")
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
                    .buttonStyle(.plain)
                    .disabled(vm.isSendingTest)

                    Button {
                        vm.saveToStore()
                    } label: {
                        Text(vm.isSaving ? "Guardando..." : "Guardar")
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.redAccent.opacity(0.75))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isSaving)
                }
            }

            rowsOverview
            botInfoBlock
            tokenInput
            labeledInput("Allow User ID", text: $vm.allowedUserID, placeholder: "Ej: 123456789")

            dropdownRow(title: "Accounts", value: vm.accountLabel)

            VStack(alignment: .leading, spacing: 8) {
                Text("Ack Reaction")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)

                TextField("", text: $vm.ackReaction)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(inputSurface)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            dropdownRow(title: "Actions", value: vm.actionsText.isEmpty ? "" : vm.actionsText)

            allowFromBlock
        }
        .padding(20)
        .frame(maxWidth: 760, alignment: .leading)
        .background(cardBackground)
    }

    private var botInfoBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bot Info")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                infoLine("Display Name", vm.botDisplayName)
                infoLine("Username", vm.botUsername)
                infoLine("Validation", vm.validationMessage)
            }
            .padding(14)
            .background(inputSurface)
        }
    }

    private var sendTestBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Send Test Result")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                infoLine("Status", vm.lastSendStatus)
                infoLine("Message", vm.lastSendMessage.isEmpty ? "—" : vm.lastSendMessage)
            }
            .padding(14)
            .background(inputSurface)
        }
    }
    
    private func infoLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 110, alignment: .leading)

            Text(value)
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()
        }
        .font(.system(size: 13, weight: .medium))
    }

    private var tokenInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Telegram Token")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 10) {
                Group {
                    if revealToken {
                        TextField("Pega aquí el token del bot", text: $vm.telegramBotToken)
                    } else {
                        SecureField("Pega aquí el token del bot", text: $vm.telegramBotToken)
                    }
                }
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.textPrimary)

                Button {
                    revealToken.toggle()
                } label: {
                    Image(systemName: revealToken ? "eye.slash" : "eye")
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.04))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(inputSurface)
        }
    }

    private var rowsOverview: some View {
        VStack(spacing: 0) {
            overviewRow("Configured", value: vm.telegramConfigured ? "Yes" : "No")
            overviewRow("Running", value: vm.telegramRunning ? "Yes" : "No")
            overviewRow("Mode", value: vm.telegramMode)
            overviewRow("Last start", value: vm.lastStart)
            overviewRow("Last probe", value: vm.lastProbe)

            Text(vm.probeStatus)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.shellBackground.opacity(0.24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
                .padding(.top, 10)
        }
    }

    private var allowFromBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Allow From")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text("\(vm.allowFromItems.count) items")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(AppTheme.panelBackgroundSoft)
                    )

                Button {
                    vm.addAllowItem()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(AppTheme.panelBackgroundSoft)
                            .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.textPrimary)
            }

            VStack(spacing: 8) {
                if vm.allowFromItems.isEmpty {
                    Text("No hay IDs agregados todavía.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(inputSurface)
                } else {
                    ForEach(Array(vm.allowFromItems.enumerated()), id: \.offset) { _, item in
                        Text(item)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(inputSurface)
                    }
                }
            }
        }
    }

    private func overviewRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .font(.system(size: 15, weight: .medium))
        .padding(.vertical, 14)
        .overlay(Rectangle().fill(AppTheme.border).frame(height: 1), alignment: .bottom)
    }

    private func labeledInput(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(inputSurface)
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func dropdownRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            HStack {
                Text(value.isEmpty ? title : value)
                    .foregroundStyle(value.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .font(.system(size: 15, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(inputSurface)
        }
    }

    private var inputSurface: some View {
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
}
