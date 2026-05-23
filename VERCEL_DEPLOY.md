# Deploy Cheepuru Katta Website to Vercel

The website lives in `site/` and is plain static HTML, CSS, and JavaScript. There is no build step.

## What Happens If Someone Clicks Download Today?

The website currently serves an unsigned preview ZIP from:

```text
/downloads/Cheepuru-Katta-preview.zip
```

The matching config is:

```js
window.CHEEPURU_CONFIG = {
  supportUrl: "",
  downloadUrl: "/downloads/Cheepuru-Katta-preview.zip"
};
```

Because this build is not Developer ID signed or notarized, users may need to right-click Open or approve it in macOS Settings.

## Recommended Vercel Setup

1. Push this repository or a fork to a GitHub repo you control.
2. Open Vercel and choose **Add New → Project**.
3. Import that GitHub repo.
4. Keep **Root Directory** as the repository root.
5. Set **Framework Preset** to `Other` if Vercel does not auto-detect it correctly.
6. Leave **Build Command** empty.
7. Leave **Output Directory** empty in the dashboard. The root `vercel.json` points Vercel to `site/`.
8. Deploy.

After deployment, every commit pushed to the connected branch will trigger a new Vercel deployment.

## Download Tracking

The repository includes `/api/download`, a Vercel serverless redirect endpoint for future app downloads.

Set these Vercel environment variables when you want Vercel's download endpoint to redirect to an externally hosted signed DMG/ZIP:

```text
CHEEPURU_DOWNLOAD_URL=https://your-file-host.example/Cheepuru-Katta.dmg
CHEEPURU_ANALYTICS_SALT=use-a-long-random-string-here
CHEEPURU_DOWNLOAD_WEBHOOK_URL=
```

Then set `downloadUrl: "/api/download"` in `site/config.js`.

Every download request will:

- set a privacy-preserving browser visitor cookie,
- write a structured event to Vercel function logs,
- redirect to the real DMG/ZIP,
- optionally send the event to `CHEEPURU_DOWNLOAD_WEBHOOK_URL` if you later connect a log drain, analytics tool, Make/Zapier workflow, or database endpoint.

Pure static hosting cannot reliably count distinct users by itself. The endpoint gives us the code path needed for total downloads and approximate unique visitors once Vercel logs, a webhook receiver, or an analytics provider is connected.

## Support Link

The support URL is optional. Leave `supportUrl` empty until Buy Me a Coffee, Ko-fi, GitHub Sponsors, Razorpay, or another page is ready.

## Public Launch Checklist

- Add more real Mac app screenshots beyond the first dashboard screenshot.
- Replace the preview ZIP with a signed/notarized archive when available.
- Add a real `supportUrl`, or hide the support CTA if not ready.
- Confirm MIT attribution remains visible.
- Test desktop and mobile layouts from the Vercel preview URL.

## Native App Build Path

The native app starter lives in `app/CheepuruKatta`.

```bash
make app-test
make app-package
make app-package-zip
make app-notarize
```

`make app-package` creates an unsigned local app bundle at:

```text
app/CheepuruKatta/.build/Cheepuru Katta.app
```

`make app-package-zip` creates an unsigned tester archive at:

```text
app/CheepuruKatta/.build/Cheepuru Katta.zip
```

The website Download button is already wired to the unsigned preview ZIP at `site/downloads/Cheepuru-Katta-preview.zip`. Replace that archive with a signed/notarized ZIP or switch `site/config.js` to `/api/download` when an external hosted build is ready.

Signing and notarization require these environment variables:

```text
CHEEPURU_CODESIGN_IDENTITY=Developer ID Application: Your Name (TEAMID)
APPLE_ID=you@example.com
APPLE_TEAM_ID=TEAMID
APPLE_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx
```
