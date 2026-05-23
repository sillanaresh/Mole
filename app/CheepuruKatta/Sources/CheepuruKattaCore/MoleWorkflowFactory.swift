import Foundation

public enum MoleWorkflowError: LocalizedError, Equatable {
    case unsupportedPreview(MoleTool)
    case unsupportedExecution(MoleTool)
    case missingTarget(MoleTool)

    public var errorDescription: String? {
        switch self {
        case .unsupportedPreview(let tool):
            return "\(tool.title) does not use the destructive preview flow."
        case .unsupportedExecution(let tool):
            return "\(tool.title) cannot be executed from this review flow."
        case .missingTarget(let tool):
            return "\(tool.title) needs a target before it can run."
        }
    }
}

public struct MoleWorkflowFactory: Sendable {
    public var skipPrivilegedAuthorization: Bool
    public var timeoutSeconds: TimeInterval

    public init(skipPrivilegedAuthorization: Bool = true, timeoutSeconds: TimeInterval = 300) {
        self.skipPrivilegedAuthorization = skipPrivilegedAuthorization
        self.timeoutSeconds = timeoutSeconds
    }

    public func previewInvocation(for tool: MoleTool, target: String? = nil) throws -> MoleInvocation {
        guard tool.isDestructiveWorkflow else {
            throw MoleWorkflowError.unsupportedPreview(tool)
        }

        switch tool {
        case .clean:
            return MoleInvocation(
                arguments: ["clean", "--dry-run"],
                environment: environment(preview: true),
                timeoutSeconds: timeoutSeconds
            )
        case .uninstall:
            let app = try requiredTarget(target, for: tool)
            return MoleInvocation(
                arguments: ["uninstall", "--dry-run", app],
                environment: environment(preview: true),
                standardInput: "y\n",
                timeoutSeconds: timeoutSeconds
            )
        case .optimize:
            return MoleInvocation(
                arguments: ["optimize", "--dry-run"],
                environment: environment(preview: true),
                timeoutSeconds: timeoutSeconds
            )
        case .purge:
            return MoleInvocation(
                arguments: ["purge", "--dry-run"],
                environment: environment(preview: true),
                timeoutSeconds: timeoutSeconds
            )
        case .installer:
            return MoleInvocation(
                arguments: ["installer", "--dry-run"],
                environment: environment(preview: true),
                standardInput: "a\n\n",
                timeoutSeconds: timeoutSeconds
            )
        case .analyze, .status:
            throw MoleWorkflowError.unsupportedPreview(tool)
        }
    }

    public func executeInvocation(for tool: MoleTool, target: String? = nil) throws -> MoleInvocation {
        guard tool.isDestructiveWorkflow else {
            throw MoleWorkflowError.unsupportedExecution(tool)
        }

        switch tool {
        case .clean:
            return MoleInvocation(
                arguments: ["clean"],
                environment: environment(preview: false),
                timeoutSeconds: timeoutSeconds
            )
        case .uninstall:
            let app = try requiredTarget(target, for: tool)
            return MoleInvocation(
                arguments: ["uninstall", app],
                environment: environment(preview: false),
                standardInput: "y\n",
                timeoutSeconds: timeoutSeconds
            )
        case .optimize:
            return MoleInvocation(
                arguments: ["optimize"],
                environment: environment(preview: false),
                timeoutSeconds: timeoutSeconds
            )
        case .purge:
            return MoleInvocation(
                arguments: ["purge"],
                environment: environment(preview: false),
                timeoutSeconds: timeoutSeconds
            )
        case .installer:
            return MoleInvocation(
                arguments: ["installer"],
                environment: environment(preview: false),
                standardInput: "a\n\n",
                timeoutSeconds: timeoutSeconds
            )
        case .analyze, .status:
            throw MoleWorkflowError.unsupportedExecution(tool)
        }
    }

    public func statusInvocation() -> MoleInvocation {
        MoleInvocation(
            arguments: ["status", "--json"],
            environment: environment(preview: true),
            timeoutSeconds: min(timeoutSeconds, 45)
        )
    }

    public func analyzeInvocation(path: String?) -> MoleInvocation {
        var args = ["analyze", "--json"]
        if let path, !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args.append(path)
        }

        return MoleInvocation(
            arguments: args,
            environment: environment(preview: true),
            timeoutSeconds: timeoutSeconds
        )
    }

    private func requiredTarget(_ target: String?, for tool: MoleTool) throws -> String {
        let trimmed = target?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            throw MoleWorkflowError.missingTarget(tool)
        }
        return trimmed
    }

    private func environment(preview: Bool) -> [String: String] {
        var env = [
            "LC_ALL": "C",
            "LANG": "C",
            "TERM": "dumb",
            "MOLE_APP": "CheepuruKatta",
            "MOLE_DELETE_MODE": "trash",
            "NONINTERACTIVE": "1"
        ]

        if preview {
            env["MOLE_DRY_RUN"] = "1"
            env["MOLE_TEST_NO_AUTH"] = "1"
        } else if skipPrivilegedAuthorization {
            env["MOLE_TEST_NO_AUTH"] = "1"
        }

        return env
    }
}
