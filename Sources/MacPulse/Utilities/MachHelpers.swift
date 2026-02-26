import Foundation
import Darwin

public enum MachHelpers {
    public static func hostProcessorInfo() -> (overall: Double, perCore: [Double])? {
        var numCPU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPU,
            &cpuInfo,
            &cpuInfoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return nil
        }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: cpuInfo),
                vm_size_t(Int(cpuInfoCount) * MemoryLayout<integer_t>.stride)
            )
        }

        var ticks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
        for i in 0..<Int(numCPU) {
            let offset = Int(CPU_STATE_MAX) * i
            ticks.append((
                user: UInt64(cpuInfo[offset + Int(CPU_STATE_USER)]),
                system: UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)]),
                idle: UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)]),
                nice: UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)])
            ))
        }

        return (overall: 0, perCore: ticks.map { _ in 0 })
    }

    public struct CPURawTicks: Sendable {
        public var user: UInt64
        public var system: UInt64
        public var idle: UInt64
        public var nice: UInt64

        public var total: UInt64 { user + system + idle + nice }
        public var active: UInt64 { user + system + nice }

        public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
            self.user = user
            self.system = system
            self.idle = idle
            self.nice = nice
        }
    }

    public static func rawProcessorTicks() -> [CPURawTicks]? {
        var numCPU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPU,
            &cpuInfo,
            &cpuInfoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return nil
        }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: cpuInfo),
                vm_size_t(Int(cpuInfoCount) * MemoryLayout<integer_t>.stride)
            )
        }

        var ticks: [CPURawTicks] = []
        for i in 0..<Int(numCPU) {
            let offset = Int(CPU_STATE_MAX) * i
            ticks.append(CPURawTicks(
                user: UInt64(cpuInfo[offset + Int(CPU_STATE_USER)]),
                system: UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)]),
                idle: UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)]),
                nice: UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)])
            ))
        }

        return ticks
    }

    public static func vmStatistics64() -> vm_statistics64? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    intPtr,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else { return nil }
        return stats
    }

    public static var pageSize: UInt64 {
        UInt64(vm_kernel_page_size)
    }

    public static var physicalMemory: UInt64 {
        ProcessInfo.processInfo.physicalMemory
    }
}
