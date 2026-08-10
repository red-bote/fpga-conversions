# Berzerk-FPGA-by-Dar (Basys 3 port)

Berzerk (Stern, 1980) by Dar (`darfpga@aol.fr`, http://darfpga.blogspot.fr).
Basys 3 (Artix-7) port by Red~Bote. See `readme-dar.txt` for the original
Dar release notes.

- Vivado 2020.2 project: `berzerk_xc7/berzerk_xc7.xpr` (top entity `rtl_top`)
- Core clock: 10 MHz (from the 100 MHz Basys 3 oscillator via `clk_wiz_0`)

## Features supported

- **Video**: 31 kHz progressive VGA. Scan doubling is built into the core
  (`tv15Khz_mode = '0'` fixed — no 15 kHz TV mode on this port).
- **Sound**: mono PWM audio on PmodAMP2.
- **Controls**: PS/2 keyboard + JA joystick (OR-merged, verified working),
  btnC = reset.

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
| JB1 / JB3 | `ps2_dat` (JB(0)) / `ps2_clk` (JB(2)) | PS/2 keyboard |
| JA1-JA4, JA7 | `JA(0..4)` | joystick (active-low) |
| JC (PmodAMP2) | `O_PMODAMP2_AIN` | PWM audio |
| VGA | `vgaRed/vgaGreen/vgaBlue(3:0)`, `vgaHsync`, `vgaVsync` | 4-4-4 RGB, 31 kHz |
| LEDs | `led(15:0)` | present |

## ROM set required

MAME ROM set `berzerk.zip`, unzipped into `tools/berzerk_unzip/`:

```
~/roms/berzerk.zip   ->   tools/berzerk_unzip/
```

Then run `./make_berzerk_proms.sh` from that directory to generate the PROM VHDL
(`berzerk_program1/2.vhd`, `berzerk_speech_rom.vhd`). The Vivado project
references these generated files in place, so the build needs only the staged
ROMs + the script.

Game ROMs are copyrighted — never commit or redistribute them.

## Applying the reset-sensitivity fix

The pristine Dar core (`vhdl_berzerk_rev_0_1_2018_08_08/rtl_dar/berzerk.vhd`)
has a process whose sensitivity list omits `reset`. The one-line fix adds it:

```vhdl
process (clock_10, cpu_iorq_n, cpu_addr, reset)
```

`berzerk_reset_sensitivity.patch` in this directory applies that single line to
the unmodified Dar source. From the `Berzerk-FPGA-by-Dar/` directory (containing
`vhdl_berzerk_rev_0_1_2018_08_08/`):

```
patch -p1 < berzerk_reset_sensitivity.patch
```

Verify it took:

```
grep -n "cpu_iorq_n, cpu_addr, reset" vhdl_berzerk_rev_0_1_2018_08_08/rtl_dar/berzerk.vhd
```

