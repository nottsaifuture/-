import Foundation

enum CleanStyle: String, CaseIterable {
    case spoken = "口語"
    case written = "書面語"

    var instruction: String {
        switch self {
        case .spoken: return "保留講者原本用嘅語言同口吻；講廣東話就寫返廣東話口語，講英文就寫英文"
        case .written: return "將廣東話口語改寫成通順嘅書面中文；講英文就寫正式英文"
        }
    }
}

enum Gemini {
    // 撞到免費額度上限可以改做 "gemini-3.5-flash-lite"
    static let model = "gemini-3.8-flash"

    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func clean(_ text: String, style: CleanStyle) async throws -> String {
        guard let promptURL = Bundle.main.url(forResource: "prompt", withExtension: "md"),
              let template = try? String(contentsOf: promptURL, encoding: .utf8) else {
            throw Failure(message: "搵唔到 prompt.md")
        }
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(Secrets.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": template.replacingOccurrences(of: "{{STYLE}}", with: style.instruction)]]],
            "contents": [["role": "user", "parts": [["text": "<transcript>\n\(text)\n</transcript>"]]]],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Failure(message: "Gemini 回應睇唔明")
        }
        if let error = json["error"] as? [String: Any] {
            throw Failure(message: "Gemini 出錯：\(error["message"] as? String ?? "")")
        }
        guard let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw Failure(message: "Gemini 冇俾到結果")
        }
        return parts
            .filter { ($0["thought"] as? Bool) != true }
            .compactMap { $0["text"] as? String }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
