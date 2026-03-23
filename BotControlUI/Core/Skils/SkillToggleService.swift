//
//  SkillToggleService.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/23/26.
//

import Foundation

enum SkillToggleService {
    static func setIsActive(at configPath: String, to newValue: Bool) throws {
        let url = URL(fileURLWithPath: configPath)
        var content = try String(contentsOf: url, encoding: .utf8)

        let pattern = #"("isActive"\s*:\s*)(true|false)"#

        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(content.startIndex..<content.endIndex, in: content)

            if regex.firstMatch(in: content, options: [], range: range) != nil {
                content = regex.stringByReplacingMatches(
                    in: content,
                    options: [],
                    range: range,
                    withTemplate: "$1\(newValue ? "true" : "false")"
                )
            } else {
                if let braceIndex = content.firstIndex(of: "{") {
                    let insertion = "\n  \"isActive\": \(newValue ? "true" : "false"),"
                    content.insert(contentsOf: insertion, at: content.index(after: braceIndex))
                }
            }
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    static func readIsActive(at configPath: String) -> Bool {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let isActive = json["isActive"] as? Bool
        else {
            return false
        }

        return isActive
    }
}
