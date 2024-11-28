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
document
  .getElementById("soundBtn")
  .addEventListener("click", playPronunciation);

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
