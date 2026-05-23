import EagleCore
import SwiftUI

struct GuidedReviewSheet: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Review simple cleanup")
                        .font(.title2.weight(.semibold))
                    Text("Suggested items are checked. Optional areas stay unchecked until you choose them.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    model.guidedReviewPresented = false
                    model.guidedAccepted = false
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            }

            if let plan = model.guidedPlan {
                List(plan.items) { item in
                    GuidedReviewRow(
                        item: item,
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

                Toggle("I reviewed the plan and want Eagle to run the selected cleanup actions.", isOn: $model.guidedAccepted)

                HStack {
                    Text("\(model.guidedSelectedItems.count) actions selected")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(role: .cancel) {
                        model.guidedReviewPresented = false
                        model.guidedAccepted = false
                        dismiss()
                    } label: {
                        Text("Not Now")
                    }
                    Button {
                        Task { await model.executeGuidedCleanup() }
                    } label: {
                        Label("Run Selected Cleanup", systemImage: "checkmark.shield")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canRunGuidedCleanup)
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
}

private struct GuidedReviewRow: View {
    let item: GuidedCleanupItem
    @Binding var isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: $isSelected)
                .labelsHidden()
                .disabled(!item.previewSucceeded)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(item.title, systemImage: item.tool.systemImage)
                        .font(.headline)
                    Spacer()
                    Text(item.statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.previewSucceeded ? Color.secondary : Color.orange)
                }

                Text(item.summary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.previewSucceeded {
                    Text("This action was left off because its preview did not complete cleanly.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
