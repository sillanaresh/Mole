import Foundation

public struct StatusSnapshot: Codable, Equatable, Sendable {
    public var collectedAt: String?
    public var host: String?
    public var platform: String?
    public var uptime: String?
    public var healthScore: Int?
    public var healthScoreMessage: String?
    public var cpu: CPUStatus?
    public var memory: MemoryStatus?
    public var disks: [DiskStatus]?
    public var batteries: [BatteryStatus]?
    public var topProcesses: [ProcessStatus]?

    enum CodingKeys: String, CodingKey {
        case collectedAt = "collected_at"
        case host
        case platform
        case uptime
        case healthScore = "health_score"
        case healthScoreMessage = "health_score_msg"
        case cpu
        case memory
        case disks
        case batteries
        case topProcesses = "top_processes"
    }

    public init(
        collectedAt: String? = nil,
        host: String? = nil,
        platform: String? = nil,
        uptime: String? = nil,
        healthScore: Int? = nil,
        healthScoreMessage: String? = nil,
        cpu: CPUStatus? = nil,
        memory: MemoryStatus? = nil,
        disks: [DiskStatus]? = nil,
        batteries: [BatteryStatus]? = nil,
        topProcesses: [ProcessStatus]? = nil
    ) {
        self.collectedAt = collectedAt
        self.host = host
        self.platform = platform
        self.uptime = uptime
        self.healthScore = healthScore
        self.healthScoreMessage = healthScoreMessage
        self.cpu = cpu
        self.memory = memory
        self.disks = disks
        self.batteries = batteries
        self.topProcesses = topProcesses
    }
}

public struct CPUStatus: Codable, Equatable, Sendable {
    public var usage: Double?
    public var load1: Double?
    public var load5: Double?
    public var load15: Double?
    public var coreCount: Int?
    public var logicalCPU: Int?

    enum CodingKeys: String, CodingKey {
        case usage
        case load1
        case load5
        case load15
        case coreCount = "core_count"
        case logicalCPU = "logical_cpu"
    }
}

public struct MemoryStatus: Codable, Equatable, Sendable {
    public var used: UInt64?
    public var total: UInt64?
    public var usedPercent: Double?
    public var pressure: String?
    public var swapUsed: UInt64?
    public var swapTotal: UInt64?

    enum CodingKeys: String, CodingKey {
        case used
        case total
        case usedPercent = "used_percent"
        case pressure
        case swapUsed = "swap_used"
        case swapTotal = "swap_total"
    }
}

public struct DiskStatus: Codable, Equatable, Sendable, Identifiable {
    public var id: String { mount ?? device ?? UUID().uuidString }
    public var mount: String?
    public var device: String?
    public var used: UInt64?
    public var total: UInt64?
    public var usedPercent: Double?
    public var external: Bool?

    enum CodingKeys: String, CodingKey {
        case mount
        case device
        case used
        case total
        case usedPercent = "used_percent"
        case external
    }
}

public struct BatteryStatus: Codable, Equatable, Sendable, Identifiable {
    public var id: String { name ?? UUID().uuidString }
    public var name: String?
    public var percent: Double?
    public var charging: Bool?
    public var health: String?
}

public struct ProcessStatus: Codable, Equatable, Sendable, Identifiable {
    public var id: Int { pid ?? 0 }
    public var pid: Int?
    public var name: String?
    public var command: String?
    public var cpu: Double?
    public var memory: Double?
}
