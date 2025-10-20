window.addEventListener('load', function () {
  // Authenticated class logic
  if (document.cookie.indexOf("authenticated=true") >= 0) {
    document.body.className += " authenticated";
  }

  // Flowdesk Form
  (function(w, d, t, h, s, n) {
    w.FlodeskObject = n;
    var fn = function() {
      (w[n].q = w[n].q || []).push(arguments);
    };
    w[n] = w[n] || fn;
    var f = d.getElementsByTagName(t)[0];
    var v = '?v=' + Math.floor(new Date().getTime() / (120 * 1000)) * 60;
    var sm = d.createElement(t);
    sm.async = true;
    sm.type = 'module';
    sm.src = h + s + '.mjs' + v;
    f.parentNode.insertBefore(sm, f);
    var sn = d.createElement(t);
    sn.async = true;
    sn.noModule = true;
    sn.src = h + s + '.js' + v;
    f.parentNode.insertBefore(sn, f);
  })(window, document, 'script', 'https://assets.flodesk.com', '/universal', 'fd');

  window.fd('form', {
    formId: '659635026b1d724082621933'
  });

  // // Snipcart cart display logic
  // document.addEventListener('snipcart.ready', function() {
  //   const cartNavItem = document.getElementById('cart-nav-item');
  //   const updateCartVisibility = () => {
  //     let count = Snipcart.store.getState().cart.items.count;
  //     cartNavItem.classList.toggle('d-none', count === 0);
  //     const cartCountDiv = cartNavItem.querySelector('.snipcart-items-count');
  //     cartCountDiv.innerHTML = count > 0 ? count : '';
  //   };
//
  //   updateCartVisibility();
  //   Snipcart.store.subscribe(updateCartVisibility);
  // });

  // Passive event listeners optimization
  (function() {
    const originalAddEventListener = EventTarget.prototype.addEventListener;
    EventTarget.prototype.addEventListener = function(type, listener, options) {
      const needsPassive = ['touchstart', 'touchmove'].includes(type);
      const useCapture = typeof options === 'boolean' ? options : options?.capture;
      const passiveOptions = needsPassive ? { passive: true, capture: useCapture } : options;
      originalAddEventListener.call(this, type, listener, passiveOptions);
    };
  })();

  // Curator Feed embed
  if (document.getElementById("curator-feed-social-media-feed-layout")) {
    var i = document.createElement("script");
    i.async = 1;
    i.charset = "UTF-8";
    i.src = "https://cdn.curator.io/published/9a94c960-289a-4d77-9d37-86b1ecbe023c.js";
    document.getElementsByTagName("script")[0].parentNode.insertBefore(i, null);
  }
});
