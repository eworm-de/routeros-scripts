/* copy code to clipboard */
function CopyToClipboard(element) {
  element.style.filter = 'invert(1)';
  navigator.clipboard.writeText(element.firstElementChild.innerHTML);
  setTimeout(function() {
    element.style.filter = 'invert(0)';
  }, 100);
}
