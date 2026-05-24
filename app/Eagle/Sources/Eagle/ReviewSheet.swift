import SwiftUI

struct ReviewSheet: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review \(model.reviewSession?.tool.title ?? "Action")")
                        .font(.title2.weight(.semibold))
                    Text(model.reviewSession?.target ?? "No target required")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    model.reviewSession = nil
                    model.reviewAccepted = false
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            }

            Text("Eagle checked this action first. It will not run until you review the details and confirm.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ConsoleView(text: model.reviewSession?.preview.combinedOutput ?? "")

            Toggle("I reviewed this and want Eagle to run it.", isOn: $model.reviewAccepted)

            HStack {
                Spacer()
                Button(role: .cancel) {
                    model.reviewSession = nil
                    model.reviewAccepted = false
                    dismiss()
                } label: {
                    Text("Not Now")
                }
                Button {
                    Task { await model.executeReview() }
                } label: {
                    Label("Run This Action", systemImage: "checkmark.shield")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canExecuteReview)
            }
        }
        .padding(24)
    }
}
