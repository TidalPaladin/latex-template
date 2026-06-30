#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s {title|abstract|metadata|abstract-length|check-abstract} PAPER_TEX [MAX_ABSTRACT_CHARS]\n' "$0" >&2
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
  exit 2
fi

mode=$1
paper_path=$2
max_abstract_chars=${3:-${ARXIV_ABSTRACT_MAX_CHARS:-1920}}
pandoc_bin=${PANDOC:-pandoc}
tmpdir=$(mktemp -d)

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

case "$mode" in
  title|abstract|metadata|abstract-length|check-abstract) ;;
  *)
    usage
    exit 2
    ;;
esac

if [[ ! -f "$paper_path" ]]; then
  printf 'Missing LaTeX source file: %s\n' "$paper_path" >&2
  exit 1
fi

if ! command -v "$pandoc_bin" >/dev/null 2>&1; then
  printf 'Missing required command for arXiv metadata extraction: %s\n' "$pandoc_bin" >&2
  exit 1
fi

if [[ ! "$max_abstract_chars" =~ ^[0-9]+$ ]]; then
  printf 'MAX_ABSTRACT_CHARS must be a non-negative integer, got: %s\n' "$max_abstract_chars" >&2
  exit 2
fi

normalize_text() {
  perl -0pe 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

extract_field() {
  local field=$1
  local template_path="$tmpdir/$field.template"

  printf '$%s$\n' "$field" > "$template_path"
  "$pandoc_bin" -s -f latex -t plain --wrap=none --template="$template_path" "$paper_path" | normalize_text
}

count_chars() {
  local text=$1

  printf '%s' "$text" | perl -MEncode=decode -e 'BEGIN { binmode(STDIN, ":raw") } local $/; my $bytes = <STDIN>; $bytes = "" unless defined $bytes; my $text = decode("UTF-8", $bytes, Encode::FB_CROAK); print length($text);'
}

title=""
abstract=""
abstract_chars=""

case "$mode" in
  title)
    title=$(extract_field title)
    printf '%s\n' "$title"
    ;;
  abstract)
    abstract=$(extract_field abstract)
    printf '%s\n' "$abstract"
    ;;
  abstract-length)
    abstract=$(extract_field abstract)
    count_chars "$abstract"
    printf '\n'
    ;;
  check-abstract)
    abstract=$(extract_field abstract)
    abstract_chars=$(count_chars "$abstract")

    if (( abstract_chars > max_abstract_chars )); then
      printf 'arXiv abstract length: %s/%s characters; exceeds limit\n' "$abstract_chars" "$max_abstract_chars" >&2
      exit 1
    fi

    printf 'arXiv abstract length: %s/%s characters\n' "$abstract_chars" "$max_abstract_chars"
    ;;
  metadata)
    title=$(extract_field title)
    abstract=$(extract_field abstract)
    abstract_chars=$(count_chars "$abstract")

    printf 'Title:\n%s\n\n' "$title"
    printf 'Abstract:\n%s\n\n' "$abstract"
    printf 'Abstract characters: %s/%s\n' "$abstract_chars" "$max_abstract_chars"
    ;;
esac
