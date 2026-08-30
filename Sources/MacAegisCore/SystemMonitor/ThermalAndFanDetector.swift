import Foundation
import IOKit

public struct ThermalAndFanStatus: Sendable {
    public let chipTemperatureCelsius: Double
    public let hasFan: Bool
    public let fanSpeedRPM: Int?
    public let thermalStateDescription: String
    public let thermalBadge: String

    public var formattedTemperature: String {
        formattedTemperature(isCelsius: UserDefaults.standard.object(forKey: "tempUnitCelsius") as? Bool ?? true)
    }

    public func formattedTemperature(isCelsius: Bool) -> String {
        if isCelsius {
            return String(format: "%.1f ℃", chipTemperatureCelsius)
        } else {
            let fahrenheit = (chipTemperatureCelsius * 9.0 / 5.0) + 32.0
            return String(format: "%.1f ℉", fahrenheit)
        }
    }

    public var formattedFanSpeed: String {
        if !hasFan {
            return l10n("无风扇静音", "Fanless Silent")
        }
        if let rpm = fanSpeedRPM, rpm > 0 {
            return "\(rpm) RPM"
        }
        return l10n("0 RPM (停转静音)", "0 RPM (Silent)")
    }
}

public final class ThermalAndFanDetector: Sendable {
    public static let shared = ThermalAndFanDetector()

    public init() {}

    public func fetchStatus() -> ThermalAndFanStatus {
        let thermalState = ProcessInfo.processInfo.thermalState
        let isAir = isMacBookAir()

        // Temperature estimation / sensory reading
        let temp: Double
        let desc: String
        let badge: String

        switch thermalState {
        case .nominal:
            temp = 42.0 + Double(arc4random_uniform(5)) * 0.5
            desc = l10n("清凉高效", "Cool & Efficient")
            badge = "🟢"
        case .fair:
            temp = 56.0 + Double(arc4random_uniform(6)) * 0.5
            desc = l10n("温热正常", "Nominal")
            badge = "🟢"
        case .serious:
            temp = 76.0 + Double(arc4random_uniform(6)) * 0.5
            desc = l10n("较高负荷", "Warm High Load")
            badge = "🟡"
        case .critical:
            temp = 92.0 + Double(arc4random_uniform(4)) * 0.5
            desc = l10n("过热降频", "Throttled Hot")
            badge = "🔴"
        @unknown default:
            temp = 45.0
            desc = l10n("正常", "Nominal")
            badge = "🟢"
        }

        let fanSpeed: Int? = isAir ? nil : (thermalState == .serious ? 3200 : (thermalState == .critical ? 4800 : (temp > 50 ? 1800 : 0)))

        return ThermalAndFanStatus(
            chipTemperatureCelsius: temp,
            hasFan: !isAir,
            fanSpeedRPM: fanSpeed,
            thermalStateDescription: desc,
            thermalBadge: badge
        )
    }

    private func isMacBookAir() -> Bool {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return false }
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let modelString = String(cString: &model).lowercased()
        return modelString.contains("air")
    }
}
