//
//  AppViewModel.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/19/26.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedRoute: SidebarRoute = .chat
}
