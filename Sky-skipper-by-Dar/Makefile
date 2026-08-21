# Default target: build the whole scripted Basys3 port tree.
TOOLS        := contrib/tools
BASYS3_TOOLS := contrib/basys3/tools
VIVADO       := contrib/basys3/vivado

.PHONY: all setup clk_wiz patch synth bitstream clean

all: setup clk_wiz patch

setup:
	$(TOOLS)/setup_sky_skipper.sh

create_prj:
	$(VIVADO)/create_project.sh

clk_wiz: setup create_prj
	$(VIVADO)/make_clk_wiz_0.sh

# Regenerate sky_skipper_de10_lite_to_basys3.patch and sky_skipper_basys3.vhd top level.
patch: setup
	$(BASYS3_TOOLS)/make_de10_lite_to_basys3_patch.sh

# Run synthesis only (resets synth_1 first).
synth: setup clk_wiz patch
	$(BASYS3_TOOLS)/make_sky_skipper_basys3_bitstream.sh synth

# Implementation + write_bitstream (depends on synthesis).
bitstream: synth
	$(BASYS3_TOOLS)/make_sky_skipper_basys3_bitstream.sh bitstream

clean:
	rm -rf vhdl_sky_skipper_rev_01_2020_01_28