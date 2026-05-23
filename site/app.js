const DOWNLOAD_URL = window.CHEEPURU_CONFIG?.downloadUrl || "";

const nav = document.querySelector("[data-nav]");
const downloadLinks = document.querySelectorAll("[data-download-link]");
const downloadNote = document.querySelector("[data-download-note]");
const root = document.documentElement;

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
      downloadLink.setAttribute("download", "Cheepuru-Katta-preview.zip");
      downloadNote.textContent = "The download is live. This unsigned preview may require right-click Open the first time you launch it.";
    }
  });
}

function handleNavShadow() {
  nav?.classList.toggle("is-scrolled", window.scrollY > 8);
}

function revealOnScroll() {
  const targets = document.querySelectorAll(".section, .tool-grid article, .principles article");
  targets.forEach((target) => target.setAttribute("data-reveal", ""));

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });

  targets.forEach((target) => observer.observe(target));
}

function setupFrameMode() {
  const params = new URLSearchParams(window.location.search);
  if (!params.has("frame")) {
    return;
  }

  root.dataset.frameMode = "true";

  const panel = document.createElement("aside");
  panel.className = "frame-panel";
  panel.innerHTML = `
    <strong>Image Frames</strong>
    <label>Hero width <input type="range" min="640" max="1400" step="10" value="1080" data-var="--hero-shot-width" data-unit="px"></label>
    <label>Hero top gap <input type="range" min="0" max="90" step="1" value="34" data-var="--hero-shot-top" data-unit="px"></label>
    <label>Product width <input type="range" min="640" max="1400" step="10" value="1040" data-var="--product-shot-width" data-unit="px"></label>
    <label>Product top gap <input type="range" min="0" max="90" step="1" value="30" data-var="--product-shot-top" data-unit="px"></label>
    <pre data-frame-output></pre>
  `;
  document.body.append(panel);

  const output = panel.querySelector("[data-frame-output]");
  const inputs = panel.querySelectorAll("input[data-var]");

  function frameLine(selector, label) {
    const target = document.querySelector(selector);
    if (!target) {
      return `${label}: missing`;
    }
    const rect = target.getBoundingClientRect();
    return `${label}: x=${Math.round(rect.left)}, y=${Math.round(rect.top + window.scrollY)}, w=${Math.round(rect.width)}, h=${Math.round(rect.height)}`;
  }

  function updateFrameReadout() {
    output.textContent = [
      `heroWidth=${getComputedStyle(root).getPropertyValue("--hero-shot-width").trim()}`,
      `heroTop=${getComputedStyle(root).getPropertyValue("--hero-shot-top").trim()}`,
      `productWidth=${getComputedStyle(root).getPropertyValue("--product-shot-width").trim()}`,
      `productTop=${getComputedStyle(root).getPropertyValue("--product-shot-top").trim()}`,
      frameLine('[data-frame-target="hero"]', "hero box"),
      frameLine('[data-frame-target="product"]', "product box")
    ].join("\n");
  }

  inputs.forEach((input) => {
    input.addEventListener("input", () => {
      root.style.setProperty(input.dataset.var, `${input.value}${input.dataset.unit}`);
      updateFrameReadout();
    });
  });

  window.addEventListener("resize", updateFrameReadout, { passive: true });
  window.addEventListener("scroll", updateFrameReadout, { passive: true });
  updateFrameReadout();
}

syncLinks();
handleNavShadow();
revealOnScroll();
setupFrameMode();
window.addEventListener("scroll", handleNavShadow, { passive: true });
