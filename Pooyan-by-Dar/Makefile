# Pooyan-by-Dar Makefile.
#   make            build the Basys 3 port (default target)
#   make build      same as above
#   make setup-roms stage the romset + generate the PROM VHDL (no Vivado)
#   make clean      remove Vivado build outputs, keep the project sources
#   make distclean  restore to just the repo-tracked files (README.md,
#                   readme-dar.txt, pooyan_t80_xor_width.patch, contrib/)
#
# The build delegates to contrib/basys3/create_project.sh (single authority
# for the port). distclean delegates to contrib/basys3/clean_project.sh
# (single authority for what is generated vs. repo content).

MAKEFILE_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/
REV_DIR      := vhdl_pooyan_rev_0_2_2020_04_26
PROJ_DIR     := $(MAKEFILE_DIR)$(REV_DIR)/basys3/pooyan_basys3

.PHONY: build clean distclean setup-roms

# Default target: build the Basys 3 port (create_project.sh). Run from /tmp
# so vivado.log / vivado.jou land outside the repo (AGENTS.md convention).
build:
	@cd /tmp && bash "$(MAKEFILE_DIR)contrib/basys3/create_project.sh"

clean:
	@if [ -d "$(PROJ_DIR)" ]; then \
	  rm -rf "$(PROJ_DIR)/pooyan_basys3.runs" \
	         "$(PROJ_DIR)/pooyan_basys3.cache" \
	         "$(PROJ_DIR)/pooyan_basys3.gen" \
	         "$(PROJ_DIR)/pooyan_basys3.hw" \
	         "$(PROJ_DIR)/pooyan_basys3.sim" \
	         "$(PROJ_DIR)/pooyan_basys3.ip_user_files"; \
	  find "$(PROJ_DIR)" \( -name '*.jou' -o -name '*.log' -o -name '*.wdb' -o -name '*.str' \) -delete; \
	  echo "cleaned: $(PROJ_DIR) build tree"; \
	else \
	  echo "clean: no project dir yet ($(PROJ_DIR))"; \
	fi
	@rm -f "$(MAKEFILE_DIR)vivado.log" "$(MAKEFILE_DIR)vivado.jou"

distclean:
	@bash "$(MAKEFILE_DIR)contrib/basys3/clean_project.sh"

# Stage the MAME romset into tools/pooyan_unzip/ and generate the PROM VHDL
# in place (create_project.sh --stage-roms; no Vivado needed). Idempotent:
# skips when all PROM VHDL are already present.
setup-roms:
	@bash "$(MAKEFILE_DIR)contrib/basys3/create_project.sh" --stage-roms
