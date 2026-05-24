import EagleCore
import SwiftUI

struct GuidedReviewSheet: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let isRunning = model.guidedPlan?.state == .running
        let isFinished = model.guidedPlan?.state == .finished

        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(isFinished ? "Cleanup summary" : "Review simple cleanup")
                        .font(.title2.weight(.semibold))
                    Text(headerSubtitle(isRunning: isRunning, isFinished: isFinished))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    model.guidedReviewPresented = false
                    model.guidedAccepted = false
                    dismiss()
                } label: {
                    Label(isFinished ? "Done" : "Cancel", systemImage: "xmark")
                }
                .disabled(isRunning)
            }

            if let plan = model.guidedPlan {
                if isRunning {
                    RunningBanner(tool: model.guidedRunningTool)
                } else if isFinished {
                    ReceiptBanner(plan: plan)
                }

                List(plan.items) { item in
                    GuidedReviewRow(
                        item: item,
                        isRunning: isRunning,
                        isFinished: isFinished,
                        isSelected: Binding(
                            get: { model.guidedSelectedTools.contains(item.tool) },
                            set: { selected in
                                if selected {
                                    model.guidedSelectedTools.insert(item.tool)
                                } else {
                                    model.guidedSelectedTools.remove(item.tool)
                                }
                            }
                        )
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if !isFinished {
                    Toggle("I understand this plan and want Eagle to clean the selected items.", isOn: $model.guidedAccepted)
                        .disabled(isRunning)
                }

                HStack {
                    Text(summaryText(isFinished: isFinished, plan: plan))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(role: .cancel) {
                        model.guidedReviewPresented = false
                        model.guidedAccepted = false
                        dismiss()
                    } label: {
                        Text(isFinished ? "Done" : "Not Now")
                    }
                    .disabled(isRunning)
                    if !isFinished {
                        Button {
                            Task { await model.executeGuidedCleanup() }
                        } label: {
                            if isRunning {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Running Cleanup")
                                }
                            } else {
                                Label("Run Selected Cleanup", systemImage: "checkmark.shield")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!model.canRunGuidedCleanup || isRunning)
                    }
                }

                RawOutputDisclosure(text: model.commandOutput)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Run a scan first", systemImage: "magnifyingglass")
                        .font(.headline)
                    Text("The simple cleanup review appears after Eagle previews your Mac.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .padding(24)
    }

    private func headerSubtitle(isRunning: Bool, isFinished: Bool) -> String {
        if isRunning {
            return "Eagle is cleaning the items you selected. Keep this window open until the summary appears."
        }
        if isFinished {
            return "These are the items Eagle finished cleaning. Details are available below if you need them."
        }
        return "Suggested items are checked. Optional areas stay unchecked until you choose them."
    }

    private func summaryText(isFinished: Bool, plan: GuidedCleanupPlan) -> String {
        if isFinished {
            return "\(plan.completedTools.count) actions completed"
        }
        return "\(model.guidedSelectedItems.count) actions selected"
    }
}

private struct GuidedReviewRow: View {
    let item: GuidedCleanupItem
    let isRunning: Bool
    let isFinished: Bool
    @Binding var isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: $isSelected)
                .labelsHidden()
                .disabled(!item.previewSucceeded || isRunning || isFinished)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(item.title, systemImage: item.tool.systemImage)
                        .font(.headline)
                    Spacer()
                    Text(item.statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                }

                Text(item.summary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.previewSucceeded {
                    Text(item.previewIssueText ?? "This action was left off because its preview did not complete cleanly.")
                        .font(.footnote)
                        .foregroundStyle(item.previewFoundNothing ? Color.secondary : Color.orange)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var statusColor: Color {
        if item.previewSucceeded {
            return .secondary
        }
        return item.previewFoundNothing ? .secondary : .orange
    }
}

private struct RunningBanner: View {
    let tool: MoleTool?

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 3) {
                Text("Cleanup is running")
                    .font(.headline)
                Text(tool.map { "Now running \($0.title)." } ?? "Preparing the selected actions.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ReceiptBanner: View {
    let plan: GuidedCleanupPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Cleanup finished", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.green)
            if plan.completedTools.isEmpty {
                Text("No selected item was cleaned. Open details below to see what happened.")
                    .foregroundStyle(.secondary)
            } else {
                Text("Completed: \(plan.completedTools.map(\.title).joined(separator: ", "))")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
