# Deploy Cheepuru Katta Website to Vercel

The website lives in `site/` and is plain static HTML, CSS, and JavaScript. There is no build step.

## What Happens If Someone Clicks Download Today?

Until `site/config.js` has a real `downloadUrl`, the hero button changes to **Mac app coming soon** and does not download anything.

When a signed/notarized app or early preview archive exists, set:

```js
window.CHEEPURU_CONFIG = {
  supportUrl: "https://your-support-page.example",
  downloadUrl: "https://your-download-url.example/Cheepuru-Katta.dmg"
};
```

Then the button will link directly to that file.

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

Set these Vercel environment variables when the Mac app archive exists:

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

- Replace temporary website mockups with real Mac app screenshots.
- Add a real `downloadUrl`.
- Add a real `supportUrl`, or hide the support CTA if not ready.
- Confirm MIT attribution remains visible.
- Test desktop and mobile layouts from the Vercel preview URL.
