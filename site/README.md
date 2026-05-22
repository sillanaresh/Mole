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

Import the repository into Vercel and set the project root directory to `site`.

No build command is required. The output is plain static HTML, CSS, and JavaScript.
