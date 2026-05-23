# Cheepuru Katta Handoff Helper

This file is a complete handoff for another coding agent. It explains what this repo is, what has already been done, what is not done yet, what needs to be done next, and the exact deployment/product decisions made so far.

## 1. Current Repo State

Workspace path:

```text
/Users/nareshsilla/conductor/workspaces/mole/tokyo
```

This is a fork/workspace based on the original open-source Mole repo:

```text
https://github.com/tw93/Mole
```

Current remotes:

```text
origin   https://github.com/sillanaresh/Mole.git
upstream https://github.com/tw93/Mole.git
```

Important branch state:

```text
Current branch: sillanaresh/repo-loopholes
Pushed branch:  origin/sillanaresh/repo-loopholes
```

The Cheepuru Katta work has been pushed to:

```text
origin/sillanaresh/repo-loopholes
```

It has not been merged to `main` unless someone does that after this handoff.

Useful sync commands:

```bash
git fetch origin upstream
git checkout sillanaresh/repo-loopholes
git pull origin sillanaresh/repo-loopholes
```

If the user wants this work on `main`, merge it deliberately:

```bash
git checkout main
git pull upstream main
git merge origin/sillanaresh/repo-loopholes
git push origin main
```

Use this Git identity for future commits:

```bash
git config user.name "Naresh Silla"
git config user.email "silla.naresh@gmail.com"
```

## 2. Product Goal

The user wants to turn the Mole open-source cleanup utility into a separate, polished Mac utility product called:

```text
Cheepuru Katta
```

Meaning:

- `Cheepuru Katta` means broom stick in Telugu.
- Brand metaphor: a broom that carefully clears digital dust from the Mac.

Product model:

- Free download.
- Donation/support-first.
- No forced payment.
- No license keys.
- No activation system.
- No device limits.
- No login/account requirement for v1.

Possible support links later:

- Buy Me a Coffee
- Ko-fi
- GitHub Sponsors
- Razorpay
- Any simple creator-support page

Product positioning:

- Calm, premium, trustworthy Mac utility.
- Scan first.
- Review clearly.
- Clean only after confirmation.
- Local-first.
- Privacy-respecting.
- Not scareware.
- Not a clone of the original Mole website/app.

Core sentence:

```text
Cheepuru Katta is a careful Mac utility that wraps Mole's local cleanup workflows in a beautiful, consent-first Mac app experience.
```

## 3. Legal / Open Source Assumptions

Original project:

```text
tw93/Mole
```

License:

```text
MIT
```

Commercialization/donation model is possible under MIT, but the product must:

- Preserve the original MIT license.
- Preserve copyright attribution.
- Clearly attribute Mole and contributors.
- Avoid pretending to be the original author/app.
- Avoid copying the original commercial website/visual identity.
- Build a distinct brand and product surface.

The website currently includes open-source attribution to Mole.

## 4. What Has Already Been Done

### 4.1 Website Prototype Built

A static marketing website has been created in:

```text
site/
```

Main files:

```text
site/index.html
site/styles.css
site/app.js
site/config.js
site/icon.svg
site/README.md
site/app-blueprint.md
```

The site is plain HTML/CSS/JS:

- No build step.
- No framework.
- Suitable for Vercel static deployment.

Website sections already implemented:

- Hero section.
- Native app screenshot section.
- Scan -> Review -> Clean workflow section.
- Capability grid.
- Safety/privacy promises.
- Open-source Mole attribution.
- Optional support/donation CTA.
- FAQ.
- Download CTA.

Capabilities represented on the website:

- Clean.
- Uninstall.
- Optimize.
- Analyze.
- Status.
- Purge.
- Installer Cleanup.

Important limitation:

- The website now includes a real dashboard screenshot.
- Additional screenshots are still needed for Clean review, Status, Analyze, History, and Settings.

### 4.2 Brand Name Changed

The product name is now:

```text
Cheepuru Katta
```

The website copy uses this name.

### 4.3 Broom Icon Added

Icon file:

```text
site/icon.svg
```

Design intent:

- Traditional bundled broom/stick broom.
- Should feel closer to a Telugu/Indian broom-stick reference, not a generic Western household broom.
- Vector SVG was used instead of generated bitmap because favicon/app-mark use is cleaner as SVG.

### 4.4 Vercel 404 Issue Fixed in Code

Problem observed:

- Vercel deployment succeeded but showed `404: NOT_FOUND`.

Cause:

- Vercel was deploying from the repo root.
- Website files live in `site/`.
- The first Vercel config existed inside `site/`, so Vercel did not read it when repo root was selected.

Fix added:

```text
vercel.json
```

The root `vercel.json` sets:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "outputDirectory": "site",
  "cleanUrls": true
}
```

The actual file also includes security/cache headers.

Correct Vercel dashboard settings now:

```text
Root Directory: Mole (root)
Framework Preset: Other
Build Command: empty
Output Directory: empty
Install Command: empty
```

The root `vercel.json` tells Vercel to serve from `site/`.

### 4.5 Download Button Safe Behavior Added

Config file:

```text
site/config.js
```

Current config:

```js
window.CHEEPURU_CONFIG = {
  supportUrl: "",
  downloadUrl: "/downloads/Cheepuru-Katta-preview.zip"
};
```

Because the native preview app exists now:

- The download button points to `site/downloads/Cheepuru-Katta-preview.zip`.
- The download note warns that the build is unsigned.
- This is acceptable for early testing, but not ideal for public launch.

When a real app exists, update config to:

```js
window.CHEEPURU_CONFIG = {
  supportUrl: "https://your-support-page.example",
  downloadUrl: "/downloads/Cheepuru-Katta-preview.zip"
};
```

### 4.6 Download Tracking Endpoint Added

File added:

```text
api/download.js
```

Purpose:

- Vercel serverless endpoint for future app downloads.
- Counts download attempts.
- Adds approximate unique-user tracking with an anonymous cookie.
- Redirects users to the real DMG/ZIP file.

Required Vercel environment variables once the app file exists:

```text
CHEEPURU_DOWNLOAD_URL=https://actual-file-host.example/Cheepuru-Katta.dmg
CHEEPURU_ANALYTICS_SALT=some-long-random-secret
CHEEPURU_DOWNLOAD_WEBHOOK_URL=
```

Behavior:

- If `CHEEPURU_DOWNLOAD_URL` is missing, redirects to `/?download=missing`.
- If configured, logs a structured event to Vercel function logs.
- Sets an anonymous cookie named `ck_visitor`.
- Hashes the visitor id before logging.
- Optionally sends event JSON to `CHEEPURU_DOWNLOAD_WEBHOOK_URL`.
- Redirects to the real download URL.

Important limitation:

- Static HTML alone cannot reliably count different users.
- This endpoint gives us total download attempts and approximate unique users.
- For a real dashboard, connect Vercel Analytics, log drains, webhook, Supabase, Airtable, PostHog, Plausible, or another analytics/database tool.

### 4.7 Deployment Docs Added

Deployment doc:

```text
VERCEL_DEPLOY.md
```

It explains:

- What happens when users click Download today.
- Correct Vercel setup.
- Future support URL configuration.
- Future download tracking configuration.
- Launch checklist.

### 4.8 App Blueprint Added

Planning doc:

```text
site/app-blueprint.md
```

It describes the intended SwiftUI app direction:

- Native macOS app.
- Local Mole adapter.
- Review-first destructive workflows.
- History/receipts.
- Optional support prompts.

### 4.9 Native SwiftUI App Starter Added

A native macOS app starter now exists in:

```text
app/CheepuruKatta/
```

Implemented:

- Swift Package app target.
- SwiftUI dashboard, sidebar, tool pages, review sheet, history, and settings.
- Mole adapter discovery for bundled `Mole/mole`, repo `mole`, or installed `mo` / `mole`.
- Dry-run review flow for Clean, Uninstall, Optimize, Purge, and Installer Cleanup.
- Read-only JSON surfaces for Status and Analyze.
- Local operation receipts in `~/Library/Application Support/Cheepuru Katta/history.json`.
- Settings via `UserDefaults`.
- Unsigned `.app` packaging script.
- Developer ID signing and notarization scripts, ready once Apple credentials exist.
- Swift tests for workflow command construction, output cleanup, history persistence, Mole discovery, and process execution.

Useful commands:

```bash
make app-test
make app-package
make app-package-zip
make app-notarize
```

`make app-package` creates:

```text
app/CheepuruKatta/.build/Cheepuru Katta.app
app/CheepuruKatta/.build/Cheepuru Katta.zip
```

The app intentionally defaults to skipping privileged authorization prompts by passing `MOLE_TEST_NO_AUTH=1`, so the native UI does not hang on sudo prompts. A production privileged-helper design is still needed for full privileged cleanup.

## 5. What Is Not Done Yet

The following are NOT done:

- The public website serves an unsigned preview ZIP, but no signed/notarized DMG/ZIP exists yet.
- No Apple Developer ID signing exists yet.
- No notarization exists yet.
- No update system exists yet.
- No real support/donation URL is configured yet.
- No production download analytics dashboard exists yet.
- A first real dashboard screenshot exists at `site/assets/app-dashboard.png`.
- An unsigned preview ZIP exists at `site/downloads/Cheepuru-Katta-preview.zip`.
- More screenshots are still needed for review, status, analyze, history, and settings.
- No privileged helper exists for full sudo-backed native execution.

## 6. Immediate Next Tasks

### Task 1: Confirm Vercel Deployment

Check whether Vercel is deploying from:

```text
origin/sillanaresh/repo-loopholes
```

or from:

```text
main
```

If Vercel deploys `main`, either:

1. Change Vercel production branch to `sillanaresh/repo-loopholes`, or
2. Merge the branch into `main`.

Correct Vercel settings:

```text
Root Directory: Mole (root)
Framework Preset: Other
Build Command: empty
Output Directory: empty
Install Command: empty
```

After redeploying, the website should no longer show 404.

### Task 2: Decide Branch Strategy

The user may want everything on `main`.

If yes:

```bash
git checkout main
git pull upstream main
git merge origin/sillanaresh/repo-loopholes
git push origin main
```

Be careful:

- Do not rename branches unless explicitly asked.
- Do not push to original upstream repo.
- Push only to the user's fork `origin`.

### Task 3: Configure Support URL

The user wants optional donation/support.

Once a provider page exists, update:

```text
site/config.js
```

Example:

```js
window.CHEEPURU_CONFIG = {
  supportUrl: "https://buymeacoffee.com/your-page",
  downloadUrl: "/downloads/Cheepuru-Katta-preview.zip"
};
```

No support provider has been finalized yet.

### Task 4: Sign, Notarize, and Package the Native App

Current local path:

```text
app/CheepuruKatta/.build/Cheepuru Katta.app
```

Next release work:

- Create a Developer ID certificate.
- Add signing settings or a signing script.
- Notarize the app bundle.
- Wrap as DMG or ZIP.
- Upload the archive.
- Set `CHEEPURU_DOWNLOAD_URL` in Vercel.
- Change `site/config.js` to `downloadUrl: "/api/download"`.

### Task 5: Build Production Privileged Helper

The app currently calls Mole locally through an adapter and avoids sudo hangs by default.

Production still needs:

- A proper privileged-helper strategy for full system cleanup.
- Clear permission onboarding.
- Tests that privileged paths cannot run without review.

### Task 6: Capture More Real App Screenshots

One privacy-safe dashboard screenshot is already wired into the website.

Still needed after visual polish:

- Run the packaged app.
- Capture Clean review, Status, Analyze, History, and Settings screenshots.
- Replace any remaining website mockups with real screenshots.

Keep website and app aesthetics consistent.

## 7. Native App Product Spec

Core app navigation:

- Clean
- Uninstall
- Optimize
- Analyze
- Status
- Purge
- Installer Cleanup
- History
- Settings/About

State the app should store locally:

- Settings.
- Operation history.
- Permission status.
- Last scan results.
- Support URL.
- Mole adapter/binary path.

Core safety concepts:

- Local-only scan.
- Clear category grouping.
- Risk labels.
- Protected paths.
- Explicit confirmation.
- Local receipts.
- Nothing sneaky in the background.

Support prompt behavior:

- Only after value moments.
- Example: after cleanup success, "Freed 2.1 GB".
- Never blocks usage.
- Never unlocks features.
- Never nags aggressively.

Suggested app surfaces:

- Dashboard summary.
- Scan results table.
- Review sheet.
- Confirmation modal.
- Execution progress.
- Receipt/history detail.
- Permissions/settings.
- About screen with Mole attribution and MIT license.

## 8. Packaging / Distribution Reality

The user does not currently have an Apple Developer ID.

Best smooth public path:

- Apple Developer ID.
- Code signing.
- Notarization.
- DMG or ZIP distribution.

Without Developer ID:

- Can ship unsigned ZIP/DMG for early testers.
- Users will hit macOS Gatekeeper warnings.
- Users may need right-click -> Open or Settings approval.
- This is okay for early private testing but poor for public launch.

Suggested staged distribution:

1. Early internal unsigned ZIP.
2. Private tester ZIP/DMG with clear opening instructions.
3. Developer ID signed and notarized DMG for public launch.
4. Later add auto-update if product gains traction.

## 9. Visual / UX Direction

Website and app should share the same visual identity:

- Premium.
- Calm.
- Trust-first.
- Broom/stick-broom brand.
- Avoid panic-cleaner aesthetics.
- Avoid fake system alerts.
- Avoid loud neon/purple SaaS sameness.
- Dense enough for a utility, but still beautiful.

Important:

- The app should look like a serious Mac utility.
- It should not look like a marketing landing page inside an app.
- Use native macOS controls where possible.
- Use clear status, risk labels, and confirmation patterns.

Good UX principle:

```text
Useful, never sneaky.
```

## 10. Files Another Agent Should Inspect First

Start here:

```text
site/index.html
site/styles.css
site/app.js
site/config.js
site/icon.svg
site/assets/app-dashboard.png
vercel.json
api/download.js
VERCEL_DEPLOY.md
site/app-blueprint.md
app/CheepuruKatta/README.md
app/CheepuruKatta/Package.swift
app/CheepuruKatta/Sources/
app/CheepuruKatta/Tests/
README.md
LICENSE
```

Mole CLI areas to inspect before app adapter work:

```text
cmd/analyze/
lib/clean/
lib/uninstall/
lib/optimize/
lib/manage/
lib/core/
tests/
```

Search for JSON support:

```bash
rg -n -- '--json|json|JSON' README.md cmd lib tests
```

Search for dry-run/preview behavior:

```bash
rg -n 'dry|preview|confirm|delete|trash|safe|protect|whitelist' README.md cmd lib tests
```

## 11. Useful Verification Commands

Check branch:

```bash
git status --short --branch
git log --oneline --decorate -8
```

Validate root Vercel config:

```bash
node -e 'JSON.parse(require("fs").readFileSync("vercel.json","utf8")); console.log("json ok")'
```

Validate download API syntax:

```bash
node -c api/download.js
```

Build and test the native app:

```bash
make app-test
make app-package
make app-package-zip
```

Run site locally:

```bash
python3 -m http.server 4173 -d site
```

Open:

```text
http://127.0.0.1:4173/
```

Test download endpoint manually:

```bash
CHEEPURU_DOWNLOAD_URL='https://example.com/Cheepuru-Katta.dmg' node - <<'NODE'
const handler = require('./api/download');
const headers = {};
const res = {
  statusCode: 0,
  setHeader(key, value) { headers[key] = value; },
  end() {
    console.log(JSON.stringify({
      statusCode: this.statusCode,
      location: headers.Location,
      hasCookie: Boolean(headers['Set-Cookie'])
    }));
  }
};
handler({
  headers: {
    cookie: '',
    'user-agent': 'test-agent',
    referer: 'https://example.org'
  }
}, res);
NODE
```

Expected:

```json
{"statusCode":302,"location":"https://example.com/Cheepuru-Katta.dmg","hasCookie":true}
```

## 12. Known Commits From This Work

Recent commits on `sillanaresh/repo-loopholes`:

```text
e252684 feat: add Cheepuru Katta website
a6a9b7f fix: make broom icon match Cheepuru Katta
6749074 fix: configure Vercel root deployment
```

This helper file may be committed after those.

## 13. Things To Avoid

Do not:

- Push to `upstream/tw93/Mole`.
- Rename the branch without permission.
- Claim the Mac app exists.
- Put a fake download file behind the Download button.
- Add forced payment/licensing.
- Add scareware messaging.
- Clone the original Mole commercial website.
- Remove MIT attribution.
- Let the app perform destructive actions without preview and confirmation.
- Parse human CLI output if stable JSON exists.

## 14. Current One-Line Status

Cheepuru Katta currently has a Vercel-ready static marketing website, a native SwiftUI app starter with Mole adapter, review-first destructive workflows, local receipts, tests, an unsigned preview ZIP behind the Download button, and a real dashboard screenshot, but the support URL, signed/notarized build, Developer ID signing, notarization, privileged helper, more screenshots, and production analytics dashboard are still pending.
