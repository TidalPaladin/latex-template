#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmpdir=$(mktemp -d)

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cp "$repo_root/Makefile" "$repo_root/references.bib" "$tmpdir"/
mkdir -p "$tmpdir/figures"

cat > "$tmpdir/main.tex" <<'TEX'
\documentclass{article}
\usepackage{svg}

\begin{document}
\includesvg{figures/sample}
\end{document}
TEX

cat > "$tmpdir/figures/sample.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 10 10">
  <rect width="10" height="10" fill="black"/>
</svg>
SVG

make -C "$tmpdir" check
