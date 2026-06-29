# LaTeX Template

This is a template for building LaTeX documents with reproducible local builds
and source-export archives.

## Build

Use the Makefile targets from the repository root:

```sh
make
make check
make test
make overleaf-zip
make arxiv-zip
make arxiv-check
make clean
```

- `make` builds `build/main.pdf`.
- `make check` runs `chktex` and a strict `latexmk` build with shell escape
  enabled for SVG conversion.
- `make test` verifies that the Makefile can build a minimal document using
  `\includesvg`.
- `make overleaf-zip` creates `build/main-overleaf.zip`, a source archive for
  uploading to Overleaf.
- `make arxiv-zip` creates `build/main-arxiv.zip`, a pruned and
  comment-stripped source archive for arXiv.
- `make arxiv-zip ARXIV_PRUNE=0` creates a broad arXiv archive with the same
  source-copying behavior as the Overleaf export, while still stripping LaTeX
  comments.
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
  Overleaf and non-pruned arXiv archives when present. Default arXiv archives
  include only compile inputs recorded in `build/main.fls`.
- `scripts/create_source_bundle.sh`: source bundle helper used by the export
  targets.

The default arXiv archive includes the generated `.bbl` file from `build/`,
omits unneeded source files such as `references.bib` unless the recorder file
shows they are compile inputs, and strips comments from staged LaTeX-like files.
