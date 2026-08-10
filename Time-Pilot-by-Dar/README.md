# Time-Pilot-by-Dar (Basys 3 port)

Time Pilot (Konami, 1982) by Dar (`darfpga@aol.fr`,
http://darfpga.blogspot.fr). Basys 3 (Artix-7) port by Red~Bote. See
`readme-dar.txt` for the original Dar release notes.

- Vivado 2020.2 project: `basys3/time_pilot_basys3.xpr` (top entity
  `time_pilot_basys3`)
- Core clocks: 12.288 MHz (game core) + 14.318 MHz (sound) from the 100 MHz
  Basys 3 oscillator via `clk_wiz_0`
- `clk_wiz_0` Clocking Wizard (MMCM, 100 MHz in): `clk_out1` = 12.288 MHz +
  `clk_out2` = 14.318 MHz; reset active-high (btnC), `locked` used. Solved
  MMCM: `DIVCLK_DIVIDE=7`, `CLKFBOUT_MULT_F=56.125`, `CLKOUT0_DIVIDE_F=65.25`,
  `CLKOUT1_DIVIDE=56`.

## Features supported

- **Video**: 31 kHz progressive VGA via a DECA `vga_scandoubler` (same as
  Pooyan; from
  <https://github.com/DECAfpga/Arcade_Pooyan/blob/main/deca/vga_scandoubler.v>);
  `enable_scandoubling` and `disable_scaneffect` are both `1`.
- **Sound**: mono PWM audio on PmodAMP2.
- **Controls**: PS/2 keyboard + JA joystick (OR-merged), btnC = reset.

| Input | Keyboard |
|-------|----------|
| Move | Arrow keys |
| Fire | Space |
| Coin | F1 |
| Start 1 | F2 |
| Start 2 | F3 |

JA joystick (active-low, switch to GND):
- JA1 = Right, JA2 = Left, JA3 = Down, JA4 = Up, JA7 = Fire
- Coin = Fire + Up; Start 1 = Fire + Left; Start 2 = Fire + Right
- Player 2 mirrors player 1 movement/fire inputs.

## IO mapping

| Basys 3 resource | Wrapper port | Function |
|------------------|--------------|----------|
| clk (W5, 100 MHz) | `clk` | clock into `clk_wiz_0` MMCM |
| btnC | `btnC` | reset (active-high) |
| btnU/btnL/btnR/btnD | `btnU/L/R/D` | declared, unused (reserved) |
| sw(15) | `O_PMODAMP2_GAIN` | AMP gain: 0 = 12 dB, 1 = 6 dB |
| sw(14) | `O_PMODAMP2_SHUTD` | AMP shutdown: 0 = off, 1 = on |
| JB1 / JB3 | `ps2_dat` (JB(0)) / `ps2_clk` (JB(2)) | PS/2 keyboard |
| JA1-JA4, JA7 | `JA(0..4)` | joystick (active-low) |
| JC (PmodAMP2) | `O_PMODAMP2_AIN` | PWM audio |
| VGA | `vgaRed/vgaGreen/vgaBlue(3:0)`, `vgaHsync`, `vgaVsync` | 4-4-4 RGB, 31 kHz |
| LEDs | `led(15:0)` | present |

## ROM set required

MAME ROM set `timeplt.zip`, unzipped into `tools/time_pilot_unzip/`:

```
~/roms/timeplt.zip   ->   tools/time_pilot_unzip/
```

Then run `./make_time_pilot_proms.sh` from that directory to generate the PROM
VHDL (`time_pilot_prog.vhd`, `time_pilot_sound_prog.vhd`,
`time_pilot_char_grphx.vhd`, `time_pilot_sprite_grphx.vhd`,
`time_pilot_palette_blue_green.vhd`, `time_pilot_palette_green_red.vhd`,
`time_pilot_char_color_lut.vhd`, `time_pilot_sprite_color_lut.vhd`). The
Vivado project references these generated files in place, so the build needs
only the staged ROMs + the script.

Game ROMs are copyrighted — never commit or redistribute them.
