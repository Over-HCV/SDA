@default_files = ('main-es.tex');

# Force xelatex + build/ output NO MATTER HOW latexmk is invoked
# (command-line flags from editors can otherwise override .latexmkrc).
$pdf_mode = 5;                                 # 5 = xelatex
$out_dir  = 'build';                           # all aux+pdf → build/
$aux_dir  = 'build';                           # (latexmk >= 4.69)
$clean_ext = 'synctex.gz run.xml bbl bcf fls fdb_latexmk xdv crt lof lot';

$xelatex = 'xelatex -interaction=nonstopmode -synctex=1 -shell-escape %O %S';
$bibtex  = 'biber %O %S';
$maxrep  = 6;                                  # enough passes for TOC/LOF/LOT/bib
