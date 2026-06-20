PAPER ?= main
BUILD_DIR := build
LATEXMK := latexmk
LATEXMK_STRICT_FLAGS := -pdf -Werror -interaction=nonstopmode -halt-on-error -file-line-error
LATEXMK_FLAGS := $(LATEXMK_STRICT_FLAGS) -shell-escape -outdir=$(BUILD_DIR)
CHKTEX := chktex
ZIP ?= zip
UNZIP ?= unzip

LATEX_ARTIFACT_EXTS := aux bbl blg fdb_latexmk fls log out pdf toc lof lot nav snm run.xml bcf synctex.gz
ROOT_ARTIFACTS := $(addprefix $(PAPER).,$(LATEX_ARTIFACT_EXTS))
PAPER_BBL := $(BUILD_DIR)/$(PAPER).bbl
OVERLEAF_ZIP := $(BUILD_DIR)/$(PAPER)-overleaf.zip
OVERLEAF_STAGE := $(BUILD_DIR)/overleaf-src
ARXIV_ZIP := $(BUILD_DIR)/$(PAPER)-arxiv.zip
ARXIV_STAGE := $(BUILD_DIR)/arxiv-src
OPTIONAL_SOURCE_DIRS := figures tables tikz
SOURCE_DIR_FILES := $(shell find $(OPTIONAL_SOURCE_DIRS) -type f 2>/dev/null)
SOURCE_DEPS := $(PAPER).tex references.bib $(SOURCE_DIR_FILES)

.PHONY: all check test check-svg-build lint overleaf-zip arxiv-zip arxiv-check clean reset clean-root-artifacts

all: $(BUILD_DIR)/$(PAPER).pdf

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/$(PAPER).pdf: $(SOURCE_DEPS) | $(BUILD_DIR) clean-root-artifacts
	$(LATEXMK) $(LATEXMK_FLAGS) $(PAPER).tex

check: lint $(BUILD_DIR)/$(PAPER).pdf

test: check-svg-build

check-svg-build: scripts/check_svg_build.sh
	./scripts/check_svg_build.sh

lint:
	$(CHKTEX) -q $(PAPER).tex

overleaf-zip: $(OVERLEAF_ZIP)

.PHONY: $(OVERLEAF_ZIP) $(ARXIV_ZIP)
$(OVERLEAF_ZIP): $(SOURCE_DEPS) | $(BUILD_DIR)
	./scripts/create_source_bundle.sh overleaf "$(PAPER)" "$(OVERLEAF_STAGE)" "$@"

arxiv-zip: $(ARXIV_ZIP)

$(PAPER_BBL): $(BUILD_DIR)/$(PAPER).pdf
	test -f $@

$(ARXIV_ZIP): $(SOURCE_DEPS) $(PAPER_BBL) | $(BUILD_DIR)
	./scripts/create_source_bundle.sh arxiv "$(PAPER)" "$(ARXIV_STAGE)" "$@"

arxiv-check: $(ARXIV_ZIP)
	$(UNZIP) -t $(ARXIV_ZIP)
	$(UNZIP) -Z1 $(ARXIV_ZIP)
	set -e; tmpdir=$$(mktemp -d); trap 'rm -rf "$$tmpdir"' EXIT; $(UNZIP) -q $(ARXIV_ZIP) -d "$$tmpdir"; cd "$$tmpdir" && $(LATEXMK) $(LATEXMK_STRICT_FLAGS) $(PAPER).tex

clean-root-artifacts:
	rm -f $(ROOT_ARTIFACTS)

clean:
	rm -f $(ROOT_ARTIFACTS)
	rm -rf $(BUILD_DIR) svg-inkscape/

reset: clean
