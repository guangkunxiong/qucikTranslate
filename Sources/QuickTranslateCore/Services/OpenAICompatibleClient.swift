import Foundation

public enum OpenAICompatibleClientError: Error, LocalizedError {
  case invalidResponse
  case missingAssistantContent
  case requestFailed(Int, String)

  public var errorDescription: String? {
    switch self {
    case .invalidResponse:
      "翻译服务返回了无效响应。"
    case .missingAssistantContent:
      "翻译服务没有返回译文内容。"
    case let .requestFailed(statusCode, body):
      "翻译请求失败，HTTP \(statusCode)：\(body)"
    }
  }
}

public final class OpenAICompatibleClient: Sendable {
  private let urlSession: URLSession

  public init(urlSession: URLSession = .shared) {
    self.urlSession = urlSession
  }

  public static func makeRequest(
    baseURL: URL,
    apiKey: String,
    model: String,
    systemPrompt: String,
    sourceText: String,
    stream: Bool = false,
    userContent: String? = nil
  ) throws -> URLRequest {
    let endpoint = baseURL
      .appendingPathComponent("chat")
      .appendingPathComponent("completions")

    let content = userContent ?? "翻译以下选中文本。只返回 JSON。\n\n\(sourceText)"
    let payload = ChatCompletionRequest(
      model: model,
      messages: [
        ChatMessage(role: "system", content: systemPrompt),
        ChatMessage(role: "user", content: content)
      ],
      temperature: 0.2,
      stream: stream ? true : nil
    )

    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(payload)
    return request
  }

  public func translate(
    sourceText: String,
    settings: AppSettings,
    apiKey: String
  ) async throws -> TranslationResult {
    let request = try Self.makeRequest(
      baseURL: settings.baseURL,
      apiKey: apiKey,
      model: settings.model,
      systemPrompt: settings.systemPrompt,
      sourceText: sourceText
    )

    let (data, response) = try await urlSession.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw OpenAICompatibleClientError.invalidResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw OpenAICompatibleClientError.requestFailed(httpResponse.statusCode, body)
    }

    let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
    guard let content = decoded.choices.first?.message.content else {
      throw OpenAICompatibleClientError.missingAssistantContent
    }

    return TranslationResponseParser.parseAssistantContent(
      content,
      sourceText: sourceText,
      model: settings.model
    )
  }

  public func streamTranslationDeltas(
    draft: TranslationDraft,
    settings: AppSettings,
    apiKey: String
  ) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          let request = try Self.makeRequest(
            baseURL: settings.baseURL,
            apiKey: apiKey,
            model: settings.model,
            systemPrompt: Self.streamingSystemPrompt(settings.systemPrompt),
            sourceText: draft.sourceText,
            stream: true,
            userContent: Self.streamingUserContent(for: draft)
          )

          let (bytes, response) = try await urlSession.bytes(for: request)
          guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAICompatibleClientError.invalidResponse
          }

          guard (200..<300).contains(httpResponse.statusCode) else {
            var body = ""
            for try await line in bytes.lines {
              body += line
            }
            throw OpenAICompatibleClientError.requestFailed(httpResponse.statusCode, body)
          }

          for try await line in bytes.lines {
            if line.trimmingCharacters(in: .whitespacesAndNewlines) == "data: [DONE]" {
              break
            }

            if let delta = StreamingChatCompletionParser.delta(fromSSELine: line) {
              continuation.yield(delta)
            }
          }

          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  private static func streamingSystemPrompt(_ prompt: String) -> String {
    """
    \(prompt)

    本次请求用于流式显示译文。只输出译文正文，不要输出 JSON、Markdown、解释或额外标签。
    """
  }

  private static func streamingUserContent(for draft: TranslationDraft) -> String {
    """
    请将以下文本翻译为\(draft.targetLanguage)。
    原文语言：\(draft.detectedLanguage)
    目标语言：\(draft.targetLanguage)

    原文：
    \(draft.sourceText)
    """
  }
}
