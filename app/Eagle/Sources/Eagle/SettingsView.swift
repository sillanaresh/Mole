import EagleCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderBlock(title: "Settings", subtitle: "Local paths, support link, and launch readiness.")

                GroupBox("Mole Adapter") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Path to mole or mo", text: $model.settings.moleBinaryPath)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Button {
                                model.autoDetectMole()
                            } label: {
                                Label("Auto-detect", systemImage: "scope")
                            }
                            Button {
                                model.saveSettings()
                            } label: {
                                Label("Save", systemImage: "square.and.arrow.down")
                            }
                            Spacer()
                        }
                        Text(model.activeMolePath.isEmpty ? "No Mole binary found." : model.activeMolePath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Safety") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Skip privileged authorization prompts from the app", isOn: $model.settings.skipPrivilegedAuthorization)
                        Text("When enabled, Mole receives MOLE_TEST_NO_AUTH=1 so the app does not hang on sudo prompts. Disable only when testing privileged behavior deliberately.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Stepper(value: $model.settings.commandTimeoutSeconds, in: 30...1800, step: 30) {
                            Text("Command timeout: \(Int(model.settings.commandTimeoutSeconds)) seconds")
                        }

                        Button {
                            model.saveSettings()
                        } label: {
                            Label("Save Safety Settings", systemImage: "checkmark.circle")
                        }
                    }
                    .padding(.vertical, 6)
                }

                GroupBox("Support") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Optional support URL", text: $model.settings.supportURL)
                            .textFieldStyle(.roundedBorder)
                        Text("Support is optional and never unlocks features.")
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
                        Text("Eagle is a separate Mac app concept built around the MIT-licensed Mole CLI by Tw93 and contributors.")
                        Text("The app preserves Mole attribution, keeps cleanup local, and routes destructive work through Mole command flows.")
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
