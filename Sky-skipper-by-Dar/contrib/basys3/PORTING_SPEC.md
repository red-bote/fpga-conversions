# Sky-skipper-by-Dar — Porting spec

## 1. Reference model

- Source archive: `vhdl_sky_skipper_rev_01_2020_01_28.zip` (SourceForge folder `sky_skipper`,
  per the repo-root `downloads.md`) → `vhdl_sky_skipper_rev_01_2020_01_28/` at the machine root.
- Top entity: `sky_skipper_basys3` (target file `sources_1/new/sky_skipper_basys3.vhd`).
- Part: `xc7a35tcpg236-1`, VHDL target language.
- Status: **not yet fully brought up** — `contrib/basys3/vivado/create_project.sh` is real and
  machine-specific, but the `.xdc`/`.xpr`/top-level wrapper it stages don't exist yet (root
  `README.md` Status section). This spec records the porting decisions already fixed by the
  machine `README.md`; sections below are design intent for the not-yet-authored top level,
  not a description of an existing build.
- Directory naming note: this machine's directory is `Sky-skipper-by-Dar` (lowercase `s`), not
  `Sky-Skipper-by-Dar` — see root `README.md`'s directory-naming bullet.

## 2. Clocking

- Single core clock: **40 MHz**, derived from the 100 MHz Basys 3 oscillator by `clk_wiz_0`.
- Solved MMCM (per machine `README.md`): `DIVCLK_DIVIDE=1`, `CLKFBOUT_MULT_F=10.0`,
  `CLKOUT0_DIVIDE_F=25.0`. Reset active-high (`btnC`), `locked` used.

## 3. Reset polarity

- **Basys 3:** `reset <= btnC or not mmcm_locked;` (Berzerk/Bagman/Pooyan pattern), planned.

## 4. Video (31 kHz VGA / 15 kHz TV)

- No external scandoubler: the core doubles scanlines internally. Mode toggled by keyboard
  **F8** (31 kHz VGA / 15 kHz TV), not a Basys 3 switch — same keyboard-only convention as
  Kick/Solar-Fox.

## 5. Audio (mono PWM on PmodAMP2)

- Mono PWM accumulator pattern (Berzerk/Burnin'-Rubber convention); `sw(15)` → AMP gain,
  `sw(14)` → AMP shutdown.

## 6. Inputs

- PS/2 keyboard + `kbd_joystick`, OR-merged with the JA joystick (active-low, invert to
  active-high): `JA1=Right, JA2=Left, JA3=Down, JA4=Up, JA7=Fire` (JA7 drives both the core's
  Fire A and Fire B inputs; the keyboard exposes them separately as Space/F).
- Coin = JA fire+up combo (OR keyboard F1=Coin1, F2=Coin2); Start = JA fire+left combo (OR
  keyboard F3=Start1, F4=Start2); Service = keyboard F7.
- No `btnU`/`btnL`/`btnR`/`btnD` reservation documented (unlike Kick/Solar-Fox) — to confirm
  against the pristine core when the top level is authored.

## 7. LEDs

- `led(15:0)` present (per machine `README.md` IO table) — unlike Bagman/Berzerk/Pooyan/
  Time-Pilot, this port does wire LEDs; exact source signal to be confirmed against the core
  when the top level is authored.

## 8. Shared conventions & hard rules

- **Non-nested project layout**: the `.xpr` will live directly in `basys3/` as
  `basys3/sky_skipper_basys3.xpr`, with the sources tree at `basys3/sky_skipper_basys3.srcs/`.
- **Vivado build scripts run from `/tmp`** so `vivado.log`/`vivado.jou` stay out of the repo.
- **Tool/path resolution** is `ENV_VAR → project default → interactive prompt`:
  - Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
  - roms: `ROMZIP` → `~/roms/`
- **Roms and generated PROM VHDL are copyrighted content** — never commit or distribute them.

## 9. Open items

- `.xdc`/`.xpr` (contrib/basys3/vivado/), `make_clk_wiz_0.sh`, the top-level wrapper
  (`make_de10_lite_to_basys3_patch.sh`), and the synth/bitstream driver script all remain to be
  authored before `make create_prj`/`clk_wiz`/`patch`/`synth`/`bitstream` can run.
