# Cheepuru Katta Website Prototype

Static website for the free Cheepuru Katta Mac utility.

## Local Preview

```bash
python3 -m http.server 4173 -d site
```

Open `http://127.0.0.1:4173/`.

To tune the live website screenshot boxes, open:

```text
http://127.0.0.1:4173/?boxes=1
```

The short form `http://127.0.0.1:4173/?box=1` works too.

The boxes appear directly around the real homepage images. Drag the label to move a box, resize from any side or corner, then copy the printed values.

## Configure Links

Edit `config.js`:

```js
window.CHEEPURU_CONFIG = {
  supportUrl: "https://buymeacoffee.com/your-page",
  downloadUrl: "/downloads/Cheepuru-Katta-preview.zip"
};
```

Leave `supportUrl` empty while the support provider is undecided. The current `downloadUrl` points to the unsigned preview ZIP served by Vercel from `site/downloads/`.

## Vercel

Import the repository into Vercel and keep the project root directory as the repository root.

No build command is required. The root `vercel.json` tells Vercel to serve the plain static website from `site/`.

For download tracking, set `downloadUrl` to `/api/download` and configure `CHEEPURU_DOWNLOAD_URL` in Vercel after an external signed archive is hosted.
