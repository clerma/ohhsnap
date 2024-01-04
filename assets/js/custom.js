var isAuthenticated = document.cookie.indexOf("authenticated=true") >= 0;

if (isAuthenticated) {
  document.body.className += " authenticated";
}

  /* curator-feed-default-feed-layout */
(function() {
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

