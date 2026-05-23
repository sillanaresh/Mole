# Eagle macOS App

Eagle is the native macOS layer for the Mole cleanup workflows. It keeps the product promise from the website:

- scan locally,
- preview before destructive work,
- require explicit confirmation,
- route execution through Mole,
- save a local receipt.

The app is a Swift Package so it can be built without a generated Xcode project.

## Build

From the repository root:

```bash
make app-build
```

Or directly:

```bash
cd app/Eagle
swift build
```

## Run During Development

```bash
cd app/Eagle
swift run Eagle
```

The adapter auto-detects the repository `mole` script, bundled `Mole/mole` resources in a packaged app, or installed `mo` / `mole` binaries in Homebrew paths.

## Test

```bash
make app-test
```

## Package A Preview App

```bash
make app-package
```

This creates:

```text
app/Eagle/.build/Eagle.app
```

For a tester archive:

```bash
make app-package-zip
```

This creates:

```text
app/Eagle/.build/Eagle.zip
```

For the website download, build the drag-to-Applications DMG:

```bash
make app-package-dmg
```

This creates:

```text
app/Eagle/.build/Eagle.dmg
```

## Sign And Notarize

For a Developer ID build:

```bash
EAGLE_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app-package-zip
```

For notarization:

```bash
export EAGLE_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="TEAMID"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
make app-notarize
```

Preview packages are ad-hoc signed by default. To disable that local-only signature:

```bash
EAGLE_AD_HOC_SIGN=0 make app-package-zip
```

The package script also builds the Go analyzer/status binaries and copies the Mole shell runtime into the app bundle under `Contents/Resources/Mole`.

For a public release, this ad-hoc signed bundle still needs:

- Apple Developer ID signing,
- notarization,
- a DMG or ZIP upload target,
- `EAGLE_DOWNLOAD_URL` configured in Vercel,
- `site/config.js` changed to `downloadUrl: "/api/download"`.

## Safety Notes

The app intentionally defaults to `skipPrivilegedAuthorization = true`. That sends `MOLE_TEST_NO_AUTH=1` to Mole so the native app does not hang on sudo prompts. Users can disable the setting while testing privileged behavior, but the production path should eventually use a proper privileged helper rather than hidden terminal prompts.

Destructive workflows are locked behind:

1. Mole dry-run preview.
2. Review sheet.
3. User confirmation toggle.
4. Execution through Mole command flows.
5. Local receipt in `~/Library/Application Support/Eagle/history.json`.
