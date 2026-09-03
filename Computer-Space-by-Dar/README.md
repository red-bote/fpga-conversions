# Computer-Space-by-Dar (Basys 3 port)

Computer Space (Nutting Associates, 1971) by Dar (`darfpga@aol.fr`,
http://darfpga.blogspot.fr). Basys 3 (Artix-7) port built with Vivado 2020.2.
See `README.txt` in the extracted source archive for the original Dar release
notes.

- Vivado 2020.2 project: `basys3/computer_space_basys3.xpr` (top entity
  `computer_space_basys3`)
- Core clock: 6 MHz video pixel clock (`game_clk`), with a ~50 MHz
  `clock_50` for timers/noise/sound, from the 100 MHz oscillator via
  `clk_wiz_0`.
- `clk_wiz_0` MMCM: VCO forced to 600 so `clk_sys` = exactly 2x `game_clk`
  (`CLKFBOUT_MULT_F=6.0`, `CLKOUT0_DIVIDE_F=12`, `CLKOUT1_DIVIDE=100`,
  `CLKOUT2_DIVIDE=50` -> 50.000 / 6.000 / 12.000 MHz). The MiST scandoubler
  needs `clk_sys` = exactly 2x `ce_x1`; an auto VCO would otherwise give a
  non-exact ratio and a black screen.

## Features supported

- **Video**: 31 kHz progressive VGA via the imported scandoubler
  (`contrib/basys3/vga_scandoubler.v`). sw(13) switches to 15 kHz TV mode
  (native RGB + composite sync on HS). White-on-black monochrome picture.
- **Sound**: mono PWM audio on PmodAMP2.
- **Controls**: PS/2 keyboard + JA joystick (OR-merged); pushbuttons
  btnU/btnD/btnL/btnR double as start; btnC = reset.

| Input | Keyboard |
|-------|----------|
| Rotate CCW | Left arrow |
| Rotate CW | Right arrow |
| Thrust | Up arrow |
| Fire | Space |
| Start | F2 |

JA joystick (active-low, switch to GND; XDC `PULLUP true`):
- JA1 = Right/CW, JA2 = Left/CCW, JA4 = Up/Thrust, JA7 = Fire
- JA3 = spare (this core has no "down"/reverse input).

Pushbuttons (active-high, Basys3 board pull-down, same convention as btnC):
- btnU / btnD / btnL / btnR = start (F2); btnC = reset.

## IO mapping

| Basys 3 resource | Wrapper port | Function |
|------------------|--------------|----------|
| clk (W5, 100 MHz) | `clk` | clock into `clk_wiz_0` MMCM |
| btnC | `btnC` | reset (active-high) |
| btnU / btnD / btnL / btnR | `btnU` / `btnD` / `btnL` / `btnR` | start (F2) |
| sw(15) | `O_PMODAMP2_GAIN` | AMP gain: 0 = 12 dB, 1 = 6 dB |
| sw(14) | `O_PMODAMP2_SHUTD` | AMP shutdown: 0 = off, 1 = on |
| sw(13) | `sw(13)` | display mode: 0 = 31 kHz VGA, 1 = 15 kHz TV |
| JB1 / JB3 | `ps2_dat` / `ps2_clk` | PS/2 keyboard |
| JA1-JA4, JA7 | `JA(0..4)` | joystick (active-low) |
| JC (PmodAMP2) | `O_PMODAMP2_AIN` | PWM audio (mono; JC1=AIN, JC2=GAIN, JC4=SHUTD) |
| VGA | `vgaRed/vgaGreen/vgaBlue(3:0)`, `vgaHsync`, `vgaVsync` | 4-4-4 RGB, 31 kHz VGA / 15 kHz TV |

## Scripted setup

`make setup` archives/stages the Dar source and generates the six
`rom_*.vhd` sound-rom replacements from Intel-HEX (via
`contrib/tools/gen_sound_roms.py`; Computer Space is a discrete-game core, so
there are no MAME ROMs or PROM generation). Then `make create_prj`,
`make clk_wiz`, `make patch`, and `make synth` / `make bitstream`.

## Build status

See the root `sf-darfpga/README.md` Status section.

## Potential future work (note only)

- Real coin/credit start: the core keeps a coin-microswitch start state
  machine (`IDLE/COIN_INSERTED/GAME_ON` in `sync_star_board.vhd`), but the
  current wrapper drives `signal_start` directly (F2 or any pushbutton) and
  bypasses it. A dedicated coin button would require exposing `signal_coin`
  at the `computer_space_top` boundary (it is currently tied to `signal_start`
  internally).
- Diode-matrix input: not needed here (the core's input is a simple parallel
  `signal_*` bus). If a future port needs many controls over few Pmod pins, a
  scanned row x column matrix with steering diodes (to prevent ghosting) is
  the pattern; it is intentionally out of scope for this port.
