import EagleCore
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderBlock(
                    title: "A sharp-eyed utility for your Mac.",
                    subtitle: "Scan locally, review clearly, run only after confirmation, then keep a local receipt."
                )

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

struct HeaderBlock: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Eagle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
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
