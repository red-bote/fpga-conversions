# Build a DarFPGA hardware platform port for the Basys 3.
#   make hardware <name>   name = machine dir name or unique prefix
#   make <name>            same thing
#   make clean             empty the downloaded-archives directory (dloads/)
#   make help              usage
#
# Delegates to <Machine>/contrib/basys3/create_project.sh, run from /tmp so
# vivado.log / vivado.jou land outside the repo (AGENTS.md convention).

REPO_ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/
MACHINES  := $(sort $(notdir $(wildcard $(REPO_ROOT)*-by-Dar $(REPO_ROOT)*-Dar)))

.PHONY: help hardware clean $(MACHINES)

help:
	@echo "usage: make hardware <name>   (machine dir name or unique prefix)"
	@echo "machines: $(MACHINES)"
	@echo "example: make hardware Pooyan"
	@echo "make clean                     empty the downloaded-archives directory (dloads/)"

hardware: $(filter-out hardware,$(MAKECMDGOALS))
	@$(if $(filter-out hardware,$(MAKECMDGOALS)),true,$(MAKE) --no-print-directory help)

# empty the downloaded-archives directory (resolved via --print-dir), keep the dir
clean:
	@dir="$$(bash "$(REPO_ROOT)download_darfpga.sh" --print-dir)"; \
	 if [ -d "$$dir" ]; then find "$$dir" -mindepth 1 -delete; fi

# exact directory name -> run that machine's build
$(MACHINES):
	@[ -x "$(REPO_ROOT)$@/contrib/basys3/create_project.sh" ] \
		|| { echo "error: $@ has no contrib/basys3/create_project.sh yet" >&2; exit 1; }
	@cd /tmp && "$(REPO_ROOT)$@/contrib/basys3/create_project.sh"

# prefix/glob match against the complete directory names
%:
	@dirs=$$(for m in $(MACHINES); do case "$$m" in "$@"*) echo "$$m";; esac; done); \
	 if [ $$(printf '%s\n' $$dirs | grep -c .) -ne 1 ]; then \
	   echo "error: '$@' does not match exactly one machine directory" >&2; \
	   echo "machines: $(MACHINES)" >&2; exit 1; \
	 fi; \
	 set -- $$dirs; \
	 [ -x "$(REPO_ROOT)$$1/contrib/basys3/create_project.sh" ] \
	   || { echo "error: $(REPO_ROOT)$$1 has no contrib/basys3/create_project.sh yet" >&2; exit 1; }; \
	 cd /tmp && "$(REPO_ROOT)$$1/contrib/basys3/create_project.sh"
