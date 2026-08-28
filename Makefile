# Top-level Makefile: delegate to each machine's own Makefile.
#
# Every machine under <Machine>-by-Dar/ owns a Makefile that is the
# authoritative driver for that machine's Basys3 port. This file only forwards
# to it, so a step is invoked as:
#
#     make <step>-<machine>
#
# e.g.  make setup-galaga          make synth-time-pilot
#       make create-prj-galaga     make bitstream-pooyan
#
# Available steps vary per machine (create_prj is not universal — Pooyan lacks
# it). Use `make help` to list what each machine supports.

GALAGA      := Galaga-Midway-by-Dar
POOYAN      := Pooyan-by-Dar
TIME_PILOT  := Time-Pilot-by-Dar
BAGMAN      := Bagman-FPGA-Dar
BERZERK     := Berzerk-FPGA-by-Dar
TRON        := Tron-by-Dar

# Bare `make` prints help instead of running a build.
.DEFAULT_GOAL := help

# ---- Galaga ----
setup-galaga:
	$(MAKE) -C "$(GALAGA)" setup

create-prj-galaga:
	$(MAKE) -C "$(GALAGA)" create_prj

clk-wiz-galaga:
	$(MAKE) -C "$(GALAGA)" clk_wiz

patch-galaga:
	$(MAKE) -C "$(GALAGA)" patch

synth-galaga:
	$(MAKE) -C "$(GALAGA)" synth

bitstream-galaga:
	$(MAKE) -C "$(GALAGA)" bitstream

all-galaga:
	$(MAKE) -C "$(GALAGA)" all

clean-galaga:
	$(MAKE) -C "$(GALAGA)" clean

# ---- Pooyan ----
setup-pooyan:
	$(MAKE) -C "$(POOYAN)" setup

clk-wiz-pooyan:
	$(MAKE) -C "$(POOYAN)" clk_wiz

patch-pooyan:
	$(MAKE) -C "$(POOYAN)" patch

synth-pooyan:
	$(MAKE) -C "$(POOYAN)" synth

bitstream-pooyan:
	$(MAKE) -C "$(POOYAN)" bitstream

all-pooyan:
	$(MAKE) -C "$(POOYAN)" all

clean-pooyan:
	$(MAKE) -C "$(POOYAN)" clean

# ---- Time-Pilot ----
setup-time-pilot:
	$(MAKE) -C "$(TIME_PILOT)" setup

create-prj-time-pilot:
	$(MAKE) -C "$(TIME_PILOT)" create_prj

clk-wiz-time-pilot:
	$(MAKE) -C "$(TIME_PILOT)" clk_wiz

patch-time-pilot:
	$(MAKE) -C "$(TIME_PILOT)" patch

synth-time-pilot:
	$(MAKE) -C "$(TIME_PILOT)" synth

bitstream-time-pilot:
	$(MAKE) -C "$(TIME_PILOT)" bitstream

all-time-pilot:
	$(MAKE) -C "$(TIME_PILOT)" all

clean-time-pilot:
	$(MAKE) -C "$(TIME_PILOT)" clean

# ---- Bagman ----
setup-bagman:
	$(MAKE) -C "$(BAGMAN)" setup

create-prj-bagman:
	$(MAKE) -C "$(BAGMAN)" create_prj

clk-wiz-bagman:
	$(MAKE) -C "$(BAGMAN)" clk_wiz

patch-bagman:
	$(MAKE) -C "$(BAGMAN)" patch

synth-bagman:
	$(MAKE) -C "$(BAGMAN)" synth

bitstream-bagman:
	$(MAKE) -C "$(BAGMAN)" bitstream

all-bagman:
	$(MAKE) -C "$(BAGMAN)" all

clean-bagman:
	$(MAKE) -C "$(BAGMAN)" clean

.PHONY: help setup-galaga create-prj-galaga clk-wiz-galaga patch-galaga \
        synth-galaga bitstream-galaga all-galaga clean-galaga \
        setup-pooyan clk-wiz-pooyan patch-pooyan synth-pooyan \
        bitstream-pooyan all-pooyan clean-pooyan \
        setup-time-pilot create-prj-time-pilot clk-wiz-time-pilot \
        patch-time-pilot synth-time-pilot bitstream-time-pilot \
        all-time-pilot clean-time-pilot \
        setup-bagman create-prj-bagman clk-wiz-bagman patch-bagman \
        synth-bagman bitstream-bagman all-bagman clean-bagman \
        setup-berzerk create-prj-berzerk clk-wiz-berzerk patch-berzerk \
        synth-berzerk bitstream-berzerk all-berzerk clean-berzerk \
        setup-tron create-prj-tron clk-wiz-tron patch-tron \
        synth-tron bitstream-tron all-tron clean-tron

# ---- Berzerk ----
setup-berzerk:
	$(MAKE) -C "$(BERZERK)" setup

create-prj-berzerk:
	$(MAKE) -C "$(BERZERK)" create_prj

clk-wiz-berzerk:
	$(MAKE) -C "$(BERZERK)" clk_wiz

patch-berzerk:
	$(MAKE) -C "$(BERZERK)" patch

synth-berzerk:
	$(MAKE) -C "$(BERZERK)" synth

bitstream-berzerk:
	$(MAKE) -C "$(BERZERK)" bitstream

all-berzerk:
	$(MAKE) -C "$(BERZERK)" all

clean-berzerk:
	$(MAKE) -C "$(BERZERK)" clean

# ---- Tron ----
setup-tron:
	$(MAKE) -C "$(TRON)" setup

create-prj-tron:
	$(MAKE) -C "$(TRON)" create_prj

clk-wiz-tron:
	$(MAKE) -C "$(TRON)" clk_wiz

patch-tron:
	$(MAKE) -C "$(TRON)" patch

synth-tron:
	$(MAKE) -C "$(TRON)" synth

bitstream-tron:
	$(MAKE) -C "$(TRON)" bitstream

all-tron:
	$(MAKE) -C "$(TRON)" all

clean-tron:
	$(MAKE) -C "$(TRON)" clean

help:
	@echo "Top-level port driver. Each step delegates to the machine's own Makefile."
	@echo "Usage: make <step>-<machine>"
	@echo
	@echo "Machines and their steps:"
	@echo "  Galaga      : setup create-prj clk-wiz patch synth bitstream all clean"
	@echo "  Pooyan      : setup          clk-wiz patch synth bitstream all clean"
	@echo "  Time-Pilot  : setup create-prj clk-wiz patch synth bitstream all clean"
	@echo "  Bagman      : setup create-prj clk-wiz patch synth bitstream all clean"
	@echo "  Berzerk     : setup create-prj clk-wiz patch synth bitstream all clean"
	@echo "  Tron        : setup create-prj clk-wiz patch synth bitstream all clean"
	@echo
	@echo "Examples:"
	@echo "  make setup-galaga      make synth-time-pilot      make bitstream-pooyan"