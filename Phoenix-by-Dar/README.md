# Phoenix-by-Dar (Basys 3 port)

Phoenix (Amstar, 1980) by Dar (`darfpga@aol.fr`, http://darfpga.blogspot.fr).
Basys 3 (Artix-7) port by Red~Bote. See `README.txt` in the extracted source
archive for the original Dar release notes.

- Vivado 2020.2 project: `basys3/phoenix_basys3.xpr` (top entity
  `phoenix_basys3`)
- Core clock: 11 MHz (pixel clock 5.5 MHz internally); audio effect/music
  blocks run on 50 MHz (from the 100 MHz Basys 3 oscillator via `clk_wiz_0`)
- `clk_wiz_0` Clocking Wizard (MMCM, 100 MHz in): `clk_out1` = 11.000 MHz +
  `clk_out2` = 50.000 MHz; reset active-high (btnC), `locked` used. Solved
  MMCM: `DIVCLK_DIVIDE=1`, `CLKFBOUT_MULT_F=11.000`, `CLKOUT0_DIVIDE_F=100.000`,
  `CLKOUT1_DIVIDE=22`.

## Features supported

- **Video**: 31 kHz progressive VGA via an imported MiST scandoubler
  (`imports/mist/scandoubler.v`) fed by a duration-threshold composite-sync
  separator authored in the wrapper (the pristine core exposes only
  composite sync, no native hsync/vsync). sw(13) switches to 15 kHz TV mode
  (native RGB + composite sync on HS, reproducing the pristine DE10-lite
  top's own output path). See `contrib/basys3/PORTING_SPEC.md` for the full
  design record — **the sync separator is unverified until hardware
  bring-up**.
- **Scan doubler source**: downloaded the first build from
  https://raw.githubusercontent.com/DECAfpga/Arcade_Galaga/main/mist/scandoubler.v
  and stashed in `dloads/`; the stashed copy is reused for subsequent builds.
- **Sound**: mono PWM audio on PmodAMP2; `audio_select` (3-bit, sw(10:8))
  selects effect1/effect2/effect3/melody solo or the default mix.
- **Controls**: PS/2 keyboard (native, handled entirely inside the core) +
  JA joystick/dedicated buttons (via `contrib/code/phoenix_expose_control_ports.patch`,
  which adds external control ports to the pristine core — **unverified
  until hardware bring-up**, see PORTING_SPEC.md); btnU = coin-in, btnL/btnR
  = start 1/2, btnC = reset.

| Input | Keyboard |
|-------|----------|
| Move (right/left) | Arrow keys |
| Shield | Up arrow |
| Fire | Space |
| Coin | F3 |
| Start 1 | F1 |
| Start 2 | F2 |

JA joystick (active-low, switch to GND):
- JA1 = Right, JA2 = Left, JA4 = Up/shield, JA7 = Fire
- JA3 (down) is present on the connector but unused — the game has no down
  input.

Buttons (active-high):
- btnU = coin-in, btnL = start 1, btnR = start 2, btnC = reset

## IO mapping

| Basys 3 resource | Wrapper port | Function |
|------------------|--------------|----------|
| clk (W5, 100 MHz) | `clk` | clock into `clk_wiz_0` MMCM |
| btnU | `btnU` | coin-in |
| btnL / btnR | `btnL` / `btnR` | start 1 / start 2 |
| btnC | `btnC` | reset (active-high) |
| sw(7:0) | `sw(7 downto 0)` | dip switches (lives, bonus life, coin mode, upright/cocktail) |
| sw(10:8) | `sw(10 downto 8)` | `audio_select`: solo effect1/2/3/melody or mixed |
| sw(15) | `O_PMODAMP2_GAIN` | AMP gain: 0 = 12 dB, 1 = 6 dB |
| sw(14) | `O_PMODAMP2_SHUTD` | AMP shutdown/enable: 0 = off, 1 = on |
| sw(13) | `sw(13)` | display mode: 0 = VGA, 1 = 15 kHz TV |
| JB1 / JB3 | `ps2_dat` / `ps2_clk` | PS/2 keyboard |
| JA1, JA2, JA4, JA7 | `JA(0)`, `JA(1)`, `JA(3)`, `JA(4)` | right, left, up/shield, fire (active-low); JA3/`JA(2)` unused |
| JC (PmodAMP2) | `O_PMODAMP2_AIN` | PWM audio (JC1=AIN, JC2=GAIN, JC4=SHUTD) |
| VGA | `vgaRed/vgaGreen/vgaBlue(3:0)`, `vgaHsync`, `vgaVsync` | 4-4-4 RGB, 31 kHz VGA / 15 kHz TV |

## Scripted setup

`contrib/tools/setup_phoenix.sh` automates the manual steps below: it
fetches the Dar archive into the gitignored `dloads/` cache (reused when its
SHA-256 matches the hash embedded in the script; re-downloaded when missing
or tampered), extracts it as `vhdl_phoenix_DE10_lite/` (the archive has no
internal top-level folder, unlike every other machine's), applies
`contrib/code/phoenix_expose_control_ports.patch`, then runs
`contrib/tools/prep_roms.sh` to compile `make_vhdl_prom`, run the
reconstructed `make_phoenix_proms.sh` (the upstream archive ships no
`.bat`/`tools_prom_src`), stage the romset from `$ROMZIP` (default
`~/roms/phoenix.zip`), and generate the PROM VHDL. Run it via `make setup`.
The MiST `scandoubler.v` (see Features above) is likewise fetched on first
build and stashed in `dloads/` for reuse.

## ROM set required

MAME ROM set `phoenix.zip`, unzipped into `tools/phoenix_unzip/`:

```
~/roms/phoenix.zip   ->   tools/phoenix_unzip/
```

Then run `./make_phoenix_proms.sh` from that directory to generate the PROM
VHDL (`phoenix_prog.vhd`, `prom_ic39.vhd`, `prom_ic40.vhd`, `prom_ic23.vhd`,
`prom_ic24.vhd`, `prom_palette_ic40.vhd`, `prom_palette_ic41.vhd`). The
Vivado project references these generated files in place, so the build
needs only the staged ROMs + the script.

machine ROMs are copyrighted — never commit or redistribute them.

## Fix patches

### `phoenix_expose_control_ports.patch`

Adds `ext_coin`/`ext_start1`/`ext_start2`/`ext_fire`/`ext_right`/`ext_left`/
`ext_up` ports to the pristine `phoenix` entity (`rtl_dar/phoenix.vhd`),
OR-merged with the existing PS/2-keyboard-derived controls — the pristine
entity otherwise has no ports at all for a JA joystick or dedicated buttons.
Verify it took:

```
grep -c ext_coin vhdl_phoenix_DE10_lite/rtl_dar/phoenix.vhd   # expect 2 (port decl + OR-merge)
```

## Known issues

- Not yet hardware-verified. Two parts of this port have no Dar reference to
  validate against and are unverified until bring-up: the composite-sync
  separator (video) and the external-control-port patch (inputs). See
  `contrib/basys3/PORTING_SPEC.md` for both designs and their fallback plans.

## Build status

Fully scripted, synthesized, and bitstream-built: `make setup create_prj
clk_wiz patch synth bitstream` all complete with 0 critical warnings and 0
errors through implementation (placement WNS positive, 0 failed routing
nets). Hardware bring-up has not been done.
