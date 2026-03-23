//
//  SkillItem.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/22/26.
//

import Foundation

struct SkillItem: Identifiable, Hashable {
    let id = UUID()
    let folderName: String
    let fileName: String
    let name: String
    let description: String
    let path: String
    let configPath: String
    let isActive: Bool
}
