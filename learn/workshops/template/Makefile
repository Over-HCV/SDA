LATEXMK   := latexmk
BUILDDIR  := build
MAINES    := main-es
MAINEN    := main-en
FINALFLAG := .final-mode
# mitthesis.cls y fontsets/ viven en el raíz del proyecto (esquema estándar
# del MIT template). No hace falta TEXINPUTS.

# FINAL=1 oculta las cajas \porque (versión entregable) creando .final-mode
.PHONY: es en all clean deepclean watch

all: es en

es:
	if [ -n "$(FINAL)" ]; then touch $(FINALFLAG); else rm -f $(FINALFLAG); fi
	$(LATEXMK) -pdfxe -outdir=$(BUILDDIR) $(MAINES).tex

en:
	if [ -n "$(FINAL)" ]; then touch $(FINALFLAG); else rm -f $(FINALFLAG); fi
	$(LATEXMK) -pdfxe -outdir=$(BUILDDIR) $(MAINEN).tex

watch:
	rm -f $(FINALFLAG)
	$(LATEXMK) -pdfxe -outdir=$(BUILDDIR) -pvc $(MAINES).tex

clean:
	$(LATEXMK) -C -outdir=$(BUILDDIR) $(MAINES).tex $(MAINEN).tex 2>/dev/null || true
	rm -rf $(BUILDDIR)
	rm -f $(FINALFLAG)
	# limpia también polución en raíz (por si se compiló sin -outdir)
	rm -f main-es.aux main-es.bbl main-es.bcf main-es.blg main-es.fdb_latexmk main-es.fls main-es.lof main-es.log main-es.lot main-es.out main-es.run.xml main-es.synctex.gz main-es.toc main-es.crt main-es.xdv main-es.pdf 2>/dev/null || true
	rm -f main-en.aux main-en.bbl main-en.bcf main-en.blg main-en.fdb_latexmk main-en.fls main-en.lof main-en.log main-en.lot main-en.out main-en.run.xml main-en.synctex.gz main-en.toc main-en.crt main-en.xdv main-en.pdf 2>/dev/null || true

deepclean: clean
	rm -f $(BUILDDIR)/*.fls $(BUILDDIR)/*.fdb_latexmk $(BUILDDIR)/*.xdv
