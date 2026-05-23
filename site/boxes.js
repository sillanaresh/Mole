const canvas = document.querySelector("[data-canvas]");
const image = document.querySelector("[data-source-image]");
const output = document.querySelector("[data-output]");
const copyButton = document.querySelector("[data-copy]");

const boxes = {
  hero: { x: 0, y: 0, w: 2400, h: 1150 },
  sidebar: { x: 0, y: 0, w: 413, h: 1150 }
};

let active = null;

function scale() {
  return image.clientWidth / image.naturalWidth;
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function render() {
  const s = scale() || 1;
  document.querySelectorAll("[data-box]").forEach((element) => {
    const box = boxes[element.dataset.box];
    element.style.left = `${box.x * s}px`;
    element.style.top = `${box.y * s}px`;
    element.style.width = `${box.w * s}px`;
    element.style.height = `${box.h * s}px`;
  });

  output.textContent = Object.entries(boxes)
    .map(([name, box]) => `${name}: x=${Math.round(box.x)}, y=${Math.round(box.y)}, w=${Math.round(box.w)}, h=${Math.round(box.h)}`)
    .join("\n");
}

function pointerToImage(event) {
  const rect = image.getBoundingClientRect();
  const s = scale() || 1;
  return {
    x: (event.clientX - rect.left) / s,
    y: (event.clientY - rect.top) / s
  };
}

document.querySelectorAll("[data-box]").forEach((element) => {
  element.addEventListener("pointerdown", (event) => {
    event.preventDefault();
    element.setPointerCapture(event.pointerId);

    const name = element.dataset.box;
    const point = pointerToImage(event);
    const box = boxes[name];
    active = {
      name,
      mode: event.target.matches("[data-resize]") ? "resize" : "move",
      startPoint: point,
      startBox: { ...box }
    };
  });
});

window.addEventListener("pointermove", (event) => {
  if (!active) {
    return;
  }

  const point = pointerToImage(event);
  const dx = point.x - active.startPoint.x;
  const dy = point.y - active.startPoint.y;
  const box = boxes[active.name];

  if (active.mode === "move") {
    box.x = clamp(active.startBox.x + dx, 0, image.naturalWidth - active.startBox.w);
    box.y = clamp(active.startBox.y + dy, 0, image.naturalHeight - active.startBox.h);
  } else {
    box.w = clamp(active.startBox.w + dx, 40, image.naturalWidth - active.startBox.x);
    box.h = clamp(active.startBox.h + dy, 40, image.naturalHeight - active.startBox.y);
  }

  render();
});

window.addEventListener("pointerup", () => {
  active = null;
});

copyButton.addEventListener("click", async () => {
  await navigator.clipboard.writeText(output.textContent);
  copyButton.textContent = "Copied";
  setTimeout(() => {
    copyButton.textContent = "Copy coordinates";
  }, 900);
});

image.addEventListener("load", render);
window.addEventListener("resize", render, { passive: true });
render();
