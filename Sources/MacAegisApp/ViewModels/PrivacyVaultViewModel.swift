import Foundation
import SwiftUI
import Combine
import AppKit
import MacAegisCore

@MainActor
public final class PrivacyVaultViewModel: ObservableObject {
    @Published public var isUnlocked: Bool = false
    @Published public var items: [VaultItem] = []
    @Published public var hasMasterPassword: Bool = false
    @Published public var isSettingUpMasterPassword: Bool = false
    @Published public var isAuthenticating: Bool = false
    @Published public var passwordInput: String = ""
    @Published public var passwordHint: String?
    @Published public var toastMessage: String?
    @Published public var searchText: String = ""

    private let vaultManager = PrivacyVaultManager.shared

    public init() {
        refreshState()
    }

    public func refreshState() {
        self.hasMasterPassword = vaultManager.hasMasterPassword
        self.passwordHint = vaultManager.getPasswordHint()
        self.items = vaultManager.fetchItems()
    }

    public func reloadItems() {
        self.items = vaultManager.fetchItems()
    }

    public var displayedItems: [VaultItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.path.localizedCaseInsensitiveContains(query)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func setupMasterPassword(password: String, hint: String?) {
        guard !password.isEmpty else {
            showToast(l10n("密码不能为空", "Password cannot be empty"))
            return
        }
        if vaultManager.setMasterPassword(password, hint: hint) {
            self.hasMasterPassword = true
            self.isSettingUpMasterPassword = false
            self.isUnlocked = true
            self.passwordInput = ""
            self.showToast(l10n("已设定金库密码并解锁", "Master password configured & unlocked"))
        } else {
            self.showToast(l10n("密码设置失败，请重试", "Failed to setup password. Try again."))
        }
    }

    public func unlockWithPassword() {
        guard !passwordInput.isEmpty else { return }
        if vaultManager.verifyMasterPassword(passwordInput) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                self.isUnlocked = true
                self.passwordInput = ""
                self.reloadItems()
            }
        } else {
            showToast(l10n("密码错误，请重新输入", "Incorrect password. Try again."))
        }
    }

    public func unlockVaultWithBiometrics() {
        guard !isUnlocked else { return }
        isAuthenticating = true

        Task {
            let success = await vaultManager.authenticateWithBiometrics()
            await MainActor.run {
                self.isAuthenticating = false
                if success {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                        self.isUnlocked = true
                        self.reloadItems()
                    }
                } else {
                    self.showToast(l10n("指纹验证未通过，请输入金库主密码", "Touch ID failed. Enter password."))
                }
            }
        }
    }

    public func lockVault() {
        vaultManager.lockAll()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            self.isUnlocked = false
            self.passwordInput = ""
            self.reloadItems()
            self.showToast(l10n("隐私保险箱已安全锁定", "Privacy Vault is safely locked"))
        }
    }

    public func unlockAndOpenInFinder(item: VaultItem) {
        vaultManager.unlockItem(item: item)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            reloadItems()
            showToast(l10n("已解除隐匿并在访达中定位「\(item.name)」", "Revealed '\(item.name)' in Finder"))
        }
    }

    public func lockItem(item: VaultItem) {
        vaultManager.lockItem(item: item)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            reloadItems()
            showToast(l10n("已将「\(item.name)」在访达中安全隐匿 🔒", "Safely hidden '\(item.name)' in Finder 🔒"))
        }
    }

    public func openAndHighlightInFinder(item: VaultItem) {
        vaultManager.openAndHighlightInFinder(path: item.path)
        reloadItems()
        showToast(l10n("已在访达中打开「\(item.name)」", "Opened '\(item.name)' in Finder"))
    }

    public func addFiles(urls: [URL], type: VaultItemType) {
        for url in urls {
            _ = vaultManager.addItem(url: url, type: type)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            reloadItems()
            showToast(l10n("已将 \(urls.count) 个项目加密上锁入库", "Encrypted & locked \(urls.count) items into Vault"))
        }
    }

    public func removeProtection(item: VaultItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            vaultManager.removeItem(id: item.id)
            reloadItems()
            showToast(l10n("已解除「\(item.name)」保护（文件原件完好保留）", "Protection removed for '\(item.name)' (file intact)"))
        }
    }

    public func showToast(_ msg: String) {
        self.toastMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.toastMessage == msg {
                self?.toastMessage = nil
            }
        }
    }
}
