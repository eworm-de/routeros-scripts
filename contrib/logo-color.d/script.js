function color() {
  var svg = document.querySelector(".logo").getSVGDocument();
  svg.getElementById("dark-1").setAttribute("stop-color", document.getElementById("color1").value);
  svg.getElementById("dark-2").setAttribute("stop-color", document.getElementById("color2").value);
}
