//
//  LocalSkillRouter.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/23/26.
//

import Foundation

enum LocalSkillRouter {
    static func handle(_ text: String) -> String? {
        if let result = MacSystemControlSkill.handle(text) {
            return result
        }

        return nil
    }
}
