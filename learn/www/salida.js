// learn/www/salida.js
//
// Pregunta antes de cerrar o recargar cuando hay cambios sin guardar.
// El servidor manda {avisar: true|false} por "sda-salida" (ui/transversal/sesion.R).
// El texto del diálogo lo pone el navegador; solo se puede pedir que aparezca.
(function () {
  var avisar = false;
  window.addEventListener("beforeunload", function (evento) {
    if (!avisar) return;
    evento.preventDefault();
    evento.returnValue = "";
  });
  function enganchar() {
    Shiny.addCustomMessageHandler("sda-salida", function (mensaje) {
      avisar = !!mensaje.avisar;
    });
  }
  if (window.Shiny && Shiny.addCustomMessageHandler) enganchar();
  else document.addEventListener("shiny:connected", enganchar, { once: true });
})();
