# Build a DarFPGA hardware platform port for the Basys 3.
#   make hardware <name>   name = machine dir name or unique prefix
#   make <name>            same thing
#   make distclean <name>  restore that machine dir to repo content only
#   make clean             empty the downloaded-archives directory (dloads/)
#   make help              usage
#
# Delegates to <Machine>/contrib/basys3/create_project.sh, run from /tmp so
# vivado.log / vivado.jou land outside the repo (AGENTS.md convention).
# make distclean <name> delegates to that machine's own Makefile distclean
# (only Pooyan has one so far).

REPO_ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/
MACHINES  := $(sort $(notdir $(wildcard $(REPO_ROOT)*-by-Dar $(REPO_ROOT)*-Dar)))
DISTCLEAN := $(filter distclean,$(MAKECMDGOALS))

.PHONY: help hardware distclean clean $(MACHINES)

help:
	@echo "usage: make hardware <name>   (machine dir name or unique prefix)"
	@echo "machines: $(MACHINES)"
	@echo "example: make hardware Pooyan"
	@echo "make distclean <name>          restore a machine dir to repo content only"
	@echo "make clean                     empty the downloaded-archives directory (dloads/)"

hardware: $(filter-out hardware,$(MAKECMDGOALS))
	@$(if $(filter-out hardware,$(MAKECMDGOALS)),true,$(MAKE) --no-print-directory help)

distclean:
	@for m in $(MACHINES); do \
	  if [ -f "$(REPO_ROOT)$$m/Makefile" ] && grep -q '^distclean:' "$(REPO_ROOT)$$m/Makefile"; then \
	    echo "distclean: $$m"; \
	    $(MAKE) --no-print-directory -C "$(REPO_ROOT)$$m" distclean; \
	  else \
	    echo "distclean: $$m (no Makefile distclean target, skipping)"; \
	  fi; \
	done

# empty the downloaded-archives directory (resolved via --print-dir), keep the dir
clean:
	@dir="$$(bash "$(REPO_ROOT)download_darfpga.sh" --print-dir)"; \
	 if [ -d "$$dir" ]; then find "$$dir" -mindepth 1 -delete; fi

# exact directory name -> run that machine's build (or distclean)
$(MACHINES):
	@if [ -n "$(DISTCLEAN)" ]; then \
	  [ -f "$(REPO_ROOT)$@/Makefile" ] \
	    || { echo "error: $@ has no Makefile with a distclean target" >&2; exit 1; }; \
	  $(MAKE) --no-print-directory -C "$(REPO_ROOT)$@" distclean; \
	else \
	  [ -x "$(REPO_ROOT)$@/contrib/basys3/create_project.sh" ] \
	    || { echo "error: $@ has no contrib/basys3/create_project.sh yet" >&2; exit 1; }; \
	  cd /tmp && "$(REPO_ROOT)$@/contrib/basys3/create_project.sh"; \
	fi

# prefix/glob match against the complete directory names
%:
	@dirs=$$(for m in $(MACHINES); do case "$$m" in "$@"*) echo "$$m";; esac; done); \
	 if [ $$(printf '%s\n' $$dirs | grep -c .) -ne 1 ]; then \
	   echo "error: '$@' does not match exactly one machine directory" >&2; \
	   echo "machines: $(MACHINES)" >&2; exit 1; \
	 fi; \
	 set -- $$dirs; \
	 if [ -n "$(DISTCLEAN)" ]; then \
	   [ -f "$(REPO_ROOT)$$1/Makefile" ] \
	     || { echo "error: $$1 has no Makefile with a distclean target" >&2; exit 1; }; \
	   $(MAKE) --no-print-directory -C "$(REPO_ROOT)$$1" distclean; \
	 else \
	   [ -x "$(REPO_ROOT)$$1/contrib/basys3/create_project.sh" ] \
	     || { echo "error: $(REPO_ROOT)$$1 has no contrib/basys3/create_project.sh yet" >&2; exit 1; }; \
	   cd /tmp && "$(REPO_ROOT)$$1/contrib/basys3/create_project.sh"; \
	 fi
