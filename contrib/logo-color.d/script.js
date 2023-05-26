function invertHex(hex) {
  return (Number("0x1" + hex) ^ 0xffffff).toString(16).substr(1);
}

function color() {
  var svg = document.querySelector(".logo").getSVGDocument();
  svg.getElementById("dark-1").setAttribute("stop-color", document.getElementById("color1").value);
  svg.getElementById("dark-2").setAttribute("stop-color", document.getElementById("color2").value);
  var background = document.getElementById("color3").value;
  svg.getElementById("background").setAttribute("fill", background);
  svg.getElementById("hexagon").setAttribute("stroke", "#" + invertHex(background.substring(1)));
}
