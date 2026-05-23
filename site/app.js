const SUPPORT_URL = window.CHEEPURU_CONFIG?.supportUrl || "";
const DOWNLOAD_URL = window.CHEEPURU_CONFIG?.downloadUrl || "";

const nav = document.querySelector("[data-nav]");
const supportLinks = document.querySelectorAll("[data-support-link]");
const downloadLink = document.querySelector("[data-download-link]");
const downloadNote = document.querySelector("[data-download-note]");
const supportNote = document.querySelector("[data-support-note]");

function syncLinks() {
  supportLinks.forEach((link) => {
    if (SUPPORT_URL) {
      link.href = SUPPORT_URL;
      link.target = "_blank";
      link.rel = "noopener";
    } else {
      link.href = "#support";
      link.addEventListener("click", (event) => {
        event.preventDefault();
        supportNote?.animate(
          [
            { transform: "translateX(0)" },
            { transform: "translateX(4px)" },
            { transform: "translateX(-4px)" },
            { transform: "translateX(0)" }
          ],
          { duration: 280 }
        );
      });
    }
  });

  if (downloadLink) {
    downloadLink.href = DOWNLOAD_URL || "#support";
    if (!DOWNLOAD_URL) {
      downloadLink.textContent = "Download unavailable";
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
      downloadNote.textContent = "Preview build for macOS. It is unsigned, so macOS may ask you to right-click Open.";
    }
  }
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

syncLinks();
handleNavShadow();
revealOnScroll();
window.addEventListener("scroll", handleNavShadow, { passive: true });
