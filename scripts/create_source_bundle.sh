#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 4 ]]; then
  printf 'Usage: %s {overleaf|arxiv} PAPER STAGING_DIR ARCHIVE_PATH\n' "$0" >&2
  exit 2
fi

bundle_type=$1
paper=$2
staging_dir=$3
archive_path=$4
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$(dirname "$archive_path")"
archive_dir=$(cd "$(dirname "$archive_path")" && pwd)
archive_path="${archive_dir}/$(basename "$archive_path")"

case "$bundle_type" in
  overleaf|arxiv) ;;
  *)
    printf 'Unknown bundle type: %s\n' "$bundle_type" >&2
    exit 2
    ;;
esac

readonly required_files=(
  "${paper}.tex"
  "references.bib"
)

readonly optional_dirs=(
  "figures"
  "tables"
  "tikz"
)

rm -rf "$staging_dir"
mkdir -p "$staging_dir" "$(dirname "$archive_path")"

for relative_path in "${required_files[@]}"; do
  source_path="$repo_root/$relative_path"
  destination_path="$staging_dir/$relative_path"

  if [[ ! -f "$source_path" ]]; then
    printf 'Missing required %s bundle file: %s\n' "$bundle_type" "$relative_path" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$destination_path")"
  cp "$source_path" "$destination_path"
done

for relative_dir in "${optional_dirs[@]}"; do
  source_dir="$repo_root/$relative_dir"

  if [[ -d "$source_dir" ]]; then
    mkdir -p "$staging_dir/$relative_dir"
    cp -R "$source_dir"/. "$staging_dir/$relative_dir"/
  fi
done

if [[ "$bundle_type" == "arxiv" ]]; then
  bbl_path="$repo_root/build/${paper}.bbl"

  if [[ ! -f "$bbl_path" ]]; then
    printf 'Missing required arxiv bundle file: build/%s.bbl\n' "$paper" >&2
    exit 1
  fi

  cp "$bbl_path" "$staging_dir/${paper}.bbl"
fi

case "$archive_path" in
  *.tar.gz|*.tgz)
    tar -czf "$archive_path" -C "$staging_dir" .
    ;;
  *.zip)
    rm -f "$archive_path"
    (
      cd "$staging_dir"
      zip -q -r "$archive_path" .
    )
    ;;
  *)
    printf 'Unsupported archive extension: %s\n' "$archive_path" >&2
    exit 2
    ;;
esac

printf 'Created %s\n' "$archive_path"
