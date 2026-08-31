# Defender-by-Dar (Basys 3 port)

Defender (Williams, 1981) by Dar (`darfpga@aol.fr`,
http://darfpga.blogspot.fr). Basys 3 (Artix-7) port by Red~Bote. See
`README.txt` in the extracted source archive for the original Dar release
notes.

- Vivado 2020.2 project: `basys3/defender_basys3.xpr` (top entity
  `defender_basys3`)
- Core clock: 12 MHz; sound-board clock: ~3.58 MHz (from the 100 MHz Basys 3
  oscillator via `clk_wiz_0`)
- `clk_wiz_0` Clocking Wizard (MMCM, 100 MHz in): `clk_out1` = 12.000 MHz
  (core + scandoubler `clk_sys`) + `clk_out2` ≈ 7.16 MHz, **divided by 2 in
  fabric** to ~3.58 MHz for the sound board and for the PWM audio accumulator.
  An exact 3.58 MHz is unreachable from the MMCM directly (VCO floor ~600 MHz
  vs max output divide 128), and the sample-based D/A sound logic tolerates the
  few-% error.

## Features supported

- **Video**: 31 kHz progressive VGA via an imported MiST scandoubler
  (`imports/mist/scandoubler.v`, tracked under `contrib/code/scandoubler.v`).
  The scandoubler's 6 MHz `ce_x1` (Defender's native pixel rate) is produced in
  fabric as `clk_out1 / 2`. sw(13) switches to 15 kHz TV mode (native RGB +
  composite sync on HS).
- **Scan doubler wiring**: see `contrib/basys3/PORTING_SPEC.md` (same core
  family wiring as Burnin-Rubber / BurgerTime).
- **Sound**: mono PWM audio on PmodAMP2 (8-bit core `audio_out`).
- **Controls**: PS/2 keyboard + JA joystick (OR-merged) for move/fire; buttons
  btnU = coin-in, btnL/btnR = start 1/2, btnC = reset. **No fire+direction
  combos** for coin/start (root `PORTING_SPEC.md` policy). Smart bomb,
  hyperspace and service stay keyboard-only (the 5-pin JA header can't carry
  the full Defender button set).

| Input | Keyboard |
|-------|----------|
| Up / Down | Up / Down arrows |
| Thrust | Right arrow |
| Reverse ship | Left arrow |
| Fire | Space |
| Smart bomb | Ctrl |
| Hyperspace | W |
| Coin | F3 |
| Start 1 | F1 |
| Start 2 | F2 |
| Service: advance / auto-up / high-score reset | A / U / H |

JA joystick (active-low, switch to GND):
- JA1 = Thrust (right), JA2 = Reverse (left), JA3 = Down, JA4 = Up, JA7 = Fire

Buttons (active-high):
- btnU = coin-in, btnL = start 1, btnR = start 2, btnC = reset

Coin/start come only from the keyboard (F3/F1/F2) or the dedicated buttons
(btnU/btnL/btnR) — no joystick fire+direction combos.

## IO mapping

| Basys 3 resource | Wrapper port | Function |
|------------------|--------------|----------|
| clk (W5, 100 MHz) | `clk` | clock into `clk_wiz_0` MMCM |
| btnC | `btnC` | reset (active-high) |
| btnU | `btnU` | coin-in, OR-merged with keyboard F3 |
| btnL / btnR | `btnL` / `btnR` | start 1 / start 2, OR-merged with F1 / F2 |
| sw(15) | `O_PMODAMP2_GAIN` | AMP gain: 0 = 12 dB, 1 = 6 dB |
| sw(14) | `O_PMODAMP2_SHUTD` | AMP shutdown: 0 = off, 1 = on |
| sw(13) | `sw(13)` | display mode: 0 = VGA, 1 = 15 kHz TV |
| JB1 / JB3 | `ps2_dat` / `ps2_clk` | PS/2 keyboard |
| JA1-JA4, JA7 | `JA(0..4)` | joystick (active-low) |
| JC (PmodAMP2) | `O_PMODAMP2_AIN` | PWM audio (JC1=AIN, JC2=GAIN, JC4=SHUTD) |
| VGA | `vgaRed/vgaGreen/vgaBlue(3:0)`, `vgaHsync`, `vgaVsync` | 4-4-4 RGB, 31 kHz VGA / 15 kHz TV |

## Scripted setup

`contrib/tools/setup_defender.sh` automates the manual steps below: it fetches
the Dar archive into the gitignored `dloads/` cache (reused when its SHA-256
matches the hash embedded in the script; re-downloaded when missing or
tampered), extracts it as `vhdl_defender_rev_0_0_2017_10_15/`, then runs
`contrib/tools/prep_roms.sh` to compile `make_vhdl_prom`, convert
`make_defender_proms.bat`, stage the romset from `$ROMZIP` (default
`~/roms/defender.zip`) and generate the PROM VHDL. Run it via `make setup`.
Note: the source archive was already downloaded and extracted in this repo; the
setup script uses the cached copy in `dloads/`.

## ROM set required

MAME ROM set `defender.zip`, unzipped into `tools/defender_unzip/`:

```
~/roms/defender.zip   ->   tools/defender_unzip/
```

Then run `./make_defender_proms.sh` from that directory to generate the PROM
VHDL (`defender_prog.vhd`, `defender_decoder_2.vhd`, `defender_decoder_3.vhd`,
`defender_sound.vhd`). The Vivado project references these generated files in
place, so the build needs only the staged ROMs + the script.

The `.bat` concatenates 11 program ROMs into `defender_prog.bin`; the Linux
conversion turns that `copy /B a + b + ...` into `cat a b ...`.

machine ROMs are copyrighted — never commit or redistribute them.

## Build status

The port is fully scripted (`make setup create_prj clk_wiz patch`; `make
synth` / `make bitstream` for a Vivado run). Port assets are authored end to
end from the BurgerTime/Burnin-Rubber reference (same scandoubler core-family
wiring), with Defender-specific clock/input/audio handling. Hardware bring-up
(Vivado synthesis/bitstream) has not yet been run.
