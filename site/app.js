const DOWNLOAD_URL = window.CHEEPURU_CONFIG?.downloadUrl || "";

const nav = document.querySelector("[data-nav]");
const downloadLinks = document.querySelectorAll("[data-download-link]");
const downloadNote = document.querySelector("[data-download-note]");

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

syncLinks();
handleNavShadow();
revealOnScroll();
window.addEventListener("scroll", handleNavShadow, { passive: true });
