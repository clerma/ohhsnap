var isAuthenticated = document.cookie.indexOf("authenticated=true") >= 0;

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
