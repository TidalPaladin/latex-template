# LaTeX Template

This is a template for building LaTeX documents with reproducible local builds
and source-export archives.

## Build

Use the Makefile targets from the repository root:

```sh
make
make check
make overleaf-zip
make arxiv-zip
make arxiv-check
make clean
```

- `make` builds `build/main.pdf`.
- `make check` runs `chktex` and a strict `latexmk` build.
- `make overleaf-zip` creates `build/main-overleaf.zip`, a source archive for
  uploading to Overleaf.
- `make arxiv-zip` creates `build/main-arxiv.zip`, a source archive for arXiv.
- `make arxiv-check` creates the arXiv archive, tests and lists its contents,
  extracts it into a temporary directory, and compiles it there with strict
  `latexmk` settings.
- `make clean` removes generated LaTeX files and the `build/` directory.

The default paper stem is `main`. To build another entry point, pass `PAPER`:

```sh
make PAPER=paper
make arxiv-check PAPER=paper
```

## Layout

- `main.tex`: default document entry point.
- `references.bib`: BibTeX database.
- `figures/`, `tables/`, and `tikz/`: optional source directories copied into
  Overleaf and arXiv archives when present.
- `scripts/create_source_bundle.sh`: source bundle helper used by the export
  targets.

The arXiv archive includes the generated `.bbl` file from `build/` to reduce
bibliography build ambiguity during arXiv processing.
