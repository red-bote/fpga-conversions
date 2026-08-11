# AGENTS.md

Staging area for porting DarFPGA arcade FPGA projects ("by Dar", darfpga@aol.fr)
to the Digilent Basys 3 (Artix-7) board. Ten arcade games, one directory each.
Target toolchain: Vivado 2020.2.

## Layout

- `downloads/` — the 10 `vhdl_<game>_rev_*.zip` DarFPGA archives (gitignored).
- `download_darfpga.sh` — fetches the zips: `./download_darfpga.sh [--force]`
  (skips existing; checks the `PK` zip magic to reject SourceForge HTML pages).
  Optional positional `OUTDIR` defaults to `<script dir>/downloads`.
- `unzip_darfpga.sh` — unzips every zip into its game dir AND applies that
  game's fix patch (`patch -p1 -N`, so already-patched trees are skipped).
  `--force` re-unzips and re-applies; optional positional `ZIPDIR` defaults to
  `downloads/`. This script's `GAMES` array is the authoritative game-dir ↔ zip
  ↔ patch mapping — don't guess dir names.
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
    `popeye_linmix_sensitivity.patch`. All 5 are already applied in-tree.
    The other 5 games have none yet.
  - `vhdl_<game>_rev_<...>/` — the unzipped Dar sources.
- `.gitignore` — enforces the copyright rules: `**/vhdl_*/*` ignores the whole
  Dar source tree (incl. staged MAME ROMs and shipped tool binaries), then
  negations re-include `tools/`, `tools/*_unzip/`, the `make_*_proms.sh` scripts,
  each game's `basys3/` port dir, and generated PROM VHDL (`*.vhd`). A new
  `make_<game>_proms.sh` or a new game's `basys3/` tree needs the same
  `!`-negation pattern (parent dirs must be re-included before the file).
  Vivado build junk is only partially ignored: the file patterns `*.jou`,
  `*.log`, `*.str`, `*.wdb` work (runme.log / vivado.jou stay hidden), but the
  dir patterns `**/.runs/`, `**/.cache/`, `**/.gen/`, `**/.hw/`, `**/.sim/`,
  `**/.ip_user_files/` do NOT match Vivado 2020.2's `<proj>.runs`-style dir
  names — so Pooyan's whole `pooyan_basys3.{runs,cache,hw,sim}` build tree
  shows as untracked in `git status` (~100 files). Don't try to clean it; just
  never `git add .` / `-A` (see Rules).

## Porting status

Per-game `README.md`s describe the *target* port. Pooyan is fully ported,
assembled, and built — synthesis and implementation both complete and a
bitstream exists (below). The other 9 games have nothing:

- Pooyan: all 7 port steps are done in-tree under
  `Pooyan-by-Dar/vhdl_pooyan_rev_0_2_2020_04_26/basys3/pooyan_basys3/`:
  - `pooyan_basys3.xpr` (Vivado 2020.2, part xc7a35tcpg236-1, top
    `pooyan_basys3`) referencing the core RTL in `rtl_dar/`, `rtl_t80_350/`,
    `rtl_mikej/` and the generated PROM VHDs in `tools/pooyan_unzip/` in place.
  - `pooyan_basys3.srcs/sources_1/new/pooyan_basys3.vhd` — the top wrapper
    (100 MHz → clk_wiz_0 MMCM → 12.288/14.318 MHz, active-high btnC reset gated
    on `locked`, DECA scandoubler, PS/2 on JB1/JB3, JA joystick, PmodAMP2 PWM).
  - `pooyan_basys3.srcs/sources_1/imports/clk_wiz_0/` — MMCM IP (2 `.v` files).
  - `pooyan_basys3.srcs/sources_1/imports/deca/vga_scandoubler.v`.
  - `pooyan_basys3.srcs/constrs_1/imports/digilent-xdc-master/pooyan_basys3.xdc`.
  - `make_pooyan_proms.sh` HAS been run — all 9 generated PROM VHDs exist in
    `tools/pooyan_unzip/` (gitignored-but-unignored via `!*.vhd`; never commit).
    The staged MAME ROMs (`1.4a`…`8.10g`, `pooyan.pr1-3`, `xx.7a/8a`) and the
    rebuilt 64-bit `make_vhdl_prom` sit in the same dir.
  - Synthesis + implementation COMPLETE: `pooyan_basys3.bit` is built in
    `pooyan_basys3.runs/impl_1/` (logs in `pooyan_basys3.runs/synth_1/runme.log`
    and `.../impl_1/runme.log`). An earlier run failed RTL elaboration with 3×
    `Synth 8-2396: near character '1' ; 3 visible types match here` at
    `pooyan_basys3.vhd:192`/`:193` — bare `'1'` literals mapped to
    `vga_scandoubler`'s Verilog `enable_scandoubling` / `disable_scaneffect`
    `input wire` ports. Vivado 2020.2 mixed-language elaboration can't resolve
    the literal's type (bit / std_logic / std_ulogic); the wrapper now maps
    qualified literals `std_logic'('1')` there, which fixed it. The
    `Synth 8-1565` warnings about `start2/start1/coin1` are benign.
- The other 9 games have no port artifacts at all: their `tools/<game>_unzip/`
  dirs hold only the upstream `make_<game>_proms.bat` + shipped Windows
  `make_vhdl_prom.exe` (gitignored) — no staged ROMs, no `.sh`, no MMCM.
- Almost everything Pooyan-ish is gitignored (`**/vhdl_*/*`): the staged MAME
  ROMs and the rebuilt `make_vhdl_prom` binary never appear in `git status` —
  check the filesystem, not git status, to see them. The un-ignored `basys3/`
  port tree (incl. the `clk_wiz_0` MMCM IP and `vga_scandoubler.v`) shows up as
  untracked; only `make_pooyan_proms.sh` is actually git-tracked (see
  `.gitignore` negations).
- **Generated PROM VHDs under `tools/<game>_unzip/` will show as untracked**
  in `git status` when produced (the `!*.vhd` gitignore negation) — never
  commit them (see Rules).
- `make_pooyan_proms.sh` EXISTS and is git-tracked at
  `Pooyan-by-Dar/vhdl_pooyan_rev_0_2_2020_04_26/tools/pooyan_unzip/` — it is the
  reference implementation for the missing 9 (`make_<game>_proms.sh`). It is a
  mechanical translation of the Dar `.bat` (a `cat` concatenation + a
  `make_vhdl_prom` call per output VHD), run from its own dir. (The main
  README's "does not exist yet" is stale for Pooyan.)
- `make_vhdl_prom` must be rebuilt into `tools/<game>_unzip/` from
  `tools/tools_prom_src/src/make_vhdl_prom.c` — note `tools/` here is INSIDE
  each `vhdl_<game>_rev_*/` tree, not at the repo root — with
  `gcc make_vhdl_prom.c -lm` (no `.bat` uses `duplicate_byte`; build commands
  in `src/doc_compilation.txt`). The shipped
  `tools/tools_prom_src/binaries/linux32/make_vhdl_prom` is a 32-bit ELF that
  will NOT run on a 64-bit host without a 32-bit loader (`/lib/ld-linux.so.2`).
  Pooyan's rebuilt 64-bit copy is already in place next to its `.sh`.
- The `.xpr` for each game will reference its generated PROM VHDL in place
  under `tools/<game>_unzip/`, so synthesis fails with missing entities until
  `make_<game>_proms.sh` runs. That step precedes project assembly and is the
  only ROM-dependent prerequisite.
- Main `README.md` holds the authoritative 7-step per-machine port procedure
  (stage ROMs → MMCM → wrapper → scandoubler → XDC → project → verify); the
  per-game `README.md`s are the source of truth for wiring.

## Porting facts

- Strategy: reuse the Dar core verbatim; replace only the board-facing layer in
  a new top wrapper (`<game>_basys3.vhd` naming convention) — Altera PLL →
  Xilinx `clk_wiz_0` MMCM, reset polarity (Basys 3 btnC is active-high, `reset
  <= btnC`), pin remap, XDC constraints, and a scandoubler to lift 15 kHz
  arcade timing to 31 kHz VGA.
- The per-game `README.md` is the source of truth for wiring; ports wire PS/2
  on JB1/JB3 and audio on JC (PmodAMP2, JC1 = AIN / JC2 = GAIN / JC4 = SHUTD).
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
- MAME ROMs and the generated PROM VHDL are copyrighted — never commit them.
  ROMs stay gitignored (enforced); generated PROM VHDs show as untracked, so
  the no-commit rule for them is convention-only — never run `git add .` /
  `git add -A` (it would stage them); stage only the specific files intended.
- Galaga's upstream file is `README.TXT` (uppercase); save it as `readme-dar.txt`
  for consistency with the other nine.
