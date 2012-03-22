# Put user-specific changes in your own Makefile.user.
# Make will silently continue if that file does not exist.
-include Makefile.user

PDFLATEX ?= pdflatex
BIBTEX ?= bibtex

MAKE ?= make

# To regenerate list of files:  latex-process-inputs --makefilelist main.tex
TEX_FILES = \
2012-pipejam.tex


NAME	:= 2012-pipejam
# EPSFIGS := bst.eps
# FIGS	:= $(DOTFIGS) $(PNGFIGS) $(EPSFIGS)
export BIBINPUTS ?= .:bib

all: figures-all $(NAME).pdf

figures-all:
#	${MAKE} -C figures all

clean:
	rm -f $(NAME).bbl $(NAME).dvi $(NAME).ps $(NAME).pdf $(NAME).aux $(NAME).log $(NAME).blg $(NAME)-gs.pdf $(NAME)-dir.pdf $(NAME).out

%.ps: %.dot
	dot -Tps $< > $@

%.ps: %.png
	pngtopnm $< | pnmtops -noturn > $@

.PRECIOUS: %.pdf
%.pdf: %.tex $(FIGS) %.bbl
	${PDFLATEX} $<
	${PDFLATEX} $<
	while grep "Rerun to get" $(basename $<).log; do ${PDFLATEX} '$(basename $<).tex'; done
	${PDFLATEX} $<

%.bbl: %.tex bib-update
	${PDFLATEX} $<
	${BIBTEX} $(basename $<)

%.eps: %.gnuplot
	gnuplot $<

TAGS: ${TEX_FILES}
	etags ${TEX_FILES}

tags: TAGS

ispell: spell

## Does not work with aspell.
# spell: ${TEX_FILES}
# 	ispell ${TEX_FILES}

## Does not work under /bin/sh
# spell: ${TEX_FILES}
# 	foreach file (${TEX_FILES})
# 	  ispell $$file
# 	end

spell:
	for file in ${TEX_FILES}; do ispell $$file; done

# DOCS = main.ps main.pdf
# dist: docs
# 	cp -p ${DOCS} ${HOME}/www/

# Count words in the abstract
abs-words:
	grep -v 'Abstract' abstract.tex | egrep -v '^%' | wc -w

bib:
	hg clone https://plume-bib.googlecode.com/hg/ bib
.PHONY: bib-update
bib-update: bib
	cd bib && hg pull -u && make
