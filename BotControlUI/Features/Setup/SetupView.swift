//
//  SetupView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import SwiftUI

struct SetupView: View {
    @StateObject private var vm = SetupViewModel()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppTheme.shellBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configura tu assistant")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Vamos a definir la identidad base del bot antes de usar el chat.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                formCard
            }
            .frame(maxWidth: 720)
            .padding(28)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            input("Nombre del bot", text: $vm.botName, placeholder: "Ej: Nova")
            input("Cómo quieres que te llame", text: $vm.userCallName, placeholder: "Ej: Jefe")
            input("Idioma principal", text: $vm.mainLanguage, placeholder: "Ej: español")

            VStack(alignment: .leading, spacing: 8) {
                Text("Cómo quieres que se comporte")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)

                TextEditor(text: $vm.assistantBehavior)
                    .font(.system(size: 14, weight: .medium))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(12)
                    .frame(minHeight: 170)
                    .background(inputBackground)
            }

            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.redAccent)
            }

            HStack {
                Spacer()

                Button {
                    Task {
                        do {
                            try vm.completeSetup()
                            onComplete()
                        } catch {
                            vm.errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    Text(vm.isSaving ? "Guardando..." : "Completar setup")
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.redAccent.opacity(0.8))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!vm.isComplete || vm.isSaving)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(AppTheme.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }

    private func input(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(inputBackground)
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppTheme.shellBackground.opacity(0.24))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}
