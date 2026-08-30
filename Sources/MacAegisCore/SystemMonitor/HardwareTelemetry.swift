import Foundation
import Darwin
import MachO

public struct SystemMetrics: Sendable {
    public let cpuUsagePercent: Double
    public let memoryTotalBytes: UInt64
    public let memoryUsedBytes: UInt64
    public let memoryFreeBytes: UInt64
    public let memoryPressure: MemoryPressureLevel
    public let swapTotalBytes: UInt64
    public let swapUsedBytes: UInt64

    public var memoryUsagePercent: Double {
        guard memoryTotalBytes > 0 else { return 0 }
        return Double(memoryUsedBytes) / Double(memoryTotalBytes) * 100.0
    }

    public var formattedMemoryUsed: String {
        return ByteFormatter.format(Int64(memoryUsedBytes))
    }

    public var formattedMemoryTotal: String {
        return ByteFormatter.format(Int64(memoryTotalBytes))
    }

    public var formattedSwapUsed: String {
        return ByteFormatter.format(Int64(swapUsedBytes))
    }
}

public enum MemoryPressureLevel: String, Sendable {
    case normal = "良好"
    case warning = "偏高"
    case critical = "极度紧张"

    public var badge: String {
        switch self {
        case .normal: return "🟢"
        case .warning: return "🟡"
        case .critical: return "🔴"
        }
    }
}

public final class HardwareTelemetry: @unchecked Sendable {
    public static let shared = HardwareTelemetry()

    private var previousCPUTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?
    private let lock = NSLock()

    private init() {}

    /// Query current system CPU, RAM, and Swap metrics with zero shell overhead
    public func fetchMetrics() -> SystemMetrics {
        lock.lock()
        defer { lock.unlock() }

        let cpuUsage = getCPUUsage()
        let (totalMem, usedMem, freeMem, pressure) = getMemoryUsage()
        let (swapTotal, swapUsed) = getSwapUsage()

        return SystemMetrics(
            cpuUsagePercent: cpuUsage,
            memoryTotalBytes: totalMem,
            memoryUsedBytes: usedMem,
            memoryFreeBytes: freeMem,
            memoryPressure: pressure,
            swapTotalBytes: swapTotal,
            swapUsedBytes: swapUsed
        )
    }

    private func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numProcessors: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numProcessors,
            &cpuInfo,
            &numCpuInfo
        )

        guard result == KERN_SUCCESS, let cpuData = cpuInfo else {
            return 0.0
        }

        var totalUser: UInt64 = 0
        var totalSystem: UInt64 = 0
        var totalIdle: UInt64 = 0
        var totalNice: UInt64 = 0

        cpuData.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(numProcessors)) { ptr in
            for i in 0..<Int(numProcessors) {
                let load = ptr[i]
                totalUser += UInt64(load.cpu_ticks.0)
                totalSystem += UInt64(load.cpu_ticks.1)
                totalIdle += UInt64(load.cpu_ticks.2)
                totalNice += UInt64(load.cpu_ticks.3)
            }
        }

        _ = vm_deallocate(
            mach_task_self_,
            vm_address_t(bitPattern: cpuData),
            vm_size_t(numCpuInfo * UInt32(MemoryLayout<integer_t>.stride))
        )

        guard let prev = previousCPUTicks else {
            previousCPUTicks = (totalUser, totalSystem, totalIdle, totalNice)
            return 0.0
        }

        let userDiff = totalUser - prev.user
        let sysDiff = totalSystem - prev.system
        let idleDiff = totalIdle - prev.idle
        let niceDiff = totalNice - prev.nice
        let totalTicks = userDiff + sysDiff + idleDiff + niceDiff

        previousCPUTicks = (totalUser, totalSystem, totalIdle, totalNice)

        guard totalTicks > 0 else { return 0.0 }
        let usage = Double(userDiff + sysDiff + niceDiff) / Double(totalTicks) * 100.0
        return min(max(usage, 0.0), 100.0)
    }

    private func getMemoryUsage() -> (total: UInt64, used: UInt64, free: UInt64, pressure: MemoryPressureLevel) {
        var totalMemory: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0)

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return (totalMemory, 0, totalMemory, .normal)
        }

        let pageSize = UInt64(getpagesize())
        let active = UInt64(vmStats.active_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let free = UInt64(vmStats.free_count) * pageSize

        let used = active + wired + compressed

        // Compute pressure
        let ratio = totalMemory > 0 ? Double(used) / Double(totalMemory) : 0.0
        let pressure: MemoryPressureLevel
        if ratio > 0.85 {
            pressure = .critical
        } else if ratio > 0.70 {
            pressure = .warning
        } else {
            pressure = .normal
        }

        return (totalMemory, used, free, pressure)
    }

    private func getSwapUsage() -> (total: UInt64, used: UInt64) {
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        let result = sysctlbyname("vm.swapusage", &swapUsage, &size, nil, 0)

        guard result == 0 else {
            return (0, 0)
        }

        return (UInt64(swapUsage.xsu_total), UInt64(swapUsage.xsu_used))
    }
}
