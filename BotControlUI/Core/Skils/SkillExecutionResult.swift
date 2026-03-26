//
//  SkillExecutionResult.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/23/26.
//

import Foundation

struct SkillExecutionResult: Codable {
    let tool: String
    let action: String
    let ok: Bool
    let summary: String
    let rawData: String
}
