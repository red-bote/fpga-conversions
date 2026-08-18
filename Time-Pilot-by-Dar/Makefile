# Default target: build the whole scripted Basys3 port tree.
TOOLS  := contrib/tools
VIVADO := contrib/basys3/vivado

.PHONY: all setup clk_wiz patch synth bitstream clean

all: setup clk_wiz patch

setup:
	$(TOOLS)/setup_time_pilot.sh

create_prj:
	$(VIVADO)/create_project.sh

clk_wiz: setup create_prj
	$(VIVADO)/make_clk_wiz_0.sh

# Regenerate time_pilot_de10_lite_to_basys3.patch and time_pilot_basys3.vhd top level.
patch: setup
	$(TOOLS)/make_de10_lite_to_basys3_patch.sh

# Run synthesis only (resets synth_1 first).
synth: setup clk_wiz patch
	$(TOOLS)/make_time_pilot_basys3_bitstream.sh synth

# Implementation + write_bitstream (depends on synthesis).
bitstream: synth
	$(TOOLS)/make_time_pilot_basys3_bitstream.sh bitstream

clean:
	rm -rf vhdl_time_pilot_rev_0_0_2017_11_05
