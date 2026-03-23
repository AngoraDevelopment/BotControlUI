//
//  ChatChannel.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/21/26.
//

import Foundation

enum ChatChannel: String, CaseIterable, Identifiable {
    case app
    case telegram

    var id: String { rawValue }
}
