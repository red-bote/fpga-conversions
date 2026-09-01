# Default target: build the whole scripted Basys3 port tree.
TOOLS        := contrib/tools
BASYS3_TOOLS := contrib/basys3/tools
VIVADO       := contrib/basys3/vivado

.PHONY: all setup clk_wiz patch synth bitstream clean help

all: setup clk_wiz patch

setup:
	$(TOOLS)/setup_zaxxon.sh

create_prj:
	$(VIVADO)/create_project.sh

clk_wiz: setup create_prj
	$(VIVADO)/make_clk_wiz_0.sh

# Regenerate zaxxon_de10_lite_to_basys3.patch and zaxxon_basys3.vhd top level.
patch: setup
	$(BASYS3_TOOLS)/make_de10_lite_to_basys3_patch.sh

# Run synthesis only (resets synth_1 first).
synth: setup clk_wiz patch
	$(BASYS3_TOOLS)/make_zaxxon_basys3_bitstream.sh synth

# Implementation + write_bitstream (depends on synthesis).
bitstream: synth
	$(BASYS3_TOOLS)/make_zaxxon_basys3_bitstream.sh bitstream

clean:
	rm -rf vhdl_zaxxon_rev_0_0_2019_11_29

help:
	@echo "Zaxxon Basys3 port driver."
	@echo "Usage: make <target>"
	@echo
	@echo "  all         setup clk_wiz patch"
	@echo "  setup       fetch/extract Dar archive + rom-prep"
	@echo "  create_prj  create Vivado project (copies .xpr/.xdc, imports scandoubler)"
	@echo "  clk_wiz     generate clk_wiz_0 MMCM IP (24 + 48 MHz)"
	@echo "  patch       regenerate zaxxon_de10_lite_to_basys3.patch + top level"
	@echo "  synth       synthesis only (resets synth_1 first)"
	@echo "  bitstream   implementation + write_bitstream"
	@echo "  clean       remove the Vivado project/build tree only"
	@echo
	@echo "Display-mode reminder: if nothing appears on the display after loading"
	@echo "the bitstream, first try toggling the display mode (sw(13), or F8 on"
	@echo "the PS/2 keyboard) before troubleshooting further."