import Foundation

public enum StreamingChatCompletionParser {
  private struct StreamingResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
      let delta: Delta
    }

    struct Delta: Decodable {
      let content: String?
    }
  }

  public static func delta(fromSSELine line: String) -> String? {
    guard line.hasPrefix("data:") else {
      return nil
    }

    let payload = line
      .dropFirst("data:".count)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !payload.isEmpty, payload != "[DONE]" else {
      return nil
    }

    guard
      let data = payload.data(using: .utf8),
      let decoded = try? JSONDecoder().decode(StreamingResponse.self, from: data)
    else {
      return nil
    }

    return decoded.choices.first?.delta.content
  }
}
