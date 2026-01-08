window.addEventListener('load', function () {
  // Authenticated class logic
  if (document.cookie.indexOf("authenticated=true") >= 0) {
    document.body.className += " authenticated";
  }

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


});
