# Default target: build the whole scripted Basys3 port tree.
TOOLS        := contrib/tools
BASYS3_TOOLS := contrib/basys3/tools
VIVADO       := contrib/basys3/vivado

# External IO summary (printed by `make help`) and display-mode switching input
# (printed by `make help` and at the end of `make all`/`make bitstream`).
IO_SUMMARY   := PS/2 keyboard (JB, only input -- JA joystick/buttons tried and reverted, see PORTING_SPEC.md); btnC=reset; dip switches sw(7:0), audio_select sw(10:8); JC PmodAMP2 PWM audio; sw(14)=sound enable, sw(15)=AMP gain, sw(13)=display mode; VGA 4-4-4 RGB
DISPLAY_HINT := sw(13): 0 = 31 kHz VGA, 1 = 15 kHz TV

DISPLAY_REMINDER := @echo "REMINDER: if nothing appears on the display, first try toggling the display mode: $(DISPLAY_HINT)."

define display_reminder
	$(if $(DISPLAY_HINT),$(DISPLAY_REMINDER))
endef

.PHONY: all setup create_prj clk_wiz patch synth bitstream clean help

all: setup clk_wiz patch
	$(display_reminder)

setup:
	$(TOOLS)/setup_phoenix.sh

create_prj:
	$(VIVADO)/create_project.sh

clk_wiz: setup create_prj
	$(VIVADO)/make_clk_wiz_0.sh

# Regenerate phoenix_de10_lite_to_basys3.patch and phoenix_basys3.vhd top level.
patch: setup
	$(BASYS3_TOOLS)/make_de10_lite_to_basys3_patch.sh

# Run synthesis only (resets synth_1 first).
synth: setup clk_wiz patch
	$(BASYS3_TOOLS)/make_phoenix_basys3_bitstream.sh synth

# Implementation + write_bitstream (depends on synthesis).
bitstream: synth
	$(BASYS3_TOOLS)/make_phoenix_basys3_bitstream.sh bitstream
	$(display_reminder)

clean:
	rm -rf vhdl_phoenix_DE10_lite

help:
	@echo "Phoenix Basys 3 port. External IO used: $(IO_SUMMARY)"
	@echo "Steps: setup create_prj clk_wiz patch synth bitstream all clean (default: all)"
	$(display_reminder)
