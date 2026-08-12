# AGENTS.md

Staging area for porting DarFPGA arcade FPGA projects ("by Dar", darfpga@aol.fr)
to the Digilent Basys 3 (Artix-7) board. Arcade games, one directory each.
Target toolchain: Vivado 2020.2.

Porting progress is deliberately NOT tracked in this repo — the per-game
READMEs describe the *target* ports, not current state. Never document WIP
status (e.g. "port X is underway / removed") in this file or the READMEs;
infer anything you need from the tree itself.

## Source of truth

- The top-level `README.md` holds the authoritative reference: the tree layout,
  `download_darfpga.sh` / `unzip_darfpga.sh` usage, the `GAMES` game-dir ↔ zip
  ↔ patch mapping, the 7-step per-machine port procedure (stage ROMs → MMCM →
  wrapper → scandoubler → XDC → project → verify), the cleanroom sourcing +
  repository-hygiene rules, and the toolchain gotchas. Read it before doing any
  porting work.
- The `GAMES` array in `unzip_darfpga.sh` is the authoritative game-dir ↔ zip ↔
  patch mapping — don't guess dir names from the tree.
- The per-game `README.md`s are the source of truth for wiring (IO mapping,
  keyboard/joystick bindings), MAME ROM sets, each game's *solved* `clk_wiz_0`
  MMCM register values (reuse these for a new game instead of solving a new
  MMCM), and the exact patch-verification grep.

## Porting rules

- A port = a new `<game>_basys3.vhd` wrapper over the untouched Dar core (Altera
  PLL → Vivado `clk_wiz_0` MMCM, `reset <= btnC`, pin remap, XDC, scandoubler);
  only the board-facing layer is replaced.
- Cleanroom: any file copied from an external project (e.g. the DECA
  `vga_scandoubler.v`) must be committed into this repo with its origin
  (URL + revision) documented in the per-game `README.md`. Never link external
  files by path, never fetch them at build time, never read them unless
  explicitly instructed.
- No git history is read by default: a port regeneration is completely from
  scratch and depends only on information derived from the readmes (the
  top-level `README.md` + the game's `README.md`). Even when a game's `basys3/`
  tree is committed, never `git checkout` it and never read its files out of
  history — reconstruct the port from the documented procedure and wiring.
- Build prerequisite: run `make_<game>_proms.sh` (from the game's own
  `tools/<game>_unzip/` dir) before assembling the Vivado project — the `.xpr`
  references the generated `*.vhd` PROMs in place, and synthesis fails with
  missing entities without them. `tools/` lives inside each `vhdl_<game>_rev_*/`
  tree, not at the repo root; the shipped `make_vhdl_prom` is a 32-bit ELF that
  must be rebuilt on a 64-bit host (`gcc make_vhdl_prom.c -lm`).
- Mixed-language gotcha (scandoubler games): wiring a Verilog module's input
  ports with bare `'1'`/`'0'` literals fails Vivado 2020.2 elaboration with
  `Synth 8-2396` ("3 visible types match here") — use qualified literals
  `std_logic'('1')` for `enable_scandoubling` / `disable_scaneffect`.
- Project/top naming isn't uniform: most games use `basys3/<game>_basys3.xpr`
  (top `<game>_basys3`), but Kick's is `basys3/kickman_basys.xpr` (top
  `kickman_basys3`, no trailing "3") and Berzerk/Popeye use `rtl_top` in
  `<game>_xc7/` — check the game's `README.md` before assembling or verifying.

## Verification

There is no CI/build/lint tooling. The only verification is the patch grep in
each game's `README.md` and running `download_darfpga.sh` / `unzip_darfpga.sh` —
don't invent test or build commands.

## Rules

- Only commit when asked; stage only the specific files intended — never
  `git add .` / `git add -A` (the why is in the README's Cleanroom section).
- MAME ROMs and the generated PROM VHDL are copyrighted — never commit or
  stage them. Generated `*.vhd` under `tools/<game>_unzip/` shows as untracked
  by design; leave it unstaged.
- Vivado build junk is only partially ignored: `**/.runs/` etc. do NOT match
  Vivado 2020.2's `<proj>.{runs,cache,hw}` dirs, so a synthesized game shows
  these as untracked (plus `.sim/` after a simulation). Don't clean them or
  extend `.gitignore` — the negations are tuned on purpose; just never stage
  them.
