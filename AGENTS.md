# AGENTS.md

Staging area for porting DarFPGA arcade FPGA projects ("by Dar", darfpga@aol.fr)
to the Digilent Basys 3 (Artix-7) board. Ten arcade games, one directory each.
Target toolchain: Vivado 2020.2.

## Layout

- `downloads/` — the 10 `vhdl_<game>_rev_*.zip` DarFPGA archives.
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
  - `*.patch` — only for the 5 patched games (Bagman, Berzerk, Galaga, Pooyan,
    Popeye): `bagman_xor_width.patch`, `berzerk_reset_sensitivity.patch`,
    `galaga_credit_mode_fix.patch`, `pooyan_t80_xor_width.patch`,
    `popeye_linmix_sensitivity.patch`. The other 5 have none yet.
  - `vhdl_<game>_rev_<...>/` — the unzipped Dar sources (all 10 present; the
    5 patched games already have their fix applied in-tree).

## What exists vs. what the READMEs describe

Per-game `README.md`s describe the *target* port, not the current tree. Absent
(created during porting): the Vivado `.xpr`, the `<game>_basys3.vhd` top
wrapper, `clk_wiz_0` MMCM IP, XDC, `imports/`, and `make_<game>_proms.sh` —
only the `.bat` ROM scripts ship in the Dar archives. The `tools/<game>_unzip/`
staging dirs and `.bat` scripts DO exist under `vhdl_<game>_rev_<...>/tools/`.
The shipped `tools/tools_prom_src/binaries/linux32/make_vhdl_prom` is a
  32-bit ELF that will NOT run on a 64-bit host without a 32-bit loader
  (`/lib/ld-linux.so.2`); it must be rebuilt from
  `tools/tools_prom_src/src/make_vhdl_prom.c` first: `gcc make_vhdl_prom.c -lm`
  (build commands in `src/doc_compilation.txt`; only `make_vhdl_prom` is needed,
  no `.bat` uses `duplicate_byte`). So the missing `make_<game>_proms.sh` is a
  mechanical translation of the `.bat`, with a build prerequisite.
  Don't assume any project file exists; porting work creates it.
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

- This directory is NOT a git repo and no CI/build/lint tooling exists; the
  only "verification" is the grep line in each game's `README.md` and running
  the two shell scripts. Don't invent test commands.
- MAME ROMs are copyrighted — never copy them into the repo or commit them
  (if a git repo is ever initialized).
- Galaga's upstream file is `README.TXT` (uppercase); save it as `readme-dar.txt`
  for consistency with the other nine.
