const crypto = require("crypto");

const COOKIE_NAME = "ck_visitor";
const ONE_YEAR = 60 * 60 * 24 * 365;

function parseCookies(header = "") {
  return Object.fromEntries(
    header
      .split(";")
      .map((part) => part.trim().split("="))
      .filter(([key, value]) => key && value)
      .map(([key, value]) => [key, decodeURIComponent(value)])
  );
}

function hash(value, salt) {
  return crypto
    .createHash("sha256")
    .update(`${salt}:${value}`)
    .digest("hex");
}

async function sendWebhook(event) {
  const webhookUrl = process.env.CHEEPURU_DOWNLOAD_WEBHOOK_URL;
  if (!webhookUrl || typeof fetch !== "function") {
    return;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 1500);

  try {
    await fetch(webhookUrl, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(event),
      signal: controller.signal
    });
  } catch (error) {
    console.warn(
      JSON.stringify({
        type: "cheepuru_download_webhook_failed",
        message: error.message
      })
    );
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = async function handler(req, res) {
  const downloadUrl = process.env.CHEEPURU_DOWNLOAD_URL || process.env.DOWNLOAD_URL;

  if (!downloadUrl) {
    console.warn(JSON.stringify({ type: "cheepuru_download_missing_url" }));
    res.statusCode = 302;
    res.setHeader("Location", "/?download=missing");
    res.end();
    return;
  }

  const cookies = parseCookies(req.headers.cookie);
  const existingVisitor = cookies[COOKIE_NAME];
  const visitorId = existingVisitor || crypto.randomUUID();
  const salt = process.env.CHEEPURU_ANALYTICS_SALT || "cheepuru-katta-v1";
  const event = {
    type: "cheepuru_download",
    product: "cheepuru-katta",
    visitorHash: hash(visitorId, salt).slice(0, 32),
    firstSeenVisitor: !existingVisitor,
    country: req.headers["x-vercel-ip-country"] || null,
    referrer: req.headers.referer || null,
    userAgentHash: hash(req.headers["user-agent"] || "unknown", salt).slice(0, 16),
    at: new Date().toISOString()
  };

  console.info(JSON.stringify(event));
  await sendWebhook(event);

  res.statusCode = 302;
  res.setHeader(
    "Set-Cookie",
    `${COOKIE_NAME}=${encodeURIComponent(visitorId)}; Path=/; Max-Age=${ONE_YEAR}; HttpOnly; Secure; SameSite=Lax`
  );
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("Location", downloadUrl);
  res.end();
};
