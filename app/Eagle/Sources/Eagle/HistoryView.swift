import EagleCore
import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: AppModel
    @State private var selectedEntry: HistoryEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderBlock(title: "History", subtitle: "Local receipts for confirmed operations.")

            HStack {
                Button {
                    model.reloadHistory()
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                Spacer()
                Text("\(model.history.count) receipts")
                    .foregroundStyle(.secondary)
            }

            HSplitView {
                List(model.history, selection: $selectedEntry) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.tool.title)
                                .font(.headline)
                            Spacer()
                            Text(entry.succeeded ? "Done" : "Check")
                                .foregroundStyle(entry.succeeded ? .green : .orange)
                        }
                        Text(entry.target ?? entry.commandLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(entry.completedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .tag(entry as HistoryEntry?)
                }
                .frame(minWidth: 320)

                if let selectedEntry {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedEntry.commandLine)
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                        ConsoleView(text: selectedEntry.outputPreview)
                    }
                    .padding(.leading, 12)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Select a receipt")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding(28)
    }
}
