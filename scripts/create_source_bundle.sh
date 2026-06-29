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
repo_root=$(realpath "$repo_root")
mkdir -p "$(dirname "$archive_path")"
archive_dir=$(cd "$(dirname "$archive_path")" && pwd)
archive_path="${archive_dir}/$(basename "$archive_path")"
arxiv_prune=1

case "$bundle_type" in
  overleaf|arxiv) ;;
  *)
    printf 'Unknown bundle type: %s\n' "$bundle_type" >&2
    exit 2
    ;;
esac

if [[ "$bundle_type" == "arxiv" ]]; then
  arxiv_prune=${ARXIV_PRUNE:-1}

  case "$arxiv_prune" in
    0|1) ;;
    *)
      printf 'ARXIV_PRUNE must be 0 or 1, got: %s\n' "$arxiv_prune" >&2
      exit 2
      ;;
  esac
fi

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

copy_absolute_source() {
  local source_path=$1
  local relative_path=$2
  local destination_path="$staging_dir/$relative_path"

  mkdir -p "$(dirname "$destination_path")"
  cp "$source_path" "$destination_path"
}

copy_repo_file() {
  local relative_path=$1
  local source_path="$repo_root/$relative_path"

  if [[ ! -f "$source_path" ]]; then
    printf 'Missing required %s bundle file: %s\n' "$bundle_type" "$relative_path" >&2
    exit 1
  fi

  copy_absolute_source "$source_path" "$relative_path"
}

copy_broad_sources() {
  local relative_path
  local relative_dir
  local source_dir

  for relative_path in "${required_files[@]}"; do
    copy_repo_file "$relative_path"
  done

  for relative_dir in "${optional_dirs[@]}"; do
    source_dir="$repo_root/$relative_dir"

    if [[ -d "$source_dir" ]]; then
      mkdir -p "$staging_dir/$relative_dir"
      cp -R "$source_dir"/. "$staging_dir/$relative_dir"/
    fi
  done
}

copy_pruned_arxiv_sources() {
  local fls_path="$repo_root/build/${paper}.fls"
  local line
  local input_path
  local source_path
  local source_canonical
  local relative_path
  local destination_path

  if [[ ! -f "$fls_path" ]]; then
    printf 'Missing required arxiv recorder file: build/%s.fls\n' "$paper" >&2
    exit 1
  fi

  declare -A staged_paths=()

  while IFS= read -r line; do
    [[ "$line" == INPUT\ * ]] || continue

    input_path=${line#INPUT }
    if [[ "$input_path" == /* ]]; then
      source_path="$input_path"
    else
      source_path="$repo_root/$input_path"
    fi

    [[ -f "$source_path" ]] || continue

    source_canonical=$(realpath "$source_path")
    case "$source_canonical" in
      "$repo_root"/*) ;;
      *) continue ;;
    esac

    relative_path=${source_canonical#"$repo_root"/}
    case "$relative_path" in
      "build/${paper}.bbl")
        destination_path="${paper}.bbl"
        ;;
      build/*)
        continue
        ;;
      *)
        destination_path="$relative_path"
        ;;
    esac

    if [[ -n "${staged_paths[$destination_path]:-}" ]]; then
      continue
    fi

    copy_absolute_source "$source_canonical" "$destination_path"
    staged_paths[$destination_path]=1
  done < "$fls_path"
}

strip_latex_comments() {
  local source_path=$1

  perl -0pi -e '
    my %verbatim_envs = map { $_ => 1 } qw(verbatim Verbatim BVerbatim LVerbatim lstlisting minted alltt spverbatim filecontents filecontents*);
    my $active_verbatim = "";
    my $active_comment = 0;

    sub strip_line_comment {
      my ($line) = @_;
      my $out = "";
      my $length = length($line);

      for (my $i = 0; $i < $length; $i++) {
        my $char = substr($line, $i, 1);
        if ($char eq "%") {
          my $slashes = 0;
          for (my $j = $i - 1; $j >= 0 && substr($line, $j, 1) eq "\\"; $j--) {
            $slashes++;
          }
          if ($slashes % 2 == 1) {
            $out .= $char;
            next;
          }
          return ($out . "%", 1);
        }
        $out .= $char;
      }

      return ($out, 0);
    }

    sub remove_comment_environment {
      my ($line) = @_;
      my $out = "";

      while (length($line) > 0) {
        if ($active_comment) {
          if ($line =~ s/^.*?\\end\{comment\}//s) {
            $active_comment = 0;
            next;
          }
          return $out;
        }

        if ($line =~ s/^(.*?)\\begin\{comment\}//s) {
          $out .= $1;
          $active_comment = 1;
          next;
        }

        $out .= $line;
        last;
      }

      return $out;
    }

    my $result = "";
    for my $line (split /(?<=\n)/, $_) {
      my $newline = "";
      $newline = $1 if $line =~ s/(\r?\n)\z//;

      if ($active_verbatim ne "") {
        $result .= $line . $newline;
        if ($line =~ /\\end\{\Q$active_verbatim\E\}/) {
          $active_verbatim = "";
        }
        next;
      }

      $line = remove_comment_environment($line);
      if ($active_comment) {
        $result .= $line . $newline;
        next;
      }

      if ($line =~ /\\begin\{([A-Za-z*]+)\}/ && $verbatim_envs{$1}) {
        my $env = $1;
        my $begin_index = $-[0];
        my $prefix = substr($line, 0, $begin_index);
        my $rest = substr($line, $begin_index);
        my ($stripped_prefix, $comment_found) = strip_line_comment($prefix);

        if ($comment_found) {
          $result .= $stripped_prefix . $newline;
          next;
        }

        $result .= $stripped_prefix . $rest . $newline;
        if ($rest !~ /\\end\{\Q$env\E\}/) {
          $active_verbatim = $env;
        }
        next;
      }

      my ($stripped, undef) = strip_line_comment($line);
      $result .= $stripped . $newline;
    }

    $_ = $result;
  ' "$source_path"
}

strip_arxiv_comments() {
  local source_path

  while IFS= read -r -d '' source_path; do
    strip_latex_comments "$source_path"
  done < <(
    find "$staging_dir" -type f \
      \( -name '*.tex' -o -name '*.sty' -o -name '*.cls' -o -name '*.ltx' -o -name '*.tikz' -o -name '*.bbl' \) \
      -print0
  )
}

if [[ "$bundle_type" == "arxiv" && "$arxiv_prune" == "1" ]]; then
  copy_pruned_arxiv_sources
else
  copy_broad_sources
fi

if [[ "$bundle_type" == "arxiv" ]]; then
  bbl_path="$repo_root/build/${paper}.bbl"

  if [[ ! -f "$bbl_path" ]]; then
    printf 'Missing required arxiv bundle file: build/%s.bbl\n' "$paper" >&2
    exit 1
  fi

  copy_absolute_source "$bbl_path" "${paper}.bbl"
  strip_arxiv_comments
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
