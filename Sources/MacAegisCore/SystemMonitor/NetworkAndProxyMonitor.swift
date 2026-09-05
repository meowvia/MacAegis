import Foundation
import SystemConfiguration
import AppKit

public enum ProxyMode: String, Sendable {
    case global = "全局代理"
    case rule = "规则分流"
    case direct = "普通直连"

    public var localizedTitle: String {
        switch self {
        case .global: return l10n("全局代理", "Global Proxy")
        case .rule: return l10n("规则分流", "Rule Routing")
        case .direct: return l10n("普通直连", "Direct")
        }
    }

    public var badge: String {
        switch self {
        case .global: return "🔴"
        case .rule: return "🟢"
        case .direct: return "🔵"
        }
    }

    public var colorHex: String {
        switch self {
        case .global: return "EF4444" // Crimson Red
        case .rule: return "10B981"   // Emerald Green
        case .direct: return "0284C7" // Vibrant Ocean Sky Blue
        }
    }
}

public struct NetworkSpeedInfo: Sendable {
    public let uploadBytesPerSec: Int64
    public let downloadBytesPerSec: Int64
    public let proxyMode: ProxyMode

    public var formattedDownload: String {
        return "\(ByteFormatter.format(downloadBytesPerSec))/s"
    }

    public var formattedUpload: String {
        return "\(ByteFormatter.format(uploadBytesPerSec))/s"
    }

    public var compactDownString: String {
        formatRate(downloadBytesPerSec)
    }

    public var compactUpString: String {
        formatRate(uploadBytesPerSec)
    }

    private func formatRate(_ bytes: Int64) -> String {
        if bytes >= 1024 * 1024 * 10 {
            return String(format: "%.0fM", Double(bytes) / (1024 * 1024))
        } else if bytes >= 1024 * 1024 {
            return String(format: "%.1fM", Double(bytes) / (1024 * 1024))
        } else if bytes >= 1024 {
            return "\(bytes / 1024)K"
        } else {
            return "0K"
        }
    }

    public var menuBarDisplayString: String {
        return "↓ \(compactDownString) ↑ \(compactUpString)"
    }
}

public final class NetworkAndProxyMonitor: @unchecked Sendable {
    public static let shared = NetworkAndProxyMonitor()

    private var previousBytes: (ibytes: UInt64, obytes: UInt64, time: Date)?
    private let lock = NSLock()
    private var cachedProxyMode: ProxyMode = .direct
    private var lastProbeTime: Date = Date.distantPast

    private init() {
        // Run initial detection
        self.cachedProxyMode = detectProxyModeSync()
        startPeriodicProbe()
    }

    private func startPeriodicProbe() {
        // Run active dynamic probe in background every 1.0 second for instant reactivity
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.runActiveProbe()
        }
    }

    /// Query live upload/download speed and proxy routing mode
    public func fetchNetworkSpeed() -> NetworkSpeedInfo {
        lock.lock()
        defer { lock.unlock() }

        let (currentIBytes, currentOBytes) = getTotalInterfaceBytes()
        let now = Date()

        // If probe is older than 1.5s, trigger background probe
        if now.timeIntervalSince(lastProbeTime) > 1.5 {
            lastProbeTime = now
            runActiveProbe()
        }

        guard let prev = previousBytes else {
            previousBytes = (currentIBytes, currentOBytes, now)
            return NetworkSpeedInfo(uploadBytesPerSec: 0, downloadBytesPerSec: 0, proxyMode: cachedProxyMode)
        }

        let timeInterval = now.timeIntervalSince(prev.time)
        guard timeInterval > 0.1 else {
            return NetworkSpeedInfo(uploadBytesPerSec: 0, downloadBytesPerSec: 0, proxyMode: cachedProxyMode)
        }

        let downRate = Int64(Double(currentIBytes >= prev.ibytes ? currentIBytes - prev.ibytes : 0) / timeInterval)
        let upRate = Int64(Double(currentOBytes >= prev.obytes ? currentOBytes - prev.obytes : 0) / timeInterval)

        previousBytes = (currentIBytes, currentOBytes, now)

        return NetworkSpeedInfo(
            uploadBytesPerSec: max(0, upRate),
            downloadBytesPerSec: max(0, downRate),
            proxyMode: cachedProxyMode
        )
    }

    private func getTotalInterfaceBytes() -> (UInt64, UInt64) {
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else {
            return (0, 0)
        }
        defer { freeifaddrs(ifap) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let name = String(cString: current.pointee.ifa_name)

            // Only inspect AF_LINK link-layer socket structures with valid if_data
            if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                let lower = name.lowercased()
                let isLoopback = lower.hasPrefix("lo")
                // Exclude virtual tunnels and auxiliary peer-to-peer links that duplicate physical bytes
                let isDuplicateVirtual = lower.hasPrefix("utun") || lower.hasPrefix("gif") || lower.hasPrefix("stf") || lower.hasPrefix("bridge") || lower.hasPrefix("llw") || lower.hasPrefix("awdl")

                if !isLoopback && !isDuplicateVirtual {
                    if let data = current.pointee.ifa_data {
                        let ifData = data.assumingMemoryBound(to: if_data.self)
                        totalIn += UInt64(ifData.pointee.ifi_ibytes)
                        totalOut += UInt64(ifData.pointee.ifi_obytes)
                    }
                }
            }
            cursor = current.pointee.ifa_next
        }

        return (totalIn, totalOut)
    }

    // MARK: - Active Dynamic Network Probe + Multi-Layer Detection
    public func detectProxyModeSync() -> ProxyMode {
        // Priority 1: Check active specialized clients (v2rayN, Clash/Mihomo, Surge)
        if let v2rayMode = checkV2RayNActiveMode() {
            return v2rayMode
        }
        if let clashMode = checkClashMode() {
            return clashMode
        }
        if let surgeMode = checkSurgeMode() {
            return surgeMode
        }

        // Priority 2: System-wide VPN Tunnel (Only when default gateway interface is utun/ppp/ipsec)
        if let tunMode = checkTunInterfaceMode() {
            return tunMode
        }

        // Priority 3: System-Level Proxies (CFNetwork / SCDynamicStore)
        if let sysMode = checkSystemProxyMode() {
            return sysMode
        }

        // Priority 4: Direct Standard Connection
        return .direct
    }

    // MARK: - Dedicated System Dynamic Store & Proxy Inspector
    private func checkSystemProxyMode() -> ProxyMode? {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return nil
        }

        let httpEnable = proxySettings[kCFNetworkProxiesHTTPEnable as String] as? Int == 1
        let httpsEnable = proxySettings[kCFNetworkProxiesHTTPSEnable as String] as? Int == 1
        let socksEnable = proxySettings[kCFNetworkProxiesSOCKSEnable as String] as? Int == 1
        let autoConfig = proxySettings[kCFNetworkProxiesProxyAutoConfigEnable as String] as? Int == 1
        let autoDiscovery = proxySettings[kCFNetworkProxiesProxyAutoDiscoveryEnable as String] as? Int == 1

        if autoConfig || autoDiscovery {
            return .rule
        }

        if httpEnable || httpsEnable || socksEnable {
            // Check if there are real domain bypass rules (filter out default localhost/127.0.0.1)
            if let exceptions = proxySettings[kCFNetworkProxiesExceptionsList as String] as? [String] {
                let customExceptions = exceptions.filter { item in
                    let lower = item.lowercased().trimmingCharacters(in: .whitespaces)
                    return lower != "localhost" && lower != "127.0.0.0/8" && lower != "127.0.0.1" && lower != "::1" && !lower.isEmpty
                }
                if !customExceptions.isEmpty {
                    return .rule
                }
            }
            return .global
        }

        return nil
    }

    // MARK: - Dynamic Virtual TUN Interface & Default Route Inspector
    private func checkTunInterfaceMode() -> ProxyMode? {
        // Query macOS SystemConfiguration for actual Primary Default Route Interface
        guard let store = SCDynamicStoreCreate(nil, "MacAegisRouteCheck" as CFString, nil, nil),
              let globalIPv4 = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any],
              let primaryInterface = globalIPv4["PrimaryInterface"] as? String else {
            return nil
        }

        let lower = primaryInterface.lowercased()
        if lower.hasPrefix("utun") || lower.hasPrefix("ppp") || lower.hasPrefix("ipsec") {
            return .global
        }
        return nil
    }

    // MARK: - Background Active Dual-Probe Engine
    private func runActiveProbe() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let detectedMode = self.detectProxyModeSync()
            self.lock.lock()
            self.cachedProxyMode = detectedMode
            self.lastProbeTime = Date()
            self.lock.unlock()
        }
    }

    // MARK: - Dedicated V2RayN Inspector
    private func checkV2RayNActiveMode() -> ProxyMode? {
        let v2rayDir = FileUtils.expandPath("~/Library/Application Support/v2rayN")
        let dbPath = "\(v2rayDir)/guiConfigs/guiNDB.db"
        guard FileManager.default.fileExists(atPath: dbPath) else { return nil }

        // Check if v2rayN or xray/v2ray processes are currently active via memory sysctl
        let isRunning = isProcessActive(named: "v2rayN") || isProcessActive(named: "xray") || isProcessActive(named: "v2ray")
        guard isRunning else { return nil }

        var sysProxyType = 0
        var enableTun = false

        // Check guiNConfig.json for System Proxy Type and TUN mode
        let configPath = "\(v2rayDir)/guiConfigs/guiNConfig.json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let sysProxy = json["SystemProxyItem"] as? [String: Any] {
                sysProxyType = sysProxy["SysProxyType"] as? Int ?? 0 // 0 = 清除系统代理, 1 = 开启系统代理, 2 = PAC
            }
            if let tun = json["TunModeItem"] as? [String: Any] {
                enableTun = tun["EnableTun"] as? Bool ?? false
            }
        }

        // If neither system proxy nor TUN is enabled, it's Direct
        if sysProxyType == 0 && !enableTun {
            return .direct
        }

        // Check binConfigs/config.json for routing rules
        let xrayConfigPath = "\(v2rayDir)/binConfigs/config.json"
        if let xrayData = try? Data(contentsOf: URL(fileURLWithPath: xrayConfigPath)),
           let xrayJson = try? JSONSerialization.jsonObject(with: xrayData) as? [String: Any] {
            if let routing = xrayJson["routing"] as? [String: Any],
               let rules = routing["rules"] as? [[String: Any]] {
                // If rules contain direct outbound tags (e.g. geoip:cn / geosite:cn -> direct), it's Rule Routing
                let hasDirectRules = rules.contains { rule in
                    let tag = rule["outboundTag"] as? String ?? ""
                    return tag.lowercased() == "direct"
                }
                if hasDirectRules {
                    return .rule
                } else {
                    return .global
                }
            }
        }

        return .rule
    }

    // MARK: - Dedicated Clash / Mihomo Inspector
    private func checkClashMode() -> ProxyMode? {
        let isRunning = isProcessActive(named: "clash") || isProcessActive(named: "mihomo") || isProcessActive(named: "Clash Verge") || isProcessActive(named: "ClashX")
        guard isRunning else { return nil }

        let clashConfigPath = FileUtils.expandPath("~/.config/clash/config.yaml")
        let mihomoConfigPath = FileUtils.expandPath("~/.config/mihomo/config.yaml")

        for path in [clashConfigPath, mihomoConfigPath] {
            if let content = try? String(contentsOfFile: path) {
                let lower = content.lowercased()
                if lower.contains("mode: global") {
                    return .global
                } else if lower.contains("mode: rule") {
                    return .rule
                } else if lower.contains("mode: direct") {
                    return .direct
                }
            }
        }
        return nil
    }

    // MARK: - Dedicated Surge Inspector
    private func checkSurgeMode() -> ProxyMode? {
        guard isProcessActive(named: "Surge") else { return nil }
        let defaults = UserDefaults(suiteName: "com.nssurge.surge-mac")
        if let outboundMode = defaults?.string(forKey: "OutboundMode") {
            let lower = outboundMode.lowercased()
            if lower.contains("direct") {
                return .direct
            } else if lower.contains("global") {
                return .global
            } else {
                return .rule
            }
        }
        return nil
    }

    /// Fast, non-blocking zero-fork process detection via NSWorkspace and Darwin sysctl
    private func isProcessActive(named processName: String) -> Bool {
        // NSWorkspace is extremely heavy via IPC and causes mouse stutter when polled frequently.
        // We solely rely on the ultra-fast Darwin kernel process table inspection in memory (< 0.05ms)
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size: size_t = 0
        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0 else { return false }
        let count = size / MemoryLayout<kinfo_proc>.size
        var procList = [kinfo_proc](repeating: kinfo_proc(), count: count)
        guard sysctl(&mib, 4, &procList, &size, nil, 0) == 0 else { return false }

        let target = processName.lowercased()
        for proc in procList {
            var pName = proc.kp_proc.p_comm
            let nameStr = withUnsafePointer(to: &pName) {
                $0.withMemoryRebound(to: CChar.self, capacity: 16) { String(cString: $0).lowercased() }
            }
            if nameStr.contains(target) {
                return true
            }
        }

        return false
    }
}
