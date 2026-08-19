# Galaga DE10-lite → Basys3 porting spec

This spec summarizes the intended step-by-step process of porting Dar's Galaga hardware to the
Digilent Basys 3, mirroring the generic reference spec (`PORTING_SPEC.md`) and the Pooyan /
Time-Pilot per-machine specs.

Galaga has **not yet been scripted** (no Makefile, no `contrib/basys3/{tools,vivado}` scripts,
no extracted source tree checked in). The port lives only in a design `README.md` and the
tracked patch `contrib/code/galaga_credit_mode_fix.patch`. Parts of this spec are therefore the
**intended** procedure to be confirmed against the pristine Dar source tree
(`vhdl_galaga_rev_0_3_2018_05_06/`, fetched locally, not checked in). Items not yet verifiable
from the repo are marked **[unverified]**.

- Source archive: `vhdl_galaga_rev_0_3_2018_05_06.zip` (SourceForge folder `galaga`, per
  `~/tmp/downloads.md`) → `vhdl_galaga_rev_0_3_2018_05_06/` at the machine root.
- Top entity: `galaga_basys3` (target file `sources_1/new/galaga_basys3.vhd`)
- Part: `xc7a35tcpg236-1`, VHDL target language

## 1. Port list (DE10-lite → Basys3)

**[unverified]** — exact DE10-lite port names depend on the pristine `galaga_de10_lite.vhd`
(or equivalent) top, which is not in the repo. The Basys 3 wrapper should expose (per the IO
mapping in the machine README and `Basys-3-Master.xdc`):

| Basys 3 port | Function |
|---|---|
| `clk` (W5) | 100 MHz into `clk_wiz_0` MMCM |
| `btnC` | reset (active-high) |
| `btnU/L/R/D` | declared, unused (reserved) |
| `sw(15:0)` | see §6 (sound/gain) |
| `ps2_dat` / `ps2_clk` (JB1/JB3) | PS/2 keyboard |
| `JA(4:0)` (JA1-4, JA7) | joystick (active-low) |
| `O_PMODAMP2_AIN/GAIN/SHUTD` (JC1/2/4) | PWM audio (PmodAMP2) |
| `vga_r/g/b(3:0)`, `vga_hs`, `vga_vs` | 4-4-4 RGB, 31 kHz VGA |

## 2. Clocking

- The core uses a single **36 MHz** clock derived from the 100 MHz Basys 3 oscillator by the
  `clk_wiz_0` MMCM (verified, machine README).
- Solved MMCM constants (verified, machine README): `DIVCLK_DIVIDE=5`,
  `CLKFBOUT_MULT_F=49.5`, `CLKOUT0_DIVIDE_F=27.5`; `clk_out1` = 36 MHz; reset active-high
  (btnC), `locked` used.

## 3. Reset polarity

- **Basys 3:** `reset <= btnC` (active-high button), mirroring Pooyan.
- **[unverified]** DE10-lite side expects an active-low key; confirm against the pristine top.

## 4. Core instantiation

- Keep the `galaga` core port map (video r/g/b, blankn, hs, vs, audio) unchanged.
- **[unverified]** exact signal names/widths — confirm against `rtl_dar/galaga.vhd` and the
  sound/51XX submodules.

## 5. Video / scan doubler (31 kHz VGA)

- Galaga uses an imported **MiST `scandoubler.v`** (`imports/mist/scandoubler.v`), sourced from
  Arcade_Galaga — **not** the DECA `vga_scandoubler.v` used by Pooyan/Time-Pilot (verified,
  machine README). This divergence is expected for Galaga.
- **[unverified]** exact clocking of the doubler inputs, 6-bit→4-bit narrowing, `blankn` gating,
  and HS/VS polarity wiring — confirm against the Pooyan/Time-Pilot top as the pattern.

## 6. Audio (mono PWM on PmodAMP2)

- Mono PWM audio on PmodAMP2 (verified, machine README).
- Documented switch semantics (verified, machine README):
  - `sw(15)` → `O_PMODAMP2_GAIN`: gain 0 = 12 dB, 1 = 6 dB
  - `sw(14)` → `O_PMODAMP2_SHUTD`: shutdown 0 = off, 1 = on

## 7. Inputs

- PS/2 keyboard on JB (`ps2_dat`/`ps2_clk`) OR-merged with the JA joystick (verified, machine
  README). Key map (verified, with scancodes): Left `←` 0x6B, Right `→` 0x74, Fire Space 0x29,
  Coin F3 0x04, Start 1 F1 0x05, Start 2 F2 0x06.
- JA joystick, active-low (switch to GND): `JA1=Right, JA2=Left, JA3=Down, JA4=Up, JA7=Fire`.
  Invert (`not JA`) to active-high to match the core boundary (Pooyan pattern).
- Coin/start from joystick via combos: `coin = fire+up`, `start1 = fire+left`.
- P2 mirrors P1 left/right/fire inputs (verified, machine README).
- `btnC` = reset.
- **Known issue** (verified, machine README): the keyboard can randomly stick to the right (and
  maybe left) — an original core issue.

## 8. Credit-mode fix patch (gameplay, not synthesis)

- The pristine Dar core has a bug where Start 1 / Start 2 are ignored after inserting a coin.
  `contrib/code/galaga_credit_mode_fix.patch` is a **gameplay bug fix**, distinct from the
  synthesis-fix patches in the generic workflow: it re-enables the Namco 51XX credit-mode flag
  (`cs51XX_credit_mode <= '1'`) on every hardware coin edge, at `rtl_dar/galaga.vhd:848`.
- Apply from the machine root (containing `vhdl_galaga_rev_0_3_2018_05_06/`):
  `patch -p1 < galaga_credit_mode_fix.patch`; verify with
  `grep -n "cs51XX_credit_mode <= '1'" vhdl_galaga_rev_0_3_2018_05_06/rtl_dar/galaga.vhd`.
- **Layout divergence (flagged as-is):** the patch lives at `contrib/code/` (flat), not under
  `contrib/basys3/code/` as in the Pooyan/Time-Pilot convention. This is an open item; no
  migration is prescribed here.

## 9. PROM VHDL generation (required; never distributed)

- **Two** MAME romsets are required: `galaga.zip` + `galagamw.zip`, unzipped into
  `tools/galaga_unzip/`. The extra `galagamw` set provides the `3200a`-`3700g` CPU ROMs absent
  from the plain `galaga` set (verified, machine README).
- Run `./make_galaga_proms.sh` from that directory to generate the PROM VHDL:
  `galaga_cpu1/2/3.vhd`, `cs54xx_prog.vhd`, `sp_graphx.vhd`, `bg_graphx.vhd`, `sp_palette.vhd`,
  `bg_palette.vhd`, `rgb.vhd`, `sound_samples.vhd`, `sound_seq.vhd`.
- The script does **not yet exist** in `contrib/basys3/tools/` **[unverified]** — it is
  documented in the README and must be authored (use `make_pooyan_proms.sh` as the template).
- Roms and the generated PROM VHDL are copyrighted MAME-derived content — never commit or
  distribute them.

## 10. Build / project setup

- No Makefile or `contrib/basys3/` scripts yet — porting is currently manual via the Vivado
  project `basys3/galaga_basys3.xpr` **[unverified]**; script it like Pooyan when bring-up is
  done.
- **Non-nested project layout**: the `.xpr` lives directly in `basys3/` as
  `basys3/galaga_basys3.xpr`, with the sources tree at `basys3/galaga_basys3.srcs/`.
- Run synthesis/implementation from `/tmp` so `vivado.log` / `vivado.jou` stay outside the repo.
- Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`; roms: `ROMZIP` → `~/roms/`.

## 11. Open items

- Source tree not extracted; no scripts / Makefile yet.
- `make_galaga_proms.sh` not yet authored.
- Patch lives at `contrib/code/` (flat) vs. the `contrib/basys3/code/` convention.
- MiST `scandoubler.v` import path vs. any local copy — re-point the `.xpr` at the local import
  so the build is self-contained (canonical import never modified).
- Hardware verification (start/coin behavior, keyboard stick, 15 kHz mode).