## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project
##
## Digilent Basys3 reference manual (c) Digilent Inc.
## See https://github.com/Digilent/Basys3
##
## Pin definitions extracted from the Digilent Basys3 master XDC,
## trimmed to the Pooyan port (see README.md):
##   clk       -> W5   (100 MHz)
##   sw(15)    -> PmodAMP2 GAIN (0 = 12 dB, 1 = 6 dB)
##   sw(14)    -> PmodAMP2 SHUTD (low = shutdown: sw14 down = mute, up = on)
##   btnC      -> reset (active high)
##   ps2_dat   -> JB1, ps2_clk -> JB3  (PULLUP, open-collector)
##   O_PMODAMP2_AIN    -> JC1
##   O_PMODAMP2_GAIN   -> JC2
##   O_PMODAMP2_SHUTD  -> JC4

set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switches
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
set_property PACKAGE_PIN V2 [get_ports {sw[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]
set_property PACKAGE_PIN T3 [get_ports {sw[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]
set_property PACKAGE_PIN T2 [get_ports {sw[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]
set_property PACKAGE_PIN R3 [get_ports {sw[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]
set_property PACKAGE_PIN W2 [get_ports {sw[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]
set_property PACKAGE_PIN U1 [get_ports {sw[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]
set_property PACKAGE_PIN T1 [get_ports {sw[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]
set_property PACKAGE_PIN R2 [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[15]}]

## Buttons
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## Pmod header JA (joystick, active-low switch to GND)
set_property PACKAGE_PIN J1 [get_ports JA[0]]
set_property IOSTANDARD LVCMOS33 [get_ports JA[0]]
set_property PACKAGE_PIN L2 [get_ports JA[1]]
set_property IOSTANDARD LVCMOS33 [get_ports JA[1]]
set_property PACKAGE_PIN J2 [get_ports JA[2]]
set_property IOSTANDARD LVCMOS33 [get_ports JA[2]]
set_property PACKAGE_PIN G2 [get_ports JA[3]]
set_property IOSTANDARD LVCMOS33 [get_ports JA[3]]
set_property PACKAGE_PIN H1 [get_ports JA[4]]
set_property IOSTANDARD LVCMOS33 [get_ports JA[4]]

## Pmod header JB (PS/2: JB1 = ps2_dat, JB3 = ps2_clk, open-collector)
set_property PACKAGE_PIN A14 [get_ports ps2_dat]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_dat]
set_property PULLUP true [get_ports ps2_dat]
set_property PACKAGE_PIN B15 [get_ports ps2_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_clk]
set_property PULLUP true [get_ports ps2_clk]

## Pmod header JC (PmodAMP2: JC1 = AIN, JC2 = GAIN, JC4 = SHUTD)
set_property PACKAGE_PIN K17 [get_ports O_PMODAMP2_AIN]
set_property IOSTANDARD LVCMOS33 [get_ports O_PMODAMP2_AIN]
set_property PACKAGE_PIN M18 [get_ports O_PMODAMP2_GAIN]
set_property IOSTANDARD LVCMOS33 [get_ports O_PMODAMP2_GAIN]
set_property PACKAGE_PIN P18 [get_ports O_PMODAMP2_SHUTD]
set_property IOSTANDARD LVCMOS33 [get_ports O_PMODAMP2_SHUTD]

## VGA connector
set_property PACKAGE_PIN G19 [get_ports {vgaRed[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[0]}]
set_property PACKAGE_PIN H19 [get_ports {vgaRed[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[1]}]
set_property PACKAGE_PIN J19 [get_ports {vgaRed[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[2]}]
set_property PACKAGE_PIN N19 [get_ports {vgaRed[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[3]}]
set_property PACKAGE_PIN J17 [get_ports {vgaGreen[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[0]}]
set_property PACKAGE_PIN H17 [get_ports {vgaGreen[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[1]}]
set_property PACKAGE_PIN G17 [get_ports {vgaGreen[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[2]}]
set_property PACKAGE_PIN D17 [get_ports {vgaGreen[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[3]}]
set_property PACKAGE_PIN N18 [get_ports {vgaBlue[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[0]}]
set_property PACKAGE_PIN L18 [get_ports {vgaBlue[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[1]}]
set_property PACKAGE_PIN K18 [get_ports {vgaBlue[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[2]}]
set_property PACKAGE_PIN J18 [get_ports {vgaBlue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[3]}]
set_property PACKAGE_PIN P19 [get_ports vgaHsync]
set_property IOSTANDARD LVCMOS33 [get_ports vgaHsync]
set_property PACKAGE_PIN R19 [get_ports vgaVsync]
set_property IOSTANDARD LVCMOS33 [get_ports vgaVsync]

## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## SPI configuration mode options for QSPI boot, can be used for all designs
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
