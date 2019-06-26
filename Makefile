.PHONY: all beautify clean conda help hooks rkpgs veryclean xaringan

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME = presentation_corkscrew_magnetism_mnau2

GITHUB_PAGES_BRANCH = gh-pages
STAGING_DIR = build

FIGURE_DIR = img
LIBS_DIR = libs

RM = rm
COPY = cp
FIND = find

BLACK = black
BLACK_OPTS = -t py37

CONDA = conda
CONDA_ENV_FILE = environment.yml

PRECOMMIT = pre-commit

R ?= Rscript

RMD = presentation_corkscrew_magnetism_mnau2.Rmd

XARINGAN = $(RMD:.Rmd=.html)
XARINGAN_EXT = %.html : %.Rmd
XARINGAN_OUTPUT = xaringan::moon_reader

PRESENTATION_FILES = \
    $(FIGURE_DIR) \
    $(LIBS_DIR)

CLEAN_FILES = *_cache/ *_files/ .Rhistory
FULL_CLEAN_FILES = *.egg-info/ pip-wheel-metadata/ .pytest_cache/

#################################################################################
# FUNCTIONS                                                                     #
#################################################################################

define cleanup
    $(FIND) -name "__pycache__" -type d -exec $(RM) -rf {} +
    $(FIND) -name "*.py[co]" -type f -exec $(RM) -rf {} +
    -$(RM) -rf $(CLEAN_FILES)
endef

define copy_presentation_files
    cp $(PROJECT_NAME).html $(STAGING_DIR)/index.html
    $(foreach filepath, $(PRESENTATION_FILES),\
        cp -rf $(filepath) $(STAGING_DIR);)
endef

define install_r_packages
    $(R) -e "install.packages('remotes', repos = 'https://cran.rstudio.com')"   \
         -e "remotes::install_deps(upgrade = 'never')"
endef

define full_cleanup
    $(call cleanup)
    -$(RM) -rf $(FULL_CLEAN_FILES)
endef

define make_subdirectory
    mkdir -p "$@"
endef

define precommit_cmd
    $(PRECOMMIT) $(1)
endef

define push_github_pages
    ghp-import -m "Update presentation" -b $(GITHUB_PAGES_BRANCH) $(STAGING_DIR)
    git push origin $(GITHUB_PAGES_BRANCH)
endef

define python_black
    $(BLACK) $(BLACK_OPTS) $(PY_SRC)
endef

define rmarkdown_render
    $(R) -e "source(here::here('R/xaringan_setup.R'));                          \
             rmarkdown::render(input = '$<', output_file = '$@',                \
             output_format = '$(strip $(1))')"
endef

define update_conda_env
    $(CONDA) env update --file $(CONDA_ENV_FILE)
endef

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Render documents in all formats
all: xaringan

## Reformat Python code with black
beautify:
	$(call python_black)

## Remove temporary files
clean:
	$(call cleanup)

## Create/update conda-based virtual environment
conda:
	$(call update_conda_env)

## Push the presentation to gh-pages
github: $(STAGING_DIR) xaringan
	$(call copy_presentation_files)
	$(call push_github_pages)

## Install pre-commit hooks
hooks:
	$(call precommit_cmd, install)

## Install R packages for compiling documents
rpkgs:
	$(call install_r_packages)

## Remove all temporary files
veryclean:
	$(call full_cleanup)

## Render presentation slides
xaringan: $(XARINGAN)

#################################################################################
# PROJECT RULES                                                                 #
#################################################################################

$(STAGING_DIR):
	$(call make_subdirectory)

$(XARINGAN): $(XARINGAN_EXT)
	$(call rmarkdown_render, $(XARINGAN_OUTPUT))

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
