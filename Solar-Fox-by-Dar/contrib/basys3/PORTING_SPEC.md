# Solar-Fox-by-Dar — Porting spec

## 1. Reference model

- Source archive: `vhdl_solar_fox_rev_0_1_2019_11_22.zip` (SourceForge folder `Solarfox`, per
  the repo-root `downloads.md`) → `vhdl_solar_fox_rev_0_1_2019_11_22/` at the machine root.
- Top entity: `solar_fox_basys3` (target file `sources_1/new/solar_fox_basys3.vhd`).
- Part: `xc7a35tcpg236-1`, VHDL target language.
- Status: **not yet fully brought up** — `contrib/basys3/vivado/create_project.sh` is real and
  machine-specific, but the `.xdc`/`.xpr`/top-level wrapper it stages don't exist yet (root
  `README.md` Status section). This spec records the porting decisions already fixed by the
  machine `README.md`; sections below are design intent for the not-yet-authored top level,
  not a description of an existing build.

## 2. Clocking

- Single core clock: **40 MHz**, derived from the 100 MHz Basys 3 oscillator by `clk_wiz_0`.
- Solved MMCM (per machine `README.md`): `DIVCLK_DIVIDE=1`, `CLKFBOUT_MULT_F=10.0`,
  `CLKOUT0_DIVIDE_F=25.0`. Reset active-high (`btnC`), `locked` used.

## 3. Reset polarity

- **Basys 3:** `reset <= btnC or not mmcm_locked;` (Berzerk/Bagman/Pooyan pattern), planned.

## 4. Video (31 kHz VGA / 15 kHz TV)

- No external scandoubler: the core doubles scanlines internally. Mode toggled by keyboard
  **F8** (31 kHz VGA / 15 kHz TV), not a Basys 3 switch — same keyboard-only convention as
  Kick/Sky-skipper.

## 5. Audio (stereo L/R PWM, mono out on PmodAMP2)

- The core carries a stereo L/R PWM path; only the left channel drives PmodAMP2 `O_PMODAMP2_AIN`
  (mono out) — same convention as Kick. Keyboard **F5** toggles separate/stereo audio mode;
  **F7** toggles service mode. `sw(15)`/`sw(14)` → AMP gain/shutdown (standard convention).

## 6. Inputs

- PS/2 keyboard + `kbd_joystick`, OR-merged with the JA joystick (active-low, invert to
  active-high, "verified working" per machine `README.md`): `JA1=Right, JA2=Left, JA3=Down,
  JA4=Up, JA7=Fire`.
- Coin = JA fire+up combo (OR keyboard F1); Fast = JA fire+left combo (OR keyboard F2).
- `btnU`/`btnL`/`btnR`/`btnD` declared but unused/reserved (per machine `README.md` IO table).

## 7. LEDs

- `led(15:0)` present (per machine `README.md` IO table) — unlike Bagman/Berzerk/Pooyan/
  Time-Pilot, this port does wire LEDs; exact source signal to be confirmed against the core
  when the top level is authored.

## 8. Shared conventions & hard rules

- **Non-nested project layout**: the `.xpr` will live directly in `basys3/` as
  `basys3/solar_fox_basys3.xpr`, with the sources tree at `basys3/solar_fox_basys3.srcs/`.
- **Vivado build scripts run from `/tmp`** so `vivado.log`/`vivado.jou` stay out of the repo.
- **Tool/path resolution** is `ENV_VAR → project default → interactive prompt`:
  - Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
  - roms: `ROMZIP` → `~/roms/`
- **Roms and generated PROM VHDL are copyrighted content** — never commit or distribute them.
- Note: the color PROM `82s123.12d` is shared with Kick's romset (per machine `README.md`
  §"ROM set required").

## 9. Open items

- `.xdc`/`.xpr` (contrib/basys3/vivado/), `make_clk_wiz_0.sh`, the top-level wrapper
  (`make_de10_lite_to_basys3_patch.sh`), and the synth/bitstream driver script all remain to be
  authored before `make create_prj`/`clk_wiz`/`patch`/`synth`/`bitstream` can run.
