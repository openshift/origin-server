function getURLParameter(name, query) {
    if (!query)
      query = location.search;
    return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(query)||[,""])[1].replace(/\+/g, '%20'))||null;
}

function writeQueryParams(params) {
  var first = true;
  var query = '';
  for (var param in params) {
    if (params[param] && params[param].length > 0) {
      query += first ? '?' : '&'
      query += param + "=" + params[param];
      if (first)
        first = false;
    }
  }
  return query;
}

function tooltip_placement(tip, element) {
  var $element, above, actualHeight, actualWidth, below, boundBottom, boundLeft, boundRight, boundTop, elementAbove, elementBelow, elementLeft, elementRight, isWithinBounds, left, pos, right;
  isWithinBounds = function(elementPosition) {
    return boundTop < elementPosition.top && boundLeft < elementPosition.left && boundRight > (elementPosition.left + actualWidth) && boundBottom > (elementPosition.top + actualHeight);
  };
  $element = $(element);
  pos = $.extend({}, $element.offset(), {
    width: element.offsetWidth,
    height: element.offsetHeight
  });
  actualWidth = 283;
  actualHeight = 117;
  boundTop = $(document).scrollTop();
  boundLeft = $(document).scrollLeft();
  boundRight = boundLeft + $(window).width();
  boundBottom = boundTop + $(window).height();
  elementAbove = {
    top: pos.top - actualHeight,
    left: pos.left + pos.width / 2 - actualWidth / 2
  };
  elementBelow = {
    top: pos.top + pos.height,
    left: pos.left + pos.width / 2 - actualWidth / 2
  };
  elementLeft = {
    top: pos.top + pos.height / 2 - actualHeight / 2,
    left: pos.left - actualWidth
  };
  elementRight = {
    top: pos.top + pos.height / 2 - actualHeight / 2,
    left: pos.left + pos.width
  };
  above = isWithinBounds(elementAbove);
  below = isWithinBounds(elementBelow);
  left = isWithinBounds(elementLeft);
  right = isWithinBounds(elementRight);
  if (above) {
    return "top";
  } else {
    if (below) {
      return "bottom";
    } else {
      if (left) {
        return "left";
      } else {
        if (right) {
          return "right";
        } else {
          return "right";
        }
      }
    }
  }
};