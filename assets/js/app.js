// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Set dark theme by default if default for the OS is dark mode...
setDefaultTheme();

document.getElementById("toggleTheme").addEventListener("click", toggleTheme);
document.getElementById("mobile-open-menu-btn").addEventListener("click", openMobileMenu);
document.getElementById("closeMenuBtn").addEventListener("click", closeMobileMenu);
document.getElementById("mobileMenuBackdrop").addEventListener("click", closeMobileMenu);
document.getElementById("soundBtn").addEventListener("click", playPronunciation);

function setDefaultTheme() {
  theme = "light";

  if (localStorage.getItem("theme")) {
    theme = localStorage.getItem("theme");
  } else {
    theme = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? "dark" : "light"
  }
  
  setTheme(theme);
}

function isCurrentDarkMode() {
  return document.getElementsByTagName("html")[0].classList.contains("dark");
}

function toggleTheme() { setTheme(isCurrentDarkMode() ? "light" : "dark"); }

function setTheme(theme) {
  root = document.getElementsByTagName("html")[0];
  localStorage.setItem("theme", theme);

  if(theme == "dark") {
    root.classList.add("dark");
  } else {
    root.classList.remove("dark");
  }
}

function openMobileMenu() {
  document.getElementById("mobile-menu").parentElement.classList.remove("hidden");
}

function closeMobileMenu() {
  document.getElementById("mobile-menu").parentElement.classList.add("hidden");
}

function playPronunciation() {
  document.getElementById("pronunciation").play();
}