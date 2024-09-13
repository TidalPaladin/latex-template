LATEX = pdflatex
BIB = bibtex

%.pdf: %.tex references.bib $(wildcard figures/*) $(wildcard tables/*)
	$(LATEX) -interaction=nonstopmode -shell-escape $* || true
	$(BIB) $*
	$(LATEX) -interaction=nonstopmode -shell-escape $* 

clean:
	# X: Only remove files that match .gitignore (don't remove untracked files)
	# d: Also delete entire directories that match .gitignore
	# f: Actually delete instead of warn
	git clean -Xdf

reset:
	$(MAKE) clean