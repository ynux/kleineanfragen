(function (document) {
  var body = document.getElementsByTagName('body')[0];
  if (!body) return;
  if (window['localStorage'] && localStorage.getItem('banner-seen')) return;
  var b = document.createElement("div");
  b.id = "datenschule_banner";
  b.innerHTML =
    '<a id="datenschule_banner_close" style="float:right; text-decoration: none !important;">&times;</a>'+
    'Die <b>OKF DE DATENSCHULE</b> nimmt an der Google Impact Challenge teil. Stimme ab! <a target="_blank" href="https://datenschule.de">datenschule.de</a>'+
    '<style>' +
    '#datenschule_banner { text-align:center; z-index:99999999; padding:18px; margin: 0; border: 1px solid #ececec; border-bottom: 0; position:fixed; right:4px;' +
    'font-family: Montserrat, Arial; font-weight: normal; text-decoration: none; font-size: 14px; bottom:0; left:4px; color:#fff !important; background-color:#FF5449 !important; } ' +
    '#datenschule_banner a {  cursor:pointer; font-size: 14px; font-weight: bold; text-decoration: underline; margin: 0; padding: 0; color:#fff !important; } ' +
    '#datenschule_banner a:hover,#datenschule_banner a:focus { color:#babab2!important; } ' +
    'a#datenschule_banner_close { font-size: 24px; line-height: 1; } ' +
    '</style>';
  b.addEventListener("click", function () {
    body.removeChild(b);
    if (window['localStorage']) {
      try {
        localStorage.setItem('banner-seen', true);
      } catch(_) {}
    }
    return true;
  });
  body.appendChild(b);
})(document);