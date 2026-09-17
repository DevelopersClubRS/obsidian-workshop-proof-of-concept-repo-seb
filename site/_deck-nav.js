// Shared deck navigation: slide counter, progress, keyboard and full screen.
// Injected by build.py via <!--INCLUDE:_deck-nav.js-->
(function () {
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }

  var slides = Array.prototype.slice.call(document.querySelectorAll(".slide"));
  var where = document.getElementById("where"), progress = document.getElementById("progress");
  var current = 0;
  function setCurrent(i) {
    current = i;
    var name = slides[i].getAttribute("aria-label");
    where.textContent = "";
    where.appendChild(el("b", "", String(i + 1).padStart(2, "0") + " / " + slides.length));
    where.appendChild(document.createTextNode(" " + (i === 0 ? "Hermes, Managed" : name)));
    progress.style.width = ((i + 1) / slides.length * 100) + "%";
  }
  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) { if (en.isIntersecting) setCurrent(slides.indexOf(en.target)); });
    }, { rootMargin: "-45% 0px -45% 0px" });
    slides.forEach(function (s) { io.observe(s); });
  }
  setCurrent(0);
  function go(delta) {
    var i = Math.max(0, Math.min(slides.length - 1, current + delta));
    slides[i].scrollIntoView({ block: "start" });
    setCurrent(i);
  }
  document.getElementById("prev").addEventListener("click", function () { go(-1); });
  document.getElementById("next").addEventListener("click", function () { go(1); });
  document.getElementById("fs").addEventListener("click", toggleFs);
  function toggleFs() {
    try {
      if (!document.fullscreenElement) document.documentElement.requestFullscreen();
      else document.exitFullscreen();
    } catch (e) { /* fullscreen not allowed here */ }
  }
  document.addEventListener("keydown", function (e) {
    var t = e.target, tag = t && t.tagName;
    if (tag === "INPUT" || tag === "SELECT" || tag === "TEXTAREA" || (t && t.isContentEditable)) return;
    if (e.key === " " && (tag === "BUTTON" || tag === "A" || tag === "SUMMARY")) return;
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    if (["ArrowDown", "PageDown", "ArrowRight"].indexOf(e.key) >= 0 || (e.key === " " && !e.shiftKey)) { e.preventDefault(); go(1); }
    else if (["ArrowUp", "PageUp", "ArrowLeft"].indexOf(e.key) >= 0 || (e.key === " " && e.shiftKey)) { e.preventDefault(); go(-1); }
    else if (e.key === "Home") { e.preventDefault(); go(-slides.length); }
    else if (e.key === "End") { e.preventDefault(); go(slides.length); }
    else if (e.key === "f" || e.key === "F") { toggleFs(); }
  });
})();
