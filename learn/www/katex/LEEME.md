# KaTeX vendorizado

Copia local de [KaTeX](https://katex.org) **v0.16.11**, licencia MIT, tomada del
release oficial `katex.tar.gz` de
`https://github.com/KaTeX/KaTeX/releases/tag/v0.16.11`.

## Por qué vive dentro del repo

La app se publica como bundle wasm servido con archivos estáticos. Un CDN sería
una petición de red que ese modo no garantiza: sin conexión —o detrás de un
proxy— las fórmulas quedarían en TeX crudo sin que nada avise. Vendorizado, el
bundle es autocontenido.

Es la única excepción a C10 («sin JavaScript propio»), y está razonada en
`learn/CONVENCIONES.md`.

## Qué se copió y qué no

| Archivo | Origen |
|---|---|
| `katex.min.js` | tal cual del release |
| `katex.min.css` | tal cual del release |
| `fonts/*.woff2` | 20 archivos, tal cual del release |
| `enganche.js` | **nuestro**, ver el comentario de cabecera |

**Se descartaron los `.woff` y los `.ttf`** (el release trae los tres formatos
de cada fuente). Son el respaldo para navegadores sin `woff2`, que ya no
existen entre los que pueden correr webR. Recorta el bundle de ~1,2 MB a ~590 KB
y no dispara peticiones: el navegador pide el primer formato que soporta y no
mira los otros.

Se descartó también `contrib/` entero, incluido `auto-render.min.js`: el
renderizado va por clase de nodo, no por delimitadores. Ver `enganche.js`.

## Cómo actualizar

```bash
curl -sSL -o katex.tar.gz \
  https://github.com/KaTeX/KaTeX/releases/download/vX.Y.Z/katex.tar.gz
tar xzf katex.tar.gz
cp katex/katex.min.js katex/katex.min.css learn/www/katex/
cp katex/fonts/*.woff2 learn/www/katex/fonts/
```

`enganche.js` no se toca al actualizar. Después: `Rscript
learn/R/pruebas/test_app.R`, que comprueba que hay nodos `.katex` en el DOM.
