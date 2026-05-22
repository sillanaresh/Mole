# Cheepuru Katta Website Prototype

Static marketing site for the donation-first Mac utility concept.

## Local Preview

```bash
python3 -m http.server 4173 -d site
```

Open `http://127.0.0.1:4173/`.

## Configure Links

Edit `config.js`:

```js
window.CHEEPURU_CONFIG = {
  supportUrl: "https://buymeacoffee.com/your-page",
  downloadUrl: "https://example.com/Cheepuru-Katta.dmg"
};
```

Leave either value empty while the support provider or app download is undecided. The page will stay usable and avoid broken external payment/download links.

## Vercel

Import the repository into Vercel and keep the project root directory as the repository root.

No build command is required. The root `vercel.json` tells Vercel to serve the plain static website from `site/`.

When a downloadable Mac app exists, set `downloadUrl` to `/api/download` and configure `CHEEPURU_DOWNLOAD_URL` in Vercel.
