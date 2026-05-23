import EagleCore
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderBlock(
                    title: "Clean up your Mac without needing to understand the tools.",
                    subtitle: "Start with one guided scan. Eagle explains the plan in plain language, asks before changing anything, and keeps the advanced controls nearby."
                )

                GuidedCleanupPanel(model: model)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 14)], spacing: 14) {
                    MetricCard(
                        title: "Health",
                        value: model.statusSnapshot?.healthScore.map(String.init) ?? "--",
                        detail: model.statusSnapshot?.healthScoreMessage ?? "Run Status to refresh"
                    )
                    MetricCard(
                        title: "Host",
                        value: model.statusSnapshot?.host ?? "Mac",
                        detail: model.statusSnapshot?.uptime ?? "Local only"
                    )
                    MetricCard(
                        title: "Receipts",
                        value: "\(model.history.count)",
                        detail: "Stored in Application Support"
                    )
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Advanced tools")
                            .font(.title2.weight(.semibold))
                        Text("Use these when you want direct control over one area.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                    ForEach(MoleTool.allCases) { tool in
                        Button {
                            model.destination = .tool(tool)
                        } label: {
                            ToolCard(tool: tool)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(28)
        }
    }
}

private struct GuidedCleanupPanel: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(
                            colors: [Color(nsColor: .systemTeal), Color(nsColor: .systemBlue)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Simple cleanup")
                        .font(.title2.weight(.semibold))
                    Text("Run one scan across everyday cleanup, maintenance, project clutter, and old installers. Eagle previews first and leaves optional areas unchecked until you review them.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    Task { await model.startGuidedScan() }
                } label: {
                    Label(scanButtonTitle, systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.isRunning || model.guidedPlan?.state == .scanning || model.guidedPlan?.state == .running)
            }

            if let guidedPlan = model.guidedPlan {
                GuidedPlanSummary(model: model, plan: guidedPlan)
            } else {
                HStack(spacing: 12) {
                    GuidedPromise(title: "Plain language", detail: "No JSON unless you open technical output.")
                    GuidedPromise(title: "Preview first", detail: "Scan results come before any cleanup.")
                    GuidedPromise(title: "You choose", detail: "Riskier areas stay optional.")
                }
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var scanButtonTitle: String {
        switch model.guidedPlan?.state {
        case .ready, .finished:
            return "Scan Again"
        case .scanning:
            return "Scanning..."
        case .running:
            return "Running..."
        case .idle, .none:
            return "Scan My Mac"
        }
    }
}

private struct GuidedPlanSummary: View {
    @ObservedObject var model: AppModel
    let plan: GuidedCleanupPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if plan.state == .scanning || plan.state == .running {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if plan.items.isEmpty {
                Text(plan.state == .scanning ? "Checking your Mac now..." : "No cleanup previews are ready yet.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
                    ForEach(plan.items) { item in
                        GuidedItemCard(item: item, isSelected: model.guidedSelectedTools.contains(item.tool))
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        model.guidedReviewPresented = true
                    } label: {
                        Label("Review Cleanup Plan", systemImage: "checklist.checked")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(plan.readyItems.isEmpty || model.isRunning)

                    Text("\(model.guidedSelectedItems.count) selected")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        model.destination = .tool(.analyze)
                    } label: {
                        Label("Inspect Disk", systemImage: "chart.pie")
                    }
                }
            }
        }
    }

    private var title: String {
        switch plan.state {
        case .idle:
            return "Ready"
        case .scanning:
            return "Scanning your Mac"
        case .ready:
            return "Cleanup plan ready"
        case .running:
            return "Running selected cleanup"
        case .finished:
            return "Cleanup finished"
        }
    }
}

private struct GuidedItemCard: View {
    let item: GuidedCleanupItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.tool.systemImage)
                    .foregroundStyle(item.previewSucceeded ? .blue : item.previewFoundNothing ? .secondary : .orange)
                Spacer()
                Text(status)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
            }
            Text(item.title)
                .font(.headline)
            Text(item.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var status: String {
        guard item.previewSucceeded else {
            return item.previewFoundNothing ? "Nothing found" : "Needs review"
        }
        return isSelected ? "Selected" : item.recommendation
    }

    private var statusColor: Color {
        if item.previewSucceeded {
            return isSelected ? .green : .secondary
        }
        return item.previewFoundNothing ? .secondary : .orange
    }
}

private struct GuidedPromise: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct HeaderBlock: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                AppIconMark(size: 36)
                Text("Eagle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.largeTitle.weight(.semibold))
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ToolCard: View {
    let tool: MoleTool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tool.systemImage)
                    .font(.title3)
                Spacer()
                Text(tool.riskLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tool.isDestructiveWorkflow ? .orange : .green)
            }
            Text(tool.title)
                .font(.headline)
            Text(tool.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
