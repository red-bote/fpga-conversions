# Burnin-Rubber-by-Dar (Basys 3 port)

Burnin' Rubber (Data East, 1982) by Dar (`darfpga@aol.fr`,
http://darfpga.blogspot.fr). Basys 3 (Artix-7) port by Red~Bote. See
`readme-dar.txt` for the original Dar release notes.

- Vivado 2020.2 project: `basys3/burnin_rubber_basys3.xpr` (top entity
  `burnin_rubber_basys3`)
- Core clock: 12 MHz (from the 100 MHz Basys 3 oscillator via `clk_wiz_0`)
- `clk_wiz_0` Clocking Wizard (MMCM, 100 MHz in): `clk_out1` = 12.000 MHz +
  `clk_out2` = 6.000 MHz; reset active-high (btnC), `locked` used. Solved
  MMCM: `DIVCLK_DIVIDE=1`, `CLKFBOUT_MULT_F=7.5`, `CLKOUT0_DIVIDE_F=62.5`,
  `CLKOUT1_DIVIDE=125`.

## Features supported

- **Video**: 31 kHz progressive VGA via an imported MiST scandoubler
  (`imports/mist/scandoubler.v`). No 15 kHz TV mode on this port.
- **Sound**: mono PWM audio on PmodAMP2.
- **Controls**: PS/2 keyboard + JA joystick (OR-merged), btnC = reset.

| Input | Keyboard |
|-------|----------|
| Move | Arrow keys |
| Fire | Space |
| Coin | F3 |
| Start 1 | F1 |
| Start 2 | F2 |

JA joystick (active-low, switch to GND):
- JA1 = Right, JA2 = Left, JA3 = Down, JA4 = Up, JA7 = Fire
- Coin = Fire + Up together; Start 1 = Fire + Left together
- Player 2 mirrors player 1 inputs.

## IO mapping

| Basys 3 resource | Wrapper port | Function |
|------------------|--------------|----------|
| clk (W5, 100 MHz) | `clk` | clock into `clk_wiz_0` MMCM |
| btnC | `btnC` | reset (active-high) |
| btnU/btnL/btnR/btnD | `btnU/L/R/D` | declared, unused (reserved) |
| sw(15) | `O_PMODAMP2_GAIN` | AMP gain: 0 = 12 dB, 1 = 6 dB |
| sw(14) | `O_PMODAMP2_SHUTD` | AMP shutdown: 0 = off, 1 = on |
| JB1 / JB3 | `ps2_dat` / `ps2_clk` | PS/2 keyboard |
| JA1-JA4, JA7 | `JA(0..4)` | joystick (active-low) |
| JC (PmodAMP2) | `O_PMODAMP2_AIN` | PWM audio (JC1=AIN, JC2=GAIN, JC4=SHUTD) |
| VGA | `vgaRed/vgaGreen/vgaBlue(3:0)`, `vgaHsync`, `vgaVsync` | 4-4-4 RGB, 31 kHz |
| LEDs | `led(15:0)` | present |

## Known issues

- Bottommost horizontal scanline is not visible (would be on the left with a
  rotated monitor).

## ROM set required

MAME ROM set `brubber.zip`, unzipped into `tools/burnin_rubber_unzip/`:

```
~/roms/brubber.zip   ->   tools/burnin_rubber_unzip/
```

Then run `./make_burnin_rubber_proms.sh` from that directory to generate the
PROM VHDL (`burnin_rubber_prog.vhd`, `bg_graphx_1/2.vhd`,
`fg_sp_graphx_1/2/3.vhd`, `burnin_rubber_sound_prog.vhd`). The Vivado project
references these generated files in place, so the build needs only the staged
ROMs + the script.

Game ROMs are copyrighted — never commit or redistribute them.
