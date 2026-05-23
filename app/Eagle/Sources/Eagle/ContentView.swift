import EagleCore
import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        NavigationSplitView {
            List(selection: $model.destination) {
                NavigationLink(value: AppDestination.dashboard) {
                    Label("Dashboard", systemImage: "rectangle.grid.2x2")
                }

                Section("Tools") {
                    ForEach(MoleTool.allCases) { tool in
                        NavigationLink(value: AppDestination.tool(tool)) {
                            Label(tool.title, systemImage: tool.systemImage)
                        }
                    }
                }

                Section("Local") {
                    NavigationLink(value: AppDestination.history) {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    NavigationLink(value: AppDestination.settings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("Eagle")
            .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
        } detail: {
            detailView
                .safeAreaInset(edge: .bottom) {
                    StatusBar(model: model)
                }
        }
        .task {
            await model.bootstrap()
        }
        .sheet(item: $model.reviewSession) { _ in
            ReviewSheet(model: model)
                .frame(minWidth: 760, minHeight: 560)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch model.destination {
        case .dashboard, .none:
            DashboardView(model: model)
        case .tool(let tool):
            ToolDetailView(model: model, tool: tool)
        case .history:
            HistoryView(model: model)
        case .settings:
            SettingsView(model: model)
        }
    }
}

private struct StatusBar: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            if model.isRunning {
                ProgressView()
                    .controlSize(.small)
            }
            Text(model.statusMessage)
                .lineLimit(1)
            Spacer()
            Circle()
                .fill(model.adapterReady ? .green : .orange)
                .frame(width: 8, height: 8)
            Text(model.adapterReady ? "Mole connected" : "Mole missing")
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .font(.footnote)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
