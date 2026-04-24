import Foundation
import Security

public enum KeychainStoreError: Error {
  case unexpectedStatus(OSStatus)
}

public final class KeychainStore {
  private let service: String
  private let account: String

  public init(
    service: String = "com.only77.QuickTranslate",
    account: String = "openai-compatible-api-key"
  ) {
    self.service = service
    self.account = account
  }

  public func saveAPIKey(_ apiKey: String) throws {
    let data = Data(apiKey.utf8)
    let query = baseQuery()

    let status = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
    if status == errSecSuccess {
      return
    }

    if status == errSecItemNotFound {
      var addQuery = query
      addQuery[kSecValueData as String] = data
      let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
      guard addStatus == errSecSuccess else {
        throw KeychainStoreError.unexpectedStatus(addStatus)
      }
      return
    }

    throw KeychainStoreError.unexpectedStatus(status)
  }

  public func loadAPIKey() throws -> String {
    var query = baseQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound {
      return ""
    }

    guard status == errSecSuccess else {
      throw KeychainStoreError.unexpectedStatus(status)
    }

    guard let data = item as? Data else {
      return ""
    }

    return String(data: data, encoding: .utf8) ?? ""
  }

  public func deleteAPIKey() throws {
    let status = SecItemDelete(baseQuery() as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainStoreError.unexpectedStatus(status)
    }
  }

  private func baseQuery() -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
  }
}
