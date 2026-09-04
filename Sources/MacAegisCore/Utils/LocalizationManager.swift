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

    @Published public var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage")
            UserDefaults.standard.synchronize() // Force flush for safety
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "zh"
        self.appLanguage = AppLanguage(rawValue: saved) ?? .zh
    }

    public var isEnglish: Bool {
        return appLanguage == .en
    }

    public func tr(_ zh: String, _ en: String) -> String {
        return isEnglish ? en : zh
    }
}

public func l10n(_ zh: String, _ en: String) -> String {
    return LocalizationManager.shared.tr(zh, en)
}