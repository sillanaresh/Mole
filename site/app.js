const SITE_CONFIG = window.EAGLE_CONFIG || {};
const DOWNLOAD_URL = SITE_CONFIG.downloadUrl || "";
const SUPPORT_URL = SITE_CONFIG.supportUrl || "";

const nav = document.querySelector("[data-nav]");
const downloadLinks = document.querySelectorAll("[data-download-link]");
const downloadNote = document.querySelector("[data-download-note]");
const supportLinks = document.querySelectorAll("[data-support-link]");
const root = document.documentElement;

const boxConfigs = {
  hero: {
    label: "top full app",
    selector: '[data-box-target="hero"]',
    widthVar: "--hero-shot-width",
    heightVar: "--hero-shot-height",
    topVar: "--hero-shot-top",
    shiftVar: "--hero-shot-shift",
    minWidth: 260,
    minHeight: 150
  },
  sidebar: {
    label: "second sidebar",
    selector: '[data-box-target="sidebar"]',
    widthVar: "--product-shot-width",
    heightVar: "--product-shot-height",
    topVar: "--product-shot-top",
    shiftVar: "--product-shot-shift",
    minWidth: 180,
    minHeight: 260
  }
};

function syncLinks() {
  downloadLinks.forEach((downloadLink) => {
    downloadLink.href = DOWNLOAD_URL || "#download";
    if (!DOWNLOAD_URL) {
      downloadLink.textContent = "Download for Mac";
      downloadLink.addEventListener("click", (event) => {
        event.preventDefault();
        downloadNote?.animate(
          [
            { opacity: 1, transform: "translateY(0)" },
            { opacity: 1, transform: "translateY(-2px)" },
            { opacity: 1, transform: "translateY(0)" }
          ],
          { duration: 320 }
        );
      });
    } else if (downloadNote) {
      downloadLink.setAttribute("download", "Eagle-preview.dmg");
      downloadNote.textContent = "Open the DMG, drag Eagle to Applications, then right-click Open the first time. This preview is unsigned because I do not have a paid Apple Developer ID yet.";
    }
  });
}

function syncSupportLinks() {
  supportLinks.forEach((supportLink) => {
    if (!SUPPORT_URL) {
      supportLink.hidden = true;
      return;
    }

    supportLink.href = SUPPORT_URL;
    supportLink.hidden = false;
  });
}

function handleNavShadow() {
  nav?.classList.toggle("is-scrolled", window.scrollY > 8);
}

function getCssPx(name) {
  return Number.parseFloat(getComputedStyle(root).getPropertyValue(name)) || 0;
}

function setCssPx(name, value) {
  root.style.setProperty(name, `${Math.round(value)}px`);
}

function createHandle(direction) {
  const handle = document.createElement("span");
  handle.className = "box-handle";
  handle.dataset.dir = direction;
  handle.setAttribute("aria-hidden", "true");
  return handle;
}

function setupBoxMode() {
  const params = new URLSearchParams(window.location.search);
  const boxModeRequested = params.get("box") === "1" || params.get("boxes") === "1";
  if (!boxModeRequested) return;

  document.body.dataset.boxMode = "true";

  const readout = document.createElement("aside");
  readout.className = "box-readout";

  const title = document.createElement("strong");
  title.textContent = "Image boxes on this page";

  const output = document.createElement("pre");
  const copyButton = document.createElement("button");
  copyButton.type = "button";
  copyButton.textContent = "Copy values";

  readout.append(title, output, copyButton);
  document.body.append(readout);

  const activeTargets = Object.entries(boxConfigs)
    .map(([name, config]) => ({ name, config, element: document.querySelector(config.selector) }))
    .filter((target) => target.element);

  function updateReadout() {
    const lines = activeTargets.map(({ name, config, element }) => {
      const rect = element.getBoundingClientRect();
      return [
        `${name}: width=${Math.round(getCssPx(config.widthVar))}px, height=${Math.round(getCssPx(config.heightVar))}px, top=${Math.round(getCssPx(config.topVar))}px, shift=${Math.round(getCssPx(config.shiftVar))}px`,
        `${name} screen box: x=${Math.round(rect.left)}px, y=${Math.round(rect.top + window.scrollY)}px, w=${Math.round(rect.width)}px, h=${Math.round(rect.height)}px`
      ].join("\n");
    });

    output.textContent = [
      `viewport: ${window.innerWidth}x${window.innerHeight}`,
      ...lines
    ].join("\n");
  }

  function startDrag(event, config, mode, direction = "") {
    event.preventDefault();
    const pointerId = event.pointerId;
    const start = {
      x: event.clientX,
      y: event.clientY,
      width: getCssPx(config.widthVar),
      height: getCssPx(config.heightVar),
      top: getCssPx(config.topVar),
      shift: getCssPx(config.shiftVar)
    };

    event.currentTarget.setPointerCapture?.(pointerId);

    function onMove(moveEvent) {
      const dx = moveEvent.clientX - start.x;
      const dy = moveEvent.clientY - start.y;

      if (mode === "move") {
        setCssPx(config.topVar, Math.max(0, start.top + dy));
        setCssPx(config.shiftVar, start.shift + dx);
        updateReadout();
        return;
      }

      let nextWidth = start.width;
      let nextHeight = start.height;
      let nextTop = start.top;
      let nextShift = start.shift;

      if (direction.includes("e")) {
        nextWidth = start.width + dx;
        nextShift = start.shift + dx / 2;
      }

      if (direction.includes("w")) {
        nextWidth = start.width - dx;
        nextShift = start.shift + dx / 2;
      }

      if (direction.includes("s")) {
        nextHeight = start.height + dy;
      }

      if (direction.includes("n")) {
        nextHeight = start.height - dy;
        nextTop = start.top + dy;
      }

      setCssPx(config.widthVar, Math.max(config.minWidth, nextWidth));
      setCssPx(config.heightVar, Math.max(config.minHeight, nextHeight));
      setCssPx(config.topVar, Math.max(0, nextTop));
      setCssPx(config.shiftVar, nextShift);
      updateReadout();
    }

    function onUp() {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      updateReadout();
    }

    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp, { once: true });
  }

  activeTargets.forEach(({ config, element }) => {
    const overlay = document.createElement("div");
    overlay.className = "box-overlay";

    const label = document.createElement("span");
    label.className = "box-label";
    label.textContent = `${config.label} · drag`;
    label.addEventListener("pointerdown", (event) => startDrag(event, config, "move"));

    overlay.append(label);
    ["n", "s", "e", "w", "ne", "nw", "se", "sw"].forEach((direction) => {
      const handle = createHandle(direction);
      handle.addEventListener("pointerdown", (event) => startDrag(event, config, "resize", direction));
      overlay.append(handle);
    });

    element.append(overlay);
  });

  copyButton.addEventListener("click", async () => {
    await navigator.clipboard?.writeText(output.textContent);
    copyButton.textContent = "Copied";
    window.setTimeout(() => {
      copyButton.textContent = "Copy values";
    }, 900);
  });

  window.addEventListener("resize", updateReadout);
  window.addEventListener("scroll", updateReadout, { passive: true });
  updateReadout();
}

syncLinks();
syncSupportLinks();
handleNavShadow();
setupBoxMode();
window.addEventListener("scroll", handleNavShadow, { passive: true });
