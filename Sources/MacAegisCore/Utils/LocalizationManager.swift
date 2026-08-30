import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case zh = "zh"
    case en = "en"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .zh: return "简体中文 (Chinese)"
        case .en: return "English"
        }
    }
}

public final class LocalizationManager: ObservableObject, @unchecked Sendable {
    public static let shared = LocalizationManager()

    public var currentLanguage: String {
        get {
            if let saved = UserDefaults.standard.string(forKey: "appLanguage") {
                return saved
            }
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "zh"
            return preferred.hasPrefix("en") ? AppLanguage.en.rawValue : AppLanguage.zh.rawValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "appLanguage")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    public var isEnglish: Bool {
        return currentLanguage == AppLanguage.en.rawValue
    }

    public func tr(_ zh: String, _ en: String) -> String {
        return isEnglish ? en : zh
    }
}

/// Global convenience localization helper
public func l10n(_ zh: String, _ en: String) -> String {
    return LocalizationManager.shared.tr(zh, en)
}
