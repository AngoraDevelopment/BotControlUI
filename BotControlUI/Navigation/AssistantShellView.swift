//
//  AssistantShellView.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/19/26.
//

import SwiftUI
internal import Combine

import SwiftUI

struct AssistantShellView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var botManager = BotProcessManager()
    @StateObject private var skillRuntimeManager = SkillRuntimeProcessManager()
    @StateObject private var configStore = AppConfigStore()
    @State private var needsSetup = false

    var body: some View {
        Group {
            if needsSetup {
                SetupView {
                    needsSetup = false
                }
            } else {
                mainShell
            }
        }
        .onAppear {
            botManager.setConfigStore(configStore)
            needsSetup = shouldShowSetup()

            
        }
    }

    private var mainShell: some View {
        HStack(spacing: 0) {
            SidebarView(
                selection: $appViewModel.selectedRoute,
                botManager: botManager,
                skillRuntimeManager: skillRuntimeManager
            )

            VStack(spacing: 0) {
                TopBarView(selection: appViewModel.selectedRoute)

                Group {
                    switch appViewModel.selectedRoute {
                    case .chat:
                        ChatView(configStore: configStore)
                    case .summary:
                        SummaryView(
                            botManager: botManager,
                            skillRuntimeManager: skillRuntimeManager
                        )
                    case .channels:
                        ChannelsView(configStore: configStore)
                    case .agent:
                        AgentFilesView(configStore: configStore)
                    case .skills:
                        SkillsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.shellBackground)
            }
        }
        .frame(minWidth: 1160, minHeight: 760)
        .background(AppTheme.shellBackground)
        .preferredColorScheme(.dark)
    }

    private func shouldShowSetup() -> Bool {
        let path = "/Users/edgardoramos/telegram-ollama-bot/state/setup.json"

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let completed = json["completed"] as? Bool else {
            return true
        }

        return !completed
    }
}
#Preview {
    AssistantShellView()
}
