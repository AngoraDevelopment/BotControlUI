//
//  SkillRuntimeClient.swift
//  BotControlUI
//
//  Created by Edgardo Ramos on 3/23/26.
//

import Foundation

struct SkillRuntimeResponse: Decodable {
    let matched: Bool
    let skill: String?
    let resolved: SkillResolvedPayload?
    let result: SkillExecutionResult?
}

struct SkillResolvedPayload: Decodable {
    let action: String?
}

enum SkillRuntimeClient {
    static func execute(from text: String) async throws -> SkillRuntimeResponse {
        guard let url = URL(string: "http://127.0.0.1:4872/skills/execute-from-text") else {
            throw NSError(domain: "SkillRuntimeClient", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid skill runtime URL"
            ])
        }

        let payload = ["text": text]
        let body = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "SkillRuntimeClient", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Skill runtime returned an invalid HTTP response."
            ])
        }

        let decoder = JSONDecoder()
        return try decoder.decode(SkillRuntimeResponse.self, from: data)
    }
}
