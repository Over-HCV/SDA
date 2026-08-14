/* Enganche de KaTeX. Ver learn/R/nucleo/formulas.R y learn/CONVENCIONES.md C10.
 *
 * R deja en el DOM nodos <div class="formula-bloque"> y <span
 * class="formula-linea"> con el TeX literal adentro. Esto los busca y llama a
 * katex.render() sobre cada uno.
 *
 * Se renderiza por clase y no con auto-render por delimitadores porque el lado
 * de R ya sabe qué es una fórmula: no hace falta volver a escanear el
 * documento buscando signos de peso, ni cargar auto-render.min.js.
 *
 * El MutationObserver está porque no todo el HTML existe al cargar: las fichas
 * de método se abren en un modal y cualquier renderUI aparece después. Sin él,
 * las fórmulas de esos sitios se quedarían en TeX crudo.
 */
(function () {
  "use strict";

  var SELECTOR = ".formula-bloque, .formula-linea";

  function render(nodo) {
    if (nodo.getAttribute("data-formula-lista")) return;
    var tex = nodo.textContent;
    nodo.setAttribute("data-formula-lista", "1");
    try {
      window.katex.render(tex, nodo, {
        displayMode: nodo.classList.contains("formula-bloque"),
        output: "htmlAndMathml",
        throwOnError: false
      });
    } catch (e) {
      // Que falle una fórmula no puede dejar la card en blanco: se deja el TeX
      // crudo, que al menos se lee.
      nodo.textContent = tex;
    }
  }

  function pintar(raiz) {
    if (!window.katex || !raiz || !raiz.querySelectorAll) return;
    // La raíz puede ser ella misma una fórmula: cuando Shiny inserta el nodo
    // suelto, querySelectorAll no lo encuentra porque solo mira descendientes.
    if (raiz.matches && raiz.matches(SELECTOR)) render(raiz);
    var nodos = raiz.querySelectorAll(SELECTOR);
    for (var i = 0; i < nodos.length; i++) render(nodos[i]);
  }

  // Solo se miran los nodos que ACABAN de entrar, no el documento entero. Con
  // un querySelectorAll sobre todo el body en cada mutación, la app se
  // arrastraba: Shiny muta el DOM constantemente y el observador se disparaba
  // en cada redibujo de cada output.
  function observar() {
    pintar(document.body);
    if (!window.MutationObserver) return;
    new MutationObserver(function (mutaciones) {
      for (var i = 0; i < mutaciones.length; i++) {
        var nuevos = mutaciones[i].addedNodes;
        for (var j = 0; j < nuevos.length; j++) {
          if (nuevos[j].nodeType === 1) pintar(nuevos[j]);
        }
      }
    }).observe(document.body, { childList: true, subtree: true });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", observar);
  } else {
    observar();
  }
})();
