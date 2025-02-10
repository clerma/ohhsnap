var isAuthenticated = document.cookie.indexOf("authenticated=true") >= 0;

var jslang='EN';

if (isAuthenticated) {
  document.body.className += " authenticated";
}

//Flowdesk Form

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

document.addEventListener('snipcart.ready', function() {
  const cartNavItem = document.getElementById('cart-nav-item');
  const updateCartVisibility = () => {
    let count = Snipcart.store.getState().cart.items.count;

    // Toggle the d-none class based on the cart count
    if (count > 0) {
      cartNavItem.classList.remove('d-none');
    } else {
      cartNavItem.classList.add('d-none');
    }

    // Update the cart count display
    const cartCountDiv = cartNavItem.querySelector('.snipcart-items-count');
    cartCountDiv.innerHTML = count > 0 ? count : '';
  };

  // Call the function once to set the initial state
  updateCartVisibility();

  // Subscribe to cart count changes
  Snipcart.store.subscribe(() => {
    updateCartVisibility();
  });
});


 document.addEventListener("DOMContentLoaded", function () {
   if (window.location.pathname === "/") {
     (function () {
       var i,
         e,
         d = document,
         s = "script";
       i = d.createElement("script");
       i.async = 1;
       i.src = "https://cdn.curator.io/published/65cf3aa1-9855-4aa7-82af-12c174dffdad.js";
       e = d.getElementsByTagName(s)[0];
       e.parentNode.insertBefore(i, e);
     })();
   }
 });
// Passive event listeners
 jQuery.event.special.touchstart = {
     setup: function( _, ns, handle ) {
         this.addEventListener("touchstart", handle, { passive: !ns.includes("noPreventDefault") });
     }
 };
 jQuery.event.special.touchmove = {
     setup: function( _, ns, handle ) {
         this.addEventListener("touchmove", handle, { passive: !ns.includes("noPreventDefault") });
     }
 };
