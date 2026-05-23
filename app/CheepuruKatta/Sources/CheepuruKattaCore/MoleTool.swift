import Foundation

public enum MoleTool: String, CaseIterable, Codable, Identifiable, Sendable {
    case clean
    case uninstall
    case optimize
    case analyze
    case status
    case purge
    case installer

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .clean: return "Clean"
        case .uninstall: return "Uninstall"
        case .optimize: return "Optimize"
        case .analyze: return "Analyze"
        case .status: return "Status"
        case .purge: return "Purge"
        case .installer: return "Installer Cleanup"
        }
    }

    public var subtitle: String {
        switch self {
        case .clean:
            return "Caches, logs, browser temp files, and developer clutter."
        case .uninstall:
            return "Apps plus preferences, support files, launch agents, and safe leftovers."
        case .optimize:
            return "Maintenance tasks, indexes, logs, DNS, and macOS service refreshes."
        case .analyze:
            return "Disk usage explorer with JSON output for review."
        case .status:
            return "CPU, memory, disk, battery, process, and health snapshot."
        case .purge:
            return "Project artifacts such as dependency folders and build outputs."
        case .installer:
            return "Old DMGs, PKGs, ZIPs, and redundant installer archives."
        }
    }

    public var systemImage: String {
        switch self {
        case .clean: return "sparkles"
        case .uninstall: return "app.badge.checkmark"
        case .optimize: return "dial.high"
        case .analyze: return "chart.pie"
        case .status: return "waveform.path.ecg"
        case .purge: return "shippingbox"
        case .installer: return "externaldrive.badge.minus"
        }
    }

    public var isDestructiveWorkflow: Bool {
        switch self {
        case .clean, .uninstall, .optimize, .purge, .installer:
            return true
        case .analyze, .status:
            return false
        }
    }

    public var riskLabel: String {
        switch self {
        case .clean, .optimize:
            return "Standard"
        case .uninstall, .purge, .installer:
            return "Review"
        case .analyze, .status:
            return "Read only"
        }
    }
}
