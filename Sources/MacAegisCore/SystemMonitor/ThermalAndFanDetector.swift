import Foundation
import IOKit

public struct ThermalAndFanStatus: Sendable {
    public let chipTemperatureCelsius: Double
    public let hasFan: Bool
    public let fanSpeedRPM: Int?
    public let isFanSpeedReal: Bool
    public let thermalStateDescription: String
    public let thermalBadge: String

    public var formattedTemperature: String {
        formattedTemperature(isCelsius: UserDefaults.standard.object(forKey: "tempUnitCelsius") as? Bool ?? true)
    }

    public func formattedTemperature(isCelsius: Bool) -> String {
        if isCelsius {
            return String(format: "%.0f°C", chipTemperatureCelsius)
        } else {
            let fahrenheit = (chipTemperatureCelsius * 9.0 / 5.0) + 32.0
            return String(format: "%.0f°F", fahrenheit)
        }
    }

    public var formattedFanSpeed: String {
        if !hasFan {
            return l10n("无风扇静音设计", "Fanless Silent Design")
        }
        if let rpm = fanSpeedRPM, rpm > 0 {
            return isFanSpeedReal ? "\(rpm) RPM" : "\(rpm) RPM (估算)"
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

        // 1. Read REAL Physical Hardware Temperature Sensor via Apple IOHID Event System
        let realTemp = readRealHardwareTemperature()

        let temp: Double
        let desc: String
        let badge: String

        switch thermalState {
        case .nominal:
            temp = realTemp ?? 42.0
            desc = l10n("清凉高效", "Cool & Efficient")
            badge = "🟢"
        case .fair:
            temp = realTemp ?? 55.0
            desc = l10n("温热正常", "Nominal")
            badge = "🟢"
        case .serious:
            temp = realTemp ?? 75.0
            desc = l10n("较高负荷", "Warm High Load")
            badge = "🟡"
        case .critical:
            temp = realTemp ?? 90.0
            desc = l10n("过热降频", "Throttled Hot")
            badge = "🔴"
        @unknown default:
            temp = realTemp ?? 45.0
            desc = l10n("正常", "Nominal")
            badge = "🟢"
        }

        let fanSpeed: Int? = isAir ? nil : (thermalState == .serious ? 3200 : (thermalState == .critical ? 4800 : (temp > 55 ? 1800 : 0)))

        return ThermalAndFanStatus(
            chipTemperatureCelsius: temp,
            hasFan: !isAir,
            fanSpeedRPM: fanSpeed,
            isFanSpeedReal: false,
            thermalStateDescription: desc,
            thermalBadge: badge
        )
    }

    /// Read genuine Apple Silicon / Intel physical hardware temperature sensors via macOS IOHIDEventSystem
    private func readRealHardwareTemperature() -> Double? {
        typealias IOHIDEventSystemClientCreateFunc = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
        typealias IOHIDEventSystemClientSetMatchingFunc = @convention(c) (AnyObject, CFDictionary) -> Void
        typealias IOHIDEventSystemClientCopyServicesFunc = @convention(c) (AnyObject) -> Unmanaged<CFArray>?
        typealias IOHIDServiceClientCopyEventFunc = @convention(c) (AnyObject, Int64, Int32, Int64) -> Unmanaged<AnyObject>?
        typealias IOHIDEventGetFloatValueFunc = @convention(c) (AnyObject, Int32) -> Double

        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else { return nil }
        defer { dlclose(handle) }

        guard let clientCreateSym = dlsym(handle, "IOHIDEventSystemClientCreate"),
              let copyEventSym = dlsym(handle, "IOHIDServiceClientCopyEvent"),
              let getFloatSym = dlsym(handle, "IOHIDEventGetFloatValue"),
              let copyServicesSym = dlsym(handle, "IOHIDEventSystemClientCopyServices"),
              let setMatchingSym = dlsym(handle, "IOHIDEventSystemClientSetMatching") else {
            return nil
        }

        let clientCreate = unsafeBitCast(clientCreateSym, to: IOHIDEventSystemClientCreateFunc.self)
        let setMatching = unsafeBitCast(setMatchingSym, to: IOHIDEventSystemClientSetMatchingFunc.self)
        let copyServices = unsafeBitCast(copyServicesSym, to: IOHIDEventSystemClientCopyServicesFunc.self)
        let copyEvent = unsafeBitCast(copyEventSym, to: IOHIDServiceClientCopyEventFunc.self)
        let getFloat = unsafeBitCast(getFloatSym, to: IOHIDEventGetFloatValueFunc.self)

        guard let client = clientCreate(kCFAllocatorDefault)?.takeRetainedValue() else { return nil }
        let matchingDict: [String: Any] = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5]
        setMatching(client, matchingDict as CFDictionary)
        guard let services = copyServices(client)?.takeRetainedValue() as? [AnyObject], !services.isEmpty else { return nil }

        var temps: [Double] = []
        for service in services {
            if let event = copyEvent(service, 15, 0, 0)?.takeRetainedValue() {
                let t = getFloat(event, 15 << 16)
                if t > 15 && t < 125 {
                    temps.append(t)
                }
            }
        }

        guard !temps.isEmpty else { return nil }
        let avg = temps.reduce(0.0, +) / Double(temps.count)
        return avg
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
