import Foundation
import IOKit.ps

public struct PowerAndThermalInfo: Sendable {
    public let thermalState: String
    public let thermalBadge: String
    public let batteryPercentage: Int?
    public let isCharging: Bool?
    public let isPluggedIn: Bool?

    public var powerSourceDescription: String {
        if let plugged = isPluggedIn {
            return plugged ? l10n("AC 电源", "AC Power") : l10n("电池供电", "Battery Power")
        }
        return l10n("未知", "Unknown")
    }
}

public final class PowerMonitor: Sendable {
    public static let shared = PowerMonitor()

    public init() {}

    public func fetchInfo() -> PowerAndThermalInfo {
        // Thermal
        let thermal = ProcessInfo.processInfo.thermalState
        let thermalStr: String
        let badge: String
        switch thermal {
        case .nominal:
            thermalStr = l10n("清凉", "Cool")
            badge = "🟢"
        case .fair:
            thermalStr = l10n("正常", "Nominal")
            badge = "🟢"
        case .serious:
            thermalStr = l10n("发热", "Warm")
            badge = "🟡"
        case .critical:
            thermalStr = l10n("高温降频", "Throttled Hot")
            badge = "🔴"
        @unknown default:
            thermalStr = l10n("正常", "Nominal")
            badge = "🟢"
        }

        // Battery via IOPS
        var batteryPercent: Int? = nil
        var isCharging: Bool? = nil
        var isPluggedIn: Bool? = nil

        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                if let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                    if let cur = desc[kIOPSCurrentCapacityKey as String] as? Int,
                       let max = desc[kIOPSMaxCapacityKey as String] as? Int, max > 0 {
                        batteryPercent = Int(Double(cur) / Double(max) * 100.0)
                    }
                    if let charging = desc[kIOPSIsChargingKey as String] as? Bool {
                        isCharging = charging
                    }
                    if let state = desc[kIOPSPowerSourceStateKey as String] as? String {
                        isPluggedIn = state == (kIOPSACPowerValue as String)
                    }
                }
            }
        }

        return PowerAndThermalInfo(
            thermalState: thermalStr,
            thermalBadge: badge,
            batteryPercentage: batteryPercent,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn
        )
    }
}
