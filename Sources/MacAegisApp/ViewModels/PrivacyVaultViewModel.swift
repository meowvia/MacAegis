import Foundation
import SwiftUI
import Combine
import AppKit
import MacAegisCore

public enum VaultFilterType: String, CaseIterable, Identifiable, Sendable {
    case all = "all"
    case folders = "folders"
    case files = "files"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: return l10n("全部", "All")
        case .folders: return l10n("文件夹", "Folders")
        case .files: return l10n("单体文件", "Files")
        }
    }

    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .folders: return "folder.fill"
        case .files: return "doc.fill"
        }
    }
}

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
    @Published public var isPasswordError: Bool = false
    @Published public var passwordErrorMessage: String?
    @Published public var shakeAttempts: Int = 0

    // Filter & Batch Selection State
    @Published public var filterType: VaultFilterType = .all
    @Published public var selectedItemIds: Set<String> = []
    @Published public var isConfirmingBatchRemove: Bool = false

    // Change Password Form State
    @Published public var isChangingPassword: Bool = false
    @Published public var oldPasswordInput: String = ""
    @Published public var newPasswordInput: String = ""
    @Published public var confirmNewPasswordInput: String = ""
    @Published public var newPasswordHintInput: String = ""
    @Published public var changePasswordErrorMessage: String?

    // Disaster Recovery Code State
    @Published public var masterRecoveryCode: String?
    @Published public var isRecoveringWithCode: Bool = false
    @Published public var recoveryCodeInput: String = ""
    @Published public var recoveryNewPasswordInput: String = ""
    @Published public var recoveryConfirmPasswordInput: String = ""
    @Published public var recoveryErrorMessage: String?

    // User Security Notice / Onboarding State
    @Published public var isShowingUserNotice: Bool = false
    @Published public var userNoticeCountdown: Int = 10
    private var noticeTimer: AnyCancellable?

    private let vaultManager = PrivacyVaultManager.shared

    public init() {
        refreshState()
    }

    public func refreshState() {
        self.hasMasterPassword = vaultManager.hasMasterPassword
        self.passwordHint = vaultManager.getPasswordHint()
        self.items = vaultManager.fetchItems()
        self.masterRecoveryCode = vaultManager.getMasterRecoveryCode()
    }

    public func reloadItems() {
        self.items = vaultManager.fetchItems()
        self.masterRecoveryCode = vaultManager.getMasterRecoveryCode()
    }

    public func isItemFolder(_ item: VaultItem) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir) {
            return isDir.boolValue
        }
        return (item.path as NSString).pathExtension.isEmpty
    }

    public var folderItems: [VaultItem] {
        items.filter { isItemFolder($0) }
    }

    public var fileItems: [VaultItem] {
        items.filter { !isItemFolder($0) }
    }

    public var displayedItems: [VaultItem] {
        let baseItems: [VaultItem]
        switch filterType {
        case .all: baseItems = items
        case .folders: baseItems = folderItems
        case .files: baseItems = fileItems
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return baseItems.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        return baseItems.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.path.localizedCaseInsensitiveContains(query)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public var displayedFolderItems: [VaultItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return folderItems.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        return folderItems.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.path.localizedCaseInsensitiveContains(query)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public var displayedFileItems: [VaultItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return fileItems.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        return fileItems.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.path.localizedCaseInsensitiveContains(query)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    // MARK: - Batch Selection & Operations
    public func toggleItemSelection(id: String) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
        } else {
            selectedItemIds.insert(id)
        }
    }

    public func selectAll() {
        selectedItemIds = Set(displayedItems.map { $0.id })
    }

    public func deselectAll() {
        selectedItemIds.removeAll()
    }

    public func selectAllFolders() {
        for item in displayedFolderItems {
            selectedItemIds.insert(item.id)
        }
    }

    public func selectAllFiles() {
        for item in displayedFileItems {
            selectedItemIds.insert(item.id)
        }
    }

    // MARK: - Queue for Operations Blocked by Authentication
    private var pendingActionAfterUnlock: (() -> Void)? = nil

    public func requireAuthentication(then action: @escaping () -> Void) {
        if isUnlocked && vaultManager.isSessionActive {
            action()
        } else {
            self.pendingActionAfterUnlock = action
            self.isUnlocked = false
            if hasMasterPassword {
                self.unlockVaultWithBiometrics()
            } else {
                self.isSettingUpMasterPassword = true
            }
        }
    }

    private func executePendingActionIfAny() {
        if let pending = self.pendingActionAfterUnlock {
            self.pendingActionAfterUnlock = nil
            pending()
        }
    }

    public func batchUnlockSelected(silent: Bool = true) {
        requireAuthentication { [weak self] in
            self?.performBatchUnlockSelected(silent: silent)
        }
    }

    private func performBatchUnlockSelected(silent: Bool = true) {
        let targets = items.filter { selectedItemIds.contains($0.id) && ($0.status == .hidden || $0.status == .locked) }
        guard !targets.isEmpty else {
            showToast(l10n("所选项目中没有需要解锁的项目", "No locked items selected"))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            for item in targets {
                self.vaultManager.unlockItem(item: item)
            }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    self.reloadItems()
                    self.selectedItemIds.removeAll()
                    self.showToast(l10n("已瞬时静默解锁 \(targets.count) 个项目 ✨", "Instant unlocked \(targets.count) items ✨"))
                }
            }
        }
    }

    public func batchLockSelected() {
        requireAuthentication { [weak self] in
            self?.performBatchLockSelected()
        }
    }

    private func performBatchLockSelected() {
        let targets = items.filter { selectedItemIds.contains($0.id) && $0.status != .hidden && $0.status != .locked }
        guard !targets.isEmpty else {
            showToast(l10n("所选项目中没有需要上锁的项目", "No unlocked items selected"))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            for item in targets {
                self.vaultManager.lockItem(item: item)
            }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    self.reloadItems()
                    self.selectedItemIds.removeAll()
                    self.showToast(l10n("已瞬时锁定 \(targets.count) 个项目 🔒", "Instant locked \(targets.count) items 🔒"))
                }
            }
        }
    }

    public func batchRemoveProtectionSelected() {
        requireAuthentication { [weak self] in
            self?.performBatchRemoveProtectionSelected()
        }
    }

    private func performBatchRemoveProtectionSelected() {
        let targets = items.filter { selectedItemIds.contains($0.id) }
        guard !targets.isEmpty else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            for item in targets {
                self.vaultManager.removeItem(id: item.id)
            }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.reloadItems()
                    self.selectedItemIds.removeAll()
                    self.isConfirmingBatchRemove = false
                    self.showToast(l10n("已解除 \(targets.count) 个项目的保护（文件原件完好保留）", "Protection removed for \(targets.count) items (files intact)"))
                }
            }
        }
    }

    public func unlockAllItems(silent: Bool = true) {
        requireAuthentication { [weak self] in
            self?.performUnlockAllItems(silent: silent)
        }
    }

    private func performUnlockAllItems(silent: Bool = true) {
        let targets = items.filter { $0.status == .hidden || $0.status == .locked }
        guard !targets.isEmpty else {
            showToast(l10n("当前没有已上锁的项目", "No locked items"))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            for item in targets {
                self.vaultManager.unlockItem(item: item)
            }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    self.reloadItems()
                    self.showToast(l10n("已一键解锁全部 \(targets.count) 个项目 ✨", "All \(targets.count) items unlocked ✨"))
                }
            }
        }
    }

    public func lockAllItems() {
        requireAuthentication { [weak self] in
            self?.performLockAllItems()
        }
    }

    private func performLockAllItems() {
        let targets = items.filter { $0.status != .hidden && $0.status != .locked }
        guard !targets.isEmpty else {
            showToast(l10n("所有项目均已在锁定隐匿状态", "All items are already locked"))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            for item in targets {
                self.vaultManager.lockItem(item: item)
            }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    self.reloadItems()
                    self.showToast(l10n("已一键锁定全部 \(targets.count) 个项目 🔒", "All \(targets.count) items locked 🔒"))
                }
            }
        }
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
            self.masterRecoveryCode = vaultManager.getMasterRecoveryCode()
            self.showToast(l10n("已设定主密码并安全解锁", "Master password configured & unlocked"))
            self.checkAndPresentUserNoticeOnboarding()
            self.executePendingActionIfAny()
        } else {
            self.showToast(l10n("密码设置失败，请重试", "Failed to setup password. Try again."))
        }
    }

    public func unlockWithPassword() {
        let trimmed = passwordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || !vaultManager.verifyMasterPassword(trimmed) {
            triggerPasswordError()
            return
        }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
            self.isUnlocked = true
            self.passwordInput = ""
            self.isPasswordError = false
            self.passwordErrorMessage = nil
            self.reloadItems()
            self.checkAndPresentUserNoticeOnboarding()
            self.executePendingActionIfAny()
        }
    }

    public func triggerPasswordError() {
        NSSound.beep()
        self.passwordInput = ""
        self.passwordErrorMessage = l10n("请输入正确密码", "Enter correct password")
        self.isPasswordError = true
        self.shakeAttempts += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                self.isPasswordError = false
                self.passwordErrorMessage = nil
            }
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
                        self.executePendingActionIfAny()
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
            self.showToast(l10n("隐私隐匿已安全锁定", "Privacy Conceal is safely locked"))
        }
    }

    public func unlockAndOpenInFinder(item: VaultItem) {
        requireAuthentication { [weak self] in
            self?.performUnlockAndOpenInFinder(item: item)
        }
    }

    private func performUnlockAndOpenInFinder(item: VaultItem) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.vaultManager.unlockItem(item: item)
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    self.reloadItems()
                    self.showToast(l10n("已解除隐匿并在访达中定位「\(item.name)」", "Revealed '\(item.name)' in Finder"))
                }
            }
        }
    }

    public func lockItem(item: VaultItem) {
        requireAuthentication { [weak self] in
            self?.performLockItem(item: item)
        }
    }

    private func performLockItem(item: VaultItem) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.vaultManager.lockItem(item: item)
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    self.reloadItems()
                    self.showToast(l10n("已将「\(item.name)」在访达中安全隐匿 🔒", "Safely hidden '\(item.name)' in Finder 🔒"))
                }
            }
        }
    }

    public func openAndHighlightInFinder(item: VaultItem) {
        requireAuthentication { [weak self] in
            self?.performOpenAndHighlightInFinder(item: item)
        }
    }

    private func performOpenAndHighlightInFinder(item: VaultItem) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.vaultManager.openAndHighlightInFinder(path: item.path)
            DispatchQueue.main.async {
                self.reloadItems()
                self.showToast(l10n("已在访达中打开「\(item.name)」", "Opened '\(item.name)' in Finder"))
            }
        }
    }

    public func addFiles(urls: [URL], type: VaultItemType) {
        requireAuthentication { [weak self] in
            self?.performAddFiles(urls: urls, type: type)
        }
    }

    private func performAddFiles(urls: [URL], type: VaultItemType) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var addedCount = 0
            var blockedCloudCount = 0
            for url in urls {
                if self.vaultManager.isCloudStoragePath(path: url.path) {
                    blockedCloudCount += 1
                    continue
                }
                if let _ = self.vaultManager.addItem(url: url, type: type) {
                    addedCount += 1
                }
            }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.reloadItems()
                    if blockedCloudCount > 0 {
                        self.showToast(l10n("⚠️ 已拦截 \(blockedCloudCount) 个云端同步文件（请拷贝至本地磁盘后再隐匿）", "⚠️ Blocked \(blockedCloudCount) cloud-synced files (move to local disk first)"))
                    } else if addedCount > 0 {
                        self.showToast(l10n("已将 \(addedCount) 个项目隐藏入库", "Concealed \(addedCount) items into Vault"))
                    }
                }
            }
        }
    }

    public func removeProtection(item: VaultItem) {
        requireAuthentication { [weak self] in
            self?.performRemoveProtection(item: item)
        }
    }

    private func performRemoveProtection(item: VaultItem) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.vaultManager.removeItem(id: item.id)
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.reloadItems()
                    self.showToast(l10n("已解除「\(item.name)」保护（文件原件完好保留）", "Protection removed for '\(item.name)' (file intact)"))
                }
            }
        }
    }

    public func rescueScanForHiddenItems() {
        requireAuthentication { [weak self] in
            self?.performRescueScanForHiddenItems()
        }
    }

    private func performRescueScanForHiddenItems() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let found = self.vaultManager.scanAndRecoverHiddenItems()
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.reloadItems()
                    if found.count > 0 {
                        self.showToast(l10n("成功找回并重新纳管 \(found.count) 个隐藏项目！", "Recovered \(found.count) hidden items!"))
                    } else {
                        self.showToast(l10n("已完成深度扫描。若文件位于外接盘，请确保已连接外接硬盘。", "Scan complete. If items are on external drives, please ensure they are connected."))
                    }
                }
            }
        }
    }

    public func executeRecoverWithCode() -> Bool {
        recoveryErrorMessage = nil
        let trimmedCode = recoveryCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = recoveryNewPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = recoveryConfirmPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty else {
            recoveryErrorMessage = l10n("请输入 64 位恢复码", "Please enter recovery key")
            return false
        }
        guard !trimmedNew.isEmpty else {
            recoveryErrorMessage = l10n("新密码不能为空", "New password cannot be empty")
            return false
        }
        guard trimmedNew.count >= 6 else {
            recoveryErrorMessage = l10n("新密码长度至少需要 6 位", "New password must be at least 6 characters")
            return false
        }
        guard trimmedNew == trimmedConfirm else {
            recoveryErrorMessage = l10n("两次输入的新密码不一致", "New passwords do not match")
            return false
        }

        let success = vaultManager.recoverVault(usingRecoveryCode: trimmedCode, newPassword: trimmedNew)
        if success {
            self.isRecoveringWithCode = false
            self.recoveryCodeInput = ""
            self.recoveryNewPasswordInput = ""
            self.recoveryConfirmPasswordInput = ""
            self.recoveryErrorMessage = nil
            self.isUnlocked = true
            self.masterRecoveryCode = vaultManager.getMasterRecoveryCode()
            self.showToast(l10n("已使用恢复码成功重置主密码并解锁 🎉", "Vault successfully recovered with key 🎉"))
            self.reloadItems()
            return true
        } else {
            self.recoveryErrorMessage = l10n("恢复码无效或格式错误，请检查核对", "Invalid recovery key format")
            return false
        }
    }

    public func executeChangePassword() -> Bool {
        changePasswordErrorMessage = nil
        let trimmedOld = oldPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = newPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmNewPasswordInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedOld.isEmpty else {
            changePasswordErrorMessage = l10n("请输入当前旧密码", "Please enter your current password")
            return false
        }
        guard !trimmedNew.isEmpty else {
            changePasswordErrorMessage = l10n("新密码不能为空", "New password cannot be empty")
            return false
        }
        guard trimmedNew.count >= 6 else {
            changePasswordErrorMessage = l10n("新密码长度至少需要 6 位", "New password must be at least 6 characters")
            return false
        }
        guard trimmedNew == trimmedConfirm else {
            changePasswordErrorMessage = l10n("两次输入的新密码不一致", "New passwords do not match")
            return false
        }

        let hint = newPasswordHintInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newPasswordHintInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let success = vaultManager.changeMasterPassword(oldPassword: trimmedOld, newPassword: trimmedNew, hint: hint)
        if success {
            self.isChangingPassword = false
            self.oldPasswordInput = ""
            self.newPasswordInput = ""
            self.confirmNewPasswordInput = ""
            self.newPasswordHintInput = ""
            self.changePasswordErrorMessage = nil
            self.passwordHint = hint
            self.showToast(l10n("主密码已成功修改 🔑", "Master password successfully changed 🔑"))
            return true
        } else {
            self.changePasswordErrorMessage = l10n("原密码验证失败，请重新输入", "Current password incorrect")
            return false
        }
    }

    // MARK: - User Security Notice Handlers
    public func openUserNotice() {
        self.userNoticeCountdown = 10
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.isShowingUserNotice = true
        }
        self.noticeTimer?.cancel()
        self.noticeTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.userNoticeCountdown > 0 {
                    self.userNoticeCountdown -= 1
                } else {
                    self.noticeTimer?.cancel()
                }
            }
    }

    public func dismissUserNotice() {
        UserDefaults.standard.set(true, forKey: "MacAegis_HasSeenUserNotice_v1")
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.isShowingUserNotice = false
        }
        self.noticeTimer?.cancel()
    }

    public func checkAndPresentUserNoticeOnboarding() {
        if !UserDefaults.standard.bool(forKey: "MacAegis_HasSeenUserNotice_v1") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.openUserNotice()
            }
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
