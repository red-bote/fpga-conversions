# AGENTS.md

Staging area for porting DarFPGA arcade FPGA projects ("by Dar", darfpga@aol.fr)
to the Digilent Basys 3 (Artix-7) board. Ten arcade games, one directory each.
Target toolchain: Vivado 2020.2.

## Layout

- `downloads/` — the 10 `vhdl_<game>_rev_*.zip` DarFPGA archives (gitignored).
- `download_darfpga.sh` — fetches the zips: `./download_darfpga.sh [--force]`
  (skips existing; checks the `PK` zip magic to reject SourceForge HTML pages).
- `unzip_darfpga.sh` — unzips every zip into its game dir AND applies that
  game's fix patch (`patch -p1 -N`, so already-patched trees are skipped).
  `--force` re-unzips and re-applies. This script's `GAMES` array is the
  authoritative game-dir ↔ zip ↔ patch mapping — don't guess dir names.
- `<Game>-by-Dar/` (10 dirs; exact names vary, e.g. `Bagman-FPGA-Dar`,
  `Kick-Midway-MCR-by-Dar`, `Sky-skipper-by-Dar`). Each contains:
  - `readme-dar.txt` — upstream Dar release notes (keep as-is).
  - `README.md` — the Basys 3 port doc: IO mapping, keyboard/joystick bindings,
    MAME ROM set + `make_<game>_proms.sh` outputs, how to apply/verify the fix.
    The 10 READMEs also document each game's *solved* `clk_wiz_0` MMCM register
    values (`DIVCLK_DIVIDE`, `CLKFBOUT_MULT_F`, `CLKOUT0/1_DIVIDE`) — reuse
    these when creating a new game's MMCM instead of solving them again.
  - `*.patch` — only for the 5 patched games (Bagman, Berzerk, Galaga, Pooyan,
    Popeye): `bagman_xor_width.patch`, `berzerk_reset_sensitivity.patch`,
    `galaga_credit_mode_fix.patch`, `pooyan_t80_xor_width.patch`,
    `popeye_linmix_sensitivity.patch`. The other 5 have none yet.
  - `vhdl_<game>_rev_<...>/` — the unzipped Dar sources (all 10 present; the
    5 patched games already have their fix applied in-tree).
- `.gitignore` — enforces the copyright rules: `**/vhdl_*/*` ignores the whole
  Dar source tree (incl. generated PROM VHDL), then negations re-include
  `tools/`, `tools/*_unzip/`, and the `make_*_proms.sh` scripts so they stay
  tracked. A new `make_<game>_proms.sh` needs the same `!`-negation pattern
  (parent dirs must be re-included before the file).

## Porting status

Per-game `README.md`s describe the *target* port; only Pooyan has artifacts in
the tree so far, and only partial:

- Pooyan: `basys3/pooyan_basys3/` exists (untracked) with the `clk_wiz_0` MMCM
  IP (100 MHz → 12.288 + 14.318 MHz) in `sources_1/imports/clk_wiz_0/`. No
  `.xpr`, no `pooyan_basys3.vhd` wrapper, no XDC yet. The other 9 have no
  project artifacts at all.
- `make_pooyan_proms.sh` EXISTS and is git-tracked at
  `Pooyan-by-Dar/vhdl_pooyan_rev_0_2_2020_04_26/tools/pooyan_unzip/` — it is the
  reference implementation for the missing 9 (`make_<game>_proms.sh`). It is a
  mechanical translation of the Dar `.bat` (a `cat` concatenation + a
  `make_vhdl_prom` call per output VHD), run from its own dir, and it requires a
  rebuilt `make_vhdl_prom` binary in the same dir: the shipped
  `tools/tools_prom_src/binaries/linux32/make_vhdl_prom` is a 32-bit ELF that
  will NOT run on a 64-bit host without a 32-bit loader
  (`/lib/ld-linux.so.2`); rebuild from `tools/tools_prom_src/src/make_vhdl_prom.c`
  with `gcc make_vhdl_prom.c -lm` (only `make_vhdl_prom` is needed, no `.bat`
  uses `duplicate_byte`).
- The generated PROM VHDL (`*_prog.vhd`, `*_grphx*.vhd`, `*_palette*.vhd`) is
  ABSENT from the tree — the `.xpr` references it in place under
  `tools/<game>_unzip/`, so synthesis fails with missing entities until
  `make_<game>_proms.sh` runs on MAME ROMs. That step precedes any project
  assembly and is the only ROM-dependent prerequisite.
- Main `README.md` holds the authoritative 7-step per-machine port procedure
  (stage ROMs → MMCM → wrapper → scandoubler → XDC → project → verify); the
  per-game `README.md`s are the source of truth for wiring.

## Porting facts

- Strategy: reuse the Dar core verbatim; replace only the board-facing layer in
  a new top wrapper — Altera PLL → Xilinx `clk_wiz_0` MMCM, reset polarity
  (Basys 3 btnC is active-high), pin remap, XDC constraints, and a scandoubler
  to lift 15 kHz arcade timing to 31 kHz VGA.
- The per-game `README.md` is the source of truth for wiring; ports wire PS/2
  on JB1/JB3 and audio on JC.
- 15 kHz video: every Dar core produces native 15 kHz + `csync`; cores with
  `tv15Khz_mode` scan-double internally (Bagman, Berzerk, Kick, Popeye,
  Sky Skipper, Solar Fox), the rest need the external scandoubler bypassed
  (Galaga, Pooyan, Burnin' Rubber, Time Pilot). Sync mux: `vga_hs <= csync when
  tv15Khz_mode = '1' else hsync`. Status table in the main README.
- Top entities differ by game: most are `<game>_basys3` in
  `basys3/<game>_basys3.xpr`; Berzerk and Popeye use `rtl_top` in `<game>_xc7/`
  projects; Kick's project is `basys3/kickman_basys.xpr` (dir has no trailing "3").

## Applying a game's fix

Normal flow is `./unzip_darfpga.sh` (already run for all 10). To redo a single
game by hand: unzip the archive into the game dir, then `patch -p1 <
<game>_<fix>.patch`, then verify with the exact grep listed in that game's
`README.md`.

Fixes exist because pristine Dar sources fail Vivado synthesis (Bagman/Pooyan
XOR literal width, Berzerk/Popeye process-sensitivity list omissions, Galaga
credit-mode bug). A newly ported game with no patch likely hits similar issues;
follow the same pattern: minimal patch + grep verification line in its README.

## Rules

- Git repo on `main` (remote `origin`); only commit when asked. No CI/build/lint
  tooling exists; the only "verification" is the grep line in each game's
  `README.md` and running the two shell scripts. Don't invent test commands.
- MAME ROMs and the generated PROM VHDL are copyrighted — never copy them into
  the repo or commit them. The `.gitignore` enforces this; don't weaken it.
- Galaga's upstream file is `README.TXT` (uppercase); save it as `readme-dar.txt`
  for consistency with the other nine.
