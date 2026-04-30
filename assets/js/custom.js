// assets/js/custom.js
(function () {
  // Add body class if authenticated (keep your existing logic)
  function setAuthenticatedClass() {
    if (document.cookie.indexOf("authenticated=true") >= 0) {
      document.body.classList.add("authenticated");
    }
  }

  // Conditional effects init (ONLY runs if markup exists)
  function initEffectsIfUsed() {
    // If you're using the patched GK helpers
    if (window.GK?.initJarallaxIfPresent) window.GK.initJarallaxIfPresent();
    if (window.GK?.initAOSIfPresent) window.GK.initAOSIfPresent();

    // If you're still on the original globals (non-patched)
    if (!window.GK) {
      const hasJarallax = document.querySelector("[data-jarallax], [data-jarallax-element], [data-jarallax-video]");
      if (hasJarallax && window.jarallax) {
        try { window.jarallaxVideo && window.jarallaxVideo(); } catch (e) {}
        try { window.jarallaxElement && window.jarallaxElement(); } catch (e) {}
        const els = document.querySelectorAll("[data-jarallax], [data-jarallax-element]");
        if (els.length) window.jarallax(els);
      }

      const hasAOS = document.querySelector("[data-aos]");
      if (hasAOS && window.AOS) {
        window.AOS.init({ once: true });
      }
    }
  }

  // DOM ready is better than window.load for these
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      setAuthenticatedClass();
      initEffectsIfUsed();
    });
  } else {
    setAuthenticatedClass();
    initEffectsIfUsed();
  }
  (function () {
    function loadLightwidget() {
      if (document.querySelector('script[data-lightwidget]')) return;

      var s = document.createElement('script');
      s.src = 'https://cdn.lightwidget.com/widgets/lightwidget.js';
      s.async = true;
      s.defer = true;
      s.setAttribute('data-lightwidget', '1');
      document.head.appendChild(s);
    }

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', loadLightwidget);
    } else {
      loadLightwidget();
    }
  })();
  function appendScriptSafely(src, attrs) {
    function doAppend() {
      try {
        var s = document.createElement('script');
        s.async = true;
        s.src = src;

        if (attrs) {
          Object.keys(attrs).forEach(function (k) {
            s.setAttribute(k, attrs[k]);
          });
        }

        var target =
          document.head ||
          document.getElementsByTagName('head')[0] ||
          document.body ||
          document.documentElement;

        if (!target || !target.appendChild) return; // nothing to attach to yet
        target.appendChild(s);
      } catch (e) {}
    }

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', doAppend, { once: true });
    } else {
      doAppend();
    }
  }

})();
(function () {
  function initJarallaxVideo(el) {
    if (!el || el.dataset.jarallaxInited === "true") return;

    // Require jarallax to be present
    if (typeof window.jarallax !== "function") return;

    // Activate jarallax on this element
    el.setAttribute("data-jarallax", "");
    if (el.dataset.videoSrcLazy) el.setAttribute("data-video-src", el.dataset.videoSrcLazy);

    // Call jarallaxVideo/jarallaxElement if available (safe)
    try { window.jarallaxVideo && window.jarallaxVideo(); } catch (e) {}
    try { window.jarallaxElement && window.jarallaxElement(); } catch (e) {}

    // Init jarallax instance on this element
    var speed = parseFloat(el.getAttribute("data-speed") || "0.5");
    window.jarallax(el, { speed: speed });

    el.dataset.jarallaxInited = "true";
  }

  function isInInitialViewport(el) {
    var r = el.getBoundingClientRect();
    return r.top < window.innerHeight && r.bottom > 0;
  }

  function setupLazyJarallaxVideos() {
    var els = document.querySelectorAll("[data-jarallax-lazy][data-video-src-lazy]");
    if (!els.length) return;

    els.forEach(function (el) {
      // HERO (above the fold): wait for first interaction OR 3s after load (whichever happens first)
      if (isInInitialViewport(el)) {
        var started = false;

        function start() {
          if (started) return;
          started = true;
          initJarallaxVideo(el);
        }

        // 3s after window load (fallback)
        window.addEventListener("load", function () {
          setTimeout(start, 3000);
        }, { once: true });

        // first interaction starts it sooner
        ["pointerdown", "touchstart", "keydown", "scroll", "mousemove"].forEach(function (evt) {
          window.addEventListener(evt, start, { once: true, passive: true });
        });

        return;
      }

      // BELOW THE FOLD: init when near viewport
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          initJarallaxVideo(entry.target);
          io.unobserve(entry.target);
        });
      }, { rootMargin: "300px 0px" });

      io.observe(el);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", setupLazyJarallaxVideos);
  } else {
    setupLazyJarallaxVideos();
  }
})();
