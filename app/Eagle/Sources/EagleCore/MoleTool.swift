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
        case .purge: return "Project Cleanup"
        case .installer: return "Installer Cleanup"
        }
    }

    public var subtitle: String {
        switch self {
        case .clean:
            return "Caches, logs, temporary files, browser clutter, and build leftovers."
        case .uninstall:
            return "Remove an app and the extra files it leaves behind."
        case .optimize:
            return "Basic Mac maintenance such as DNS, logs, indexes, and service refreshes."
        case .analyze:
            return "Find large folders and understand where your storage is going."
        case .status:
            return "Check memory, CPU, disk, battery, uptime, and overall Mac health."
        case .purge:
            return "Clean build folders and dependency caches inside development projects."
        case .installer:
            return "Old DMGs, PKGs, ZIPs, and duplicate installer downloads."
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
            return "Check only"
        }
    }
}
