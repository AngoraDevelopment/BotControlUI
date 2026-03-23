//
//  ChatView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/19/26.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var vm: ChatViewModel

    init(configStore: AppConfigStore) {
        _vm = StateObject(wrappedValue: ChatViewModel(configStore: configStore))
    }

    var body: some View {
        VStack(spacing: 0) {
            topControls

            Divider()
                .overlay(AppTheme.border)
                .padding(.top, 18)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        if vm.isEmpty {
                            centerIntro
                                .padding(.top, 52)
                        } else {
                            messagesView
                                .padding(.top, 24)
                        }

                        if vm.selectedChannel == .app && vm.isThinking {
                            typingBubble
                        }

                        if !vm.errorMessage.isEmpty {
                            errorBubble(vm.errorMessage)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 22)
                }
                .onChange(of: vm.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: vm.isThinking) { _, _ in
                    scrollToBottom(proxy)
                }
                .onAppear {
                    scrollToBottom(proxy)
                }
            }

            composer
        }
        .padding(.horizontal, 26)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .background(AppTheme.shellBackground)
    }

    private var topControls: some View {
        HStack(spacing: 12) {
            sessionMenu
            modelMenu

            Spacer()

            HStack(spacing: 12) {
                squareIcon("arrow.clockwise") {
                    vm.refreshInstalledModels()
                    vm.refreshTelegramMirror()
                }

                dividerLine

                squareIcon("display", active: true) { }
                squareIcon("clock", active: true) { }
            }
        }
    }

    private var sessionMenu: some View {
        Menu {
            Button("main: AngoraDevUI") {
                vm.selectChannel(.app)
            }

            Button("main: telegram:\(vm.telegramUserID)") {
                vm.selectChannel(.telegram)
                vm.refreshTelegramMirror()
            }
        } label: {
            pillLabel(vm.channelTitle)
        }
        .buttonStyle(.plain)
    }

    private var modelMenu: some View {
        Menu {
            if vm.installedModels.isEmpty {
                Button("No models found") { }
            } else {
                ForEach(vm.installedModels) { model in
                    Button(model.name) {
                        vm.setModel(model.name)
                    }
                }
            }

            Divider()

            Button("Refresh installed models") {
                vm.refreshInstalledModels()
            }
        } label: {
            pillLabel(vm.currentModel.isEmpty ? "Select model" : vm.currentModel)
        }
        .buttonStyle(.plain)
        .disabled(vm.selectedChannel == .telegram)
    }

    private func pillLabel(_ text: String) -> some View {
        HStack(spacing: 10) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .frame(width: 350, height: 52)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func squareIcon(_ icon: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.panelBackground)
                    .frame(width: 46, height: 46)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(active ? AppTheme.redAccentBorder : AppTheme.border, lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(active ? AppTheme.redAccent : AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(AppTheme.border)
            .frame(width: 1, height: 24)
            .padding(.horizontal, 2)
    }

    private var centerIntro: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.panelBackground)
                    .frame(width: 54, height: 54)

                Image(systemName: "ladybug.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.redAccent)
            }

            Text(vm.botName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 8) {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.redAccent)

                Text(vm.selectedChannel == .app ? "Ready to chat" : "Telegram mirror")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.clear)
                    .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
            )

            Text(vm.selectedChannel == .app
                 ? "Type a message below · local session with Ollama"
                 : "Aquí verás reflejados los mensajes de Telegram")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var messagesView: some View {
        VStack(spacing: 14) {
            ForEach(vm.messages) { message in
                messageBubble(message)
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == .user

        return HStack {
            if isUser { Spacer(minLength: 70) }

            VStack(alignment: .leading, spacing: 6) {
                Text(isUser ? "Tú" : vm.botName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                Text(message.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isUser ? AppTheme.redAccentSoft.opacity(0.85) : AppTheme.panelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isUser ? AppTheme.redAccentBorder : AppTheme.border, lineWidth: 1)
                    )
            )
            .frame(maxWidth: 620, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer(minLength: 70) }
        }
        .id(message.id)
    }

    private var typingBubble: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.botName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                TypingDotsView()
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.panelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )

            Spacer(minLength: 70)
        }
    }

    private func errorBubble(_ text: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Error")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.redAccentSoft.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.redAccentBorder, lineWidth: 1)
                    )
            )

            Spacer(minLength: 70)
        }
    }

    private var composer: some View {
        VStack(spacing: 0) {
            TextField(
                vm.selectedChannel == .app
                ? "Message \(vm.botName) (Enter to send)"
                : "La sesión de Telegram es solo lectura por ahora",
                text: $vm.draft,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .disabled(vm.selectedChannel == .telegram)
            .onSubmit {
                Task {
                    await vm.sendCurrentDraft()
                }
            }

            Divider()
                .overlay(AppTheme.border)
                .padding(.top, 14)

            HStack(spacing: 12) {
                Image(systemName: "paperclip")
                    .foregroundStyle(AppTheme.textSecondary)

                Image(systemName: "mic")
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Image(systemName: "plus")
                    .foregroundStyle(AppTheme.textSecondary)

                Image(systemName: "arrow.down.to.line")
                    .foregroundStyle(AppTheme.textMuted)

                Button {
                    Task {
                        await vm.sendCurrentDraft()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.redAccent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(
                    vm.selectedChannel == .telegram ||
                    vm.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    vm.isThinking
                )
            }
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = vm.messages.last {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}
