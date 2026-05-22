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
- Product/app mockup.
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

- The current product mockups are visual website mockups.
- They are not real SwiftUI app screenshots.
- Once the native app exists, replace the mockups with actual app screenshots.

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
  downloadUrl: ""
};
```

Because no Mac app exists yet:

- The download button does not point to a fake file.
- The button text changes to `Mac app coming soon`.
- This prevents misleading users.

When a real app exists, update config to:

```js
window.CHEEPURU_CONFIG = {
  supportUrl: "https://your-support-page.example",
  downloadUrl: "/api/download"
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

## 5. What Is Not Done Yet

The following are NOT done:

- No actual Mac app has been built yet.
- No SwiftUI project exists yet.
- No real DMG/ZIP app download exists yet.
- No Apple Developer ID signing exists yet.
- No notarization exists yet.
- No update system exists yet.
- No real support/donation URL is configured yet.
- No production download analytics dashboard exists yet.
- No real app screenshots exist yet.
- Website mockups are not real app UI screenshots.
- Branch has not necessarily been merged into `main`.

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
  downloadUrl: ""
};
```

No support provider has been finalized yet.

### Task 4: Start Native Mac App

Recommended direction:

- SwiftUI macOS app.
- Native feel.
- Beautiful but quiet utility UI.
- Same brand/aesthetic as website.
- Use actual app screenshots later on website.

Do not start with Electron unless the user explicitly changes direction.

### Task 5: Build Mole Adapter Layer

The app should call Mole locally through an adapter.

Adapter responsibilities:

- Locate bundled Mole binary or repo CLI.
- Run scan/preview commands.
- Parse stable JSON output where available.
- Avoid fragile parsing of terminal-formatted human output.
- Route destructive actions through Mole safety helpers.
- Return structured results to SwiftUI.

### Task 6: Enforce Destructive-Action Safety

Every destructive workflow must follow:

1. Preview/dry-run.
2. Grouped review.
3. Explicit confirmation.
4. Execution.
5. Local receipt/history.

The app must not allow direct deletion without preview/confirmation.

### Task 7: Replace Website Mockups With Real Screenshots

After the SwiftUI app exists:

- Capture real app screenshots.
- Replace website mockups with actual product screenshots.
- Keep website and app aesthetics consistent.

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
vercel.json
api/download.js
VERCEL_DEPLOY.md
site/app-blueprint.md
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

Cheepuru Katta currently has a Vercel-ready static marketing website, a fixed root Vercel deployment config, and a future download-tracking endpoint, but the native macOS app, real download package, support URL, app screenshots, signing, notarization, and production analytics dashboard are still pending.

