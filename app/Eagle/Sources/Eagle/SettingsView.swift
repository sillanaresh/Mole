import EagleCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderBlock(title: "Settings", subtitle: "Connection, safety, and support options.")

                GroupBox("Cleanup Engine") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Path to Eagle cleanup engine", text: $model.settings.moleBinaryPath)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Button {
                                model.autoDetectMole()
                            } label: {
                                Label("Find Automatically", systemImage: "scope")
                            }
                            Button {
                                model.saveSettings()
                            } label: {
                                Label("Save", systemImage: "square.and.arrow.down")
                            }
                            Spacer()
                        }
                        Text(model.activeMolePath.isEmpty ? "Cleanup engine not found." : model.activeMolePath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Safety") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Avoid password prompts inside Eagle", isOn: $model.settings.skipPrivilegedAuthorization)
                        Text("Keep this on for normal use. Some deeper cleanup may be skipped instead of asking for a password.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Stepper(value: $model.settings.commandTimeoutSeconds, in: 30...1800, step: 30) {
                            Text("Command timeout: \(Int(model.settings.commandTimeoutSeconds)) seconds")
                        }

                        Button {
                            model.saveSettings()
                        } label: {
                            Label("Save Safety Options", systemImage: "checkmark.circle")
                        }
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Support") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Optional support URL", text: $model.settings.supportURL)
                            .textFieldStyle(.roundedBorder)
                        Text("Support is optional. Eagle works the same either way.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            model.saveSettings()
                        } label: {
                            Label("Save Support URL", systemImage: "heart")
                        }
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Attribution") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Eagle uses the open-source Mole cleanup project by Tw93 and contributors.")
                        Text("The app includes the MIT license and keeps cleanup work on your Mac.")
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    .padding(.vertical, 6)
                }
            }
            .padding(28)
        }
    }
}
