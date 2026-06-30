# LaTeX Template

This is a template for building LaTeX documents with reproducible local builds
and source-export archives.

## Build

Use the Makefile targets from the repository root:

```sh
make
make check
make test
make arxiv-title
make arxiv-abstract
make arxiv-metadata
make check-arxiv-abstract
make overleaf-zip
make arxiv-zip
make arxiv-check
make clean
```

- `make` builds `build/main.pdf`.
- `make check` runs `chktex`, verifies that the plain-text abstract is at most
  1920 characters for arXiv, and builds the PDF with shell escape enabled for
  SVG conversion.
- `make test` runs the SVG and arXiv metadata regression checks.
- `make arxiv-title` prints the plain-text title for the arXiv submission form.
- `make arxiv-abstract` prints the plain-text abstract for the arXiv submission
  form.
- `make arxiv-metadata` prints the extracted title, abstract, and abstract
  character count.
- `make check-arxiv-abstract` runs only the arXiv abstract-length gate.
- `make overleaf-zip` creates `build/main-overleaf.zip`, a source archive for
  uploading to Overleaf.
- `make arxiv-zip` creates `build/main-arxiv.zip`, a pruned and
  comment-stripped source archive for arXiv.
- `make arxiv-zip ARXIV_PRUNE=0` creates a broad arXiv archive with the same
  source-copying behavior as the Overleaf export, while still stripping LaTeX
  comments.
- `make arxiv-check` verifies the abstract length, creates the arXiv archive,
  tests and lists its contents, extracts it into a temporary directory, and
  compiles it there with strict `latexmk` settings.
- `make clean` removes generated LaTeX files and the `build/` directory.

The default paper stem is `main`. To build another entry point, pass `PAPER`:

```sh
make PAPER=paper
make arxiv-check PAPER=paper
```

The arXiv metadata targets require Pandoc. Override `PANDOC` to use a non-default
binary, and override `ARXIV_ABSTRACT_MAX_CHARS` only if arXiv changes its
submission limit.

## Layout

- `main.tex`: default document entry point.
- `references.bib`: BibTeX database.
- `figures/`, `tables/`, and `tikz/`: optional source directories copied into
  Overleaf and non-pruned arXiv archives when present. Default arXiv archives
  include only compile inputs recorded in `build/main.fls`.
- `scripts/create_source_bundle.sh`: source bundle helper used by the export
  targets.
- `scripts/extract_arxiv_metadata.sh`: extracts the arXiv title and abstract as
  normalized plain text.
- `scripts/check_arxiv_metadata.sh`: regression checks for the metadata
  extraction and length-limit behavior.

The default arXiv archive includes the generated `.bbl` file from `build/`,
omits unneeded source files such as `references.bib` unless the recorder file
shows they are compile inputs, and strips comments from staged LaTeX-like files.
