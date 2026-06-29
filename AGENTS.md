# Repository Guidelines

## Project Structure & Module Organization
This is a minimal LaTeX article template. `main.tex` is the default document entry point, and `references.bib` is the BibTeX database. Optional source directories `figures/`, `tables/`, and `tikz/` are copied into export archives when present. `scripts/create_source_bundle.sh` creates Overleaf and arXiv source bundles; `scripts/check_svg_build.sh` verifies SVG build support. Generated outputs belong in `build/` or LaTeX temporary files ignored by `.gitignore`; do not commit PDFs, archives, or `svg-inkscape/`.

## Build, Test, and Development Commands
- `make`: build `build/main.pdf` with `latexmk`.
- `make check`: run `chktex` and a strict PDF build with shell escape enabled.
- `make test`: run the minimal `\includesvg` regression check.
- `make overleaf-zip`: create `build/main-overleaf.zip`.
- `make arxiv-zip`: create `build/main-arxiv.zip` after `build/main.bbl` exists.
- `make arxiv-check`: validate, list, extract, and rebuild the arXiv archive.
- `make clean`: remove generated build artifacts.

Use `make PAPER=paper check` for a non-`main.tex` entry point.

## Coding Style & Naming Conventions
Keep LaTeX source readable: one logical paragraph per block, descriptive labels, and package comments only when they explain a non-obvious dependency. Use lowercase, hyphenated or underscored filenames for assets. Keep shell scripts in Bash with `set -euo pipefail`, quoted paths, and clear error messages.

## Testing Guidelines
Run `make check` before handoff for manuscript changes. Run `make test` when touching SVG support, `\includesvg`, or Makefile shell-escape behavior. Run `make arxiv-check` after changing archive packaging, bibliography handling, or optional source-directory copying.

## Commit & Pull Request Guidelines
Use short, imperative or descriptive commit subjects, matching existing history, for example `Add template files`. PRs should summarize the document or workflow change, list commands run, and note any generated artifacts inspected. Include PDF screenshots only for visible layout or figure changes.
