-- notas.lua — `::: notas` del .qmd al entorno LaTeX `notas`.
--
-- El entorno (recuadro rojo pastel titulado «Notas») y su interruptor
-- global (\mostrarnotasfalse, u `ocultar-notas: true` en el YAML) viven en
-- taller-qmd-template.tex. Se activa en el YAML del taller con
--
--   filters:
--     - ../template/notas.lua
--
-- \begin{notas} y \end{notas} salen en renglones propios porque el paquete
-- comment, que es el que las quita, los busca así.

function Div(div)
  if not div.classes:includes("notas") then return nil end
  local bloques = { pandoc.RawBlock("latex", "\\begin{notas}") }
  for _, b in ipairs(div.content) do table.insert(bloques, b) end
  table.insert(bloques, pandoc.RawBlock("latex", "\\end{notas}"))
  return bloques
end
