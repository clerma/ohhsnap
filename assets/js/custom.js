/* Check for container before loading Curator script */
(function() {
  var containerId = 'curator-feed-default-feed-layout';
  var container = document.getElementById(containerId);

  // Only proceed if the container is found
  if (container) {
	var scriptElement, firstScript, doc = document, scriptTag = "script";
	scriptElement = doc.createElement(scriptTag);
	scriptElement.async = 1;
	scriptElement.src = "https://cdn.curator.io/published/65cf3aa1-9855-4aa7-82af-12c174dffdad.js";
	firstScript = doc.getElementsByTagName(scriptTag)[0];
	firstScript.parentNode.insertBefore(scriptElement, firstScript);
  }
})();


$(document).ready(function() {
$('.zoom-gallery').magnificPopup({
delegate: 'a',
type: 'image',
closeOnContentClick: false,
closeBtnInside: false,
mainClass: 'mfp-with-zoom mfp-img-mobile',
image: {
verticalFit: true,
titleSrc: function(item) {
return item.el.attr('title');
}
},
gallery: {
enabled: true
},
zoom: {
enabled: true,
duration: 300, // don't foget to change the duration also in CSS
opener: function(element) {
return element.find('img');
}
}

});

materialKit.initFormExtendedDatetimepickers();

$("#flexiselDemo1").flexisel({
visibleItems: 4,
itemsToScroll: 1,
animationSpeed: 400,
enableResponsiveBreakpoints: true,
responsiveBreakpoints: {
	portrait: {
		changePoint:480,
		visibleItems: 3
	},
	landscape: {
		changePoint:640,
		visibleItems: 3
	},
	tablet: {
		changePoint:768,
		visibleItems: 3
	}
}
});
});


$('body').materialScrollTop();

