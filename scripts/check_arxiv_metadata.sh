#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
extract_script="$repo_root/scripts/extract_arxiv_metadata.sh"
tmpdir=$(mktemp -d)

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

fail() {
  printf 'metadata regression failed: %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local expected=$1
  local actual=$2
  local label=$3

  if [[ "$actual" != "$expected" ]]; then
    printf 'metadata regression failed: %s\nexpected: %s\nactual:   %s\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
}

simple_tex="$tmpdir/simple.tex"
macro_tex="$tmpdir/macro.tex"
length_tex="$tmpdir/length.tex"
unicode_tex="$tmpdir/unicode.tex"
empty_tex="$tmpdir/empty.tex"

cat > "$simple_tex" <<'TEX'
\documentclass{article}
\title{Simple Paper Title}
\begin{document}
\begin{abstract}
This is a simple abstract.
\end{abstract}
\end{document}
TEX

cat > "$macro_tex" <<'TEX'
\documentclass{article}
\newcommand{\titletext}{Macro Backed Title}
\title{\titletext}
\begin{document}
\begin{abstract}
Macro \textbf{abstract} with \emph{emphasis}.
\end{abstract}
\end{document}
TEX

cat > "$length_tex" <<'TEX'
\documentclass{article}
\title{Length Check}
\begin{document}
\begin{abstract}
abcd
\end{abstract}
\end{document}
TEX

cat > "$unicode_tex" <<'TEX'
\documentclass{article}
\title{Unicode Check}
\begin{document}
\begin{abstract}
ééé
\end{abstract}
\end{document}
TEX

cat > "$empty_tex" <<'TEX'
\documentclass{article}
\title{Empty Abstract Check}
\begin{document}
\end{document}
TEX

assert_eq "Simple Paper Title" "$("$extract_script" title "$simple_tex")" "simple title extraction"
assert_eq "This is a simple abstract." "$("$extract_script" abstract "$simple_tex")" "simple abstract extraction"
assert_eq "Macro Backed Title" "$("$extract_script" title "$macro_tex")" "macro-backed title extraction"
assert_eq "Macro abstract with emphasis." "$("$extract_script" abstract "$macro_tex")" "formatted abstract extraction"
assert_eq "4" "$("$extract_script" abstract-length "$length_tex")" "abstract length excludes trailing newline"
assert_eq "3" "$(LC_ALL=C "$extract_script" abstract-length "$unicode_tex")" "unicode abstract length ignores locale byte counting"
assert_eq "0" "$("$extract_script" abstract-length "$empty_tex")" "missing abstract length is zero"

"$extract_script" check-abstract "$length_tex" 4 >/dev/null

if "$extract_script" check-abstract "$length_tex" 3 >/dev/null 2>&1; then
  fail "abstract length check should fail above the configured limit"
fi

printf 'arXiv metadata regression checks passed\n'
