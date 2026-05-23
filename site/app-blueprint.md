# Eagle Mac App Blueprint

## Product Principle

Eagle is free and local-first. The product should feel sharp-eyed, careful, and precise: useful without being pushy. Support is optional and never unlocks features.

## Current Repo Status

A SwiftUI starter app now lives in `app/Eagle`. It includes the Mole adapter, dry-run review flow, local receipts, settings, status JSON parsing, analyze JSON parsing, an ad-hoc signed `.app` packaging script, and a first real dashboard screenshot for the website.

## Recommended Stack

- SwiftUI macOS app.
- Bundled Mole CLI or local command adapter.
- Local settings with `UserDefaults`.
- Operation history as local JSON.
- No license system.
- Optional support link from shared config.

## Main Surfaces

- **Clean**: cache, logs, browser temp files, developer artifacts, AI-tool leftovers, communication/design app caches.
- **Uninstall**: app removal plus leftovers, launch agents, login items, preferences, Dock entries, recoverable by Trash where possible.
- **Optimize**: safe maintenance tasks with explicit password explanation.
- **Analyze**: disk usage explorer using Mole analyzer capability or native wrapper.
- **Status**: CPU, memory, disk, network, battery, thermals, uptime, health, top processes.
- **Purge**: developer project artifact cleanup with boundary checks.
- **Installer Cleanup**: old DMG, PKG, ZIP, and redundant installer review.

## Action Pattern

Every destructive workflow must follow this sequence:

1. Preview/dry-run.
2. Grouped review with size, risk, destination, and skipped/protected paths.
3. Explicit confirmation.
4. Execution through Mole safety helpers.
5. Local receipt/history entry.

The current app implements this sequence for Clean, Uninstall, Optimize, Purge, and Installer Cleanup. Status and Analyze are read-only JSON surfaces.

## Support Prompt

Show softly after successful value moments, for example after freeing space or completing a clean scan. The prompt should never block the app, change available features, or imply payment is expected.
