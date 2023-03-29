function visible(cb, element) {
  document.getElementById(element).style.display = cb.checked ? "block" : "none";
}
function update(cb, element) {
  document.getElementById(element).innerHTML = cb.value;
}
