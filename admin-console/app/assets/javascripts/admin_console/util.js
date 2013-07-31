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