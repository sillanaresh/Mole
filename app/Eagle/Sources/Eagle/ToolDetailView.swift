import EagleCore
import SwiftUI

struct ToolDetailView: View {
    @ObservedObject var model: AppModel
    let tool: MoleTool

    var body: some View {
        switch tool {
        case .status:
            StatusToolView(model: model)
        case .analyze:
            AnalyzeToolView(model: model)
        default:
            DestructiveToolView(model: model, tool: tool)
        }
    }
}

private struct DestructiveToolView: View {
    @ObservedObject var model: AppModel
    let tool: MoleTool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderBlock(title: tool.title, subtitle: tool.subtitle)

                if tool == .uninstall {
                    TextField("Application name, for example Slack", text: $model.uninstallTarget)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 460)
                }

                HStack(spacing: 10) {
                    Button {
                        Task { await model.preview(tool) }
                    } label: {
                        Label("Preview", systemImage: "doc.text.magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isRunning)

                    Button {
                        model.commandOutput = ""
                    } label: {
                        Label("Clear Output", systemImage: "xmark.circle")
                    }
                    .disabled(model.commandOutput.isEmpty)
                }

                SafetyStrip(tool: tool)
                ConsoleView(text: model.commandOutput)
                    .frame(height: 300)
            }
            .padding(28)
        }
    }
}

private struct SafetyStrip: View {
    let tool: MoleTool

    var body: some View {
        HStack(spacing: 12) {
            SafetyItem(title: "Preview first", detail: "Dry-run runs before changes.")
            SafetyItem(title: "Confirmation", detail: "Execution is locked behind review.")
            SafetyItem(title: "Receipts", detail: "A local history entry is saved.")
            SafetyItem(title: "Routing", detail: tool == .uninstall ? "Trash by default." : "Mole safety helpers.")
        }
    }
}

private struct SafetyItem: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct StatusToolView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderBlock(title: "Status", subtitle: MoleTool.status.subtitle)

                Button {
                    Task { await model.refreshStatus() }
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isRunning)

                if let snapshot = model.statusSnapshot {
                    StatusSnapshotView(snapshot: snapshot)
                }

                RawOutputDisclosure(text: model.commandOutput)
            }
            .padding(28)
        }
    }
}

private struct StatusSnapshotView: View {
    let snapshot: StatusSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                SmallDataCard(title: "Health", value: snapshot.healthScore.map(String.init) ?? "--")
                SmallDataCard(title: "CPU", value: percent(snapshot.cpu?.usage))
                SmallDataCard(title: "Memory", value: percent(snapshot.memory?.usedPercent))
                SmallDataCard(title: "Uptime", value: snapshot.uptime ?? "--")
            }

            if let disks = snapshot.disks, !disks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Disks")
                        .font(.headline)
                    ForEach(disks.prefix(5)) { disk in
                        HStack {
                            Text(disk.mount ?? disk.device ?? "Disk")
                            Spacer()
                            Text(percent(disk.usedPercent))
                                .foregroundStyle(.secondary)
                            Text(ByteCount.format(disk.total))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                .padding(14)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct AnalyzeToolView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderBlock(title: "Analyze", subtitle: MoleTool.analyze.subtitle)

                HStack {
                    TextField("Path to scan", text: $model.analyzePath)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await model.scanAnalyze() }
                    } label: {
                        Label("Scan", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isRunning)
                }

                if let report = model.analyzeReport {
                    AnalyzeReportView(report: report)
                }

                RawOutputDisclosure(text: model.commandOutput)
            }
            .padding(28)
        }
    }
}

private struct AnalyzeReportView: View {
    let report: AnalyzeReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SmallDataCard(title: "Path", value: report.path)
                SmallDataCard(title: "Total", value: ByteCount.format(report.totalSize))
                SmallDataCard(title: "Entries", value: "\(report.entries.count)")
            }

            List(report.entries.prefix(12)) { entry in
                HStack {
                    Image(systemName: entry.isDir ? "folder" : "doc")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading) {
                        Text(entry.name)
                            .lineLimit(1)
                        Text(entry.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(ByteCount.format(entry.size))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 3)
            }
            .frame(minHeight: 220)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct SmallDataCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ConsoleView: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text.isEmpty ? "Command output will appear here." : text)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(text.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .textSelection(.enabled)
                .padding(14)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator.opacity(0.4), lineWidth: 1)
        )
    }
}

private struct RawOutputDisclosure: View {
    let text: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ConsoleView(text: text)
                .frame(height: 260)
                .padding(.top, 10)
        } label: {
            Label("Raw command output", systemImage: "terminal")
                .font(.headline)
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .disabled(text.isEmpty)
    }
}

private func percent(_ value: Double?) -> String {
    guard let value else {
        return "--"
    }
    return "\(Int(value.rounded()))%"
}
