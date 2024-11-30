import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

liveSocket.connect();

window.liveSocket = liveSocket;

// Set dark theme by default if default for the OS is dark mode...
setDefaultTheme();

document.getElementById("toggleTheme").addEventListener("click", toggleTheme);
document
  .getElementById("mobile-open-menu-btn")
  .addEventListener("click", openMobileMenu);
document
  .getElementById("closeMenuBtn")
  .addEventListener("click", closeMobileMenu);
document
  .getElementById("mobileMenuBackdrop")
  .addEventListener("click", closeMobileMenu);
// document
//   .getElementById("soundBtn")
//   .addEventListener("click", playPronunciation);
//

code_snippets = document.querySelectorAll("pre > code");

code_snippets.forEach((node) => {
  // append wrapper element
  const wrapper = document.createElement("div");
  while (node.firstChild) {
    wrapper.appendChild(node.firstChild);
  }
  wrapper.style.position = "relative";
  node.appendChild(wrapper);

  wrapper_width = wrapper.getBoundingClientRect().width;

  // Style node
  node.style.width = "100%";
  // Create the "Copy to Clipboard" element
  const copyElement = document.createElement("button");
  copyElement.innerText = "Copy";
  copyElement.style.position = "absolute";
  copyElement.style.top = "0";
  copyElement.style.right = `-${wrapper_width}px`;
  copyElement.style.backgroundColor = "#007BFF";
  copyElement.style.color = "#fff";
  copyElement.style.border = "none";
  copyElement.style.borderRadius = "4px";
  copyElement.style.padding = "5px 10px";
  copyElement.style.cursor = "pointer";
  copyElement.style.zIndex = "999999"; // Ensure it stays on top

  // Add a click event to copy content to the clipboard
  copyElement.addEventListener("click", () => {
    // Assuming the text to copy is the node's textContent
    navigator.clipboard
      .writeText(node.textContent.replace("Copy", "") || "")
      .catch((err) => {
        console.error("Failed to copy text: ", err);
      });
  });

  // Position the parent node as `relative` if not already set
  const computedStyle = getComputedStyle(node);
  if (computedStyle.position === "static") {
    node.style.position = "relative";
  }

  // Append the "Copy to Clipboard" element to the node
  // node.appendChild(copyElement);
  node.insertBefore(copyElement, wrapper);
});

function setDefaultTheme() {
  theme = "light";

  if (localStorage.getItem("theme")) {
    theme = localStorage.getItem("theme");
  } else {
    theme =
      window.matchMedia &&
      window.matchMedia("(prefers-color-scheme: dark)").matches
        ? "dark"
        : "light";
  }

  setTheme(theme);
}

function isCurrentDarkMode() {
  return document.getElementsByTagName("html")[0].classList.contains("dark");
}

function toggleTheme() {
  setTheme(isCurrentDarkMode() ? "light" : "dark");
}

function setTheme(theme) {
  root = document.getElementsByTagName("html")[0];
  localStorage.setItem("theme", theme);

  if (theme == "dark") {
    root.classList.add("dark");
  } else {
    root.classList.remove("dark");
  }
}

function openMobileMenu() {
  document
    .getElementById("mobile-menu")
    .parentElement.classList.remove("hidden");
}

function closeMobileMenu() {
  document.getElementById("mobile-menu").parentElement.classList.add("hidden");
}

function playPronunciation() {
  document.getElementById("pronunciation").play();
}
