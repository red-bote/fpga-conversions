# AGENTS.md

Staging area that converts DarFPGA FPGA projects ("by Dar") to the **Basys 3
(Artix-7)** trainer board. The root `README.md` has the full porting
background; each machine's own `README.md` is the source of truth for that
port's wiring.

Porting progress is deliberately **not tracked** here — state changes and can
appear to regress as work proceeds. Don't treat any status statement in the
docs as current.

## Layout

- `dloads/` — downloaded Dar source zips (gitignored; owned by
  `download_darfpga.sh`).
- `<Machine>-by-Dar/` (some dirs end `-Dar`, e.g. `Bagman-FPGA-Dar`; don't
  guess names) — per-machine: `readme-dar.txt`, the port's `README.md`, any
  `<game>_*.patch` fix, and the extracted `vhdl_<game>_rev_*/` tree
  (gitignored; contains the RTL plus `tools/<game>_unzip/` with the staged
  romset, generated PROM VHDL, and `make_<game>_proms.sh`).
- `contrib/basys3/` — port scaffold + build script (`create_project.sh`,
  `clean_project.sh`). Only Pooyan has one so far; don't assume the other
  machines' exist.

## Terminology

- hardware = a particular hardware platform being built in FPGA (one
  `<Machine>-by-Dar/` directory).
- machine = a hardware platform combined with a particular romset (some
  hardware support multiple romsets).
- Say "roms"/"romset", never "MAME roms"; describe machines/hardware, never
  "games"/"arcade". Upstream filenames keep their names
  (e.g. `make_pooyan_proms.sh`).

## Git

- Never run git commands (status, log, diff, checkout, …) unprompted. When
  explicitly asked, inspect once — a single read — and don't re-check.
- Never restore or peek at a port from git history: regeneration is always
  from scratch, from the READMEs and scripts only.

## Filesystem scope

- Read nothing outside this repo without explicit permission. Exceptions:
  `/tmp` (scratch; build scripts run there), `~/roms/` (`ROMZIP`), and the
  tool paths resolved via the env vars below.

## Cleanroom sourcing (copyright)

- The only user-supplied input is the MAME romset: never committed, never
  fetched — only unzipped in-tree by the build step.
- Any file taken from an external project must be **committed into this repo**
  with its origin (URL + revision) documented in the machine's `README.md`.
  Never link or fetch external files at build time.
- Generated PROM VHDL (`tools/*_unzip/*.vhd`) is copyrighted MAME-derived and
  intentionally shows as untracked — never stage it. Never `git add -A` /
  `git add .`; stage only the specific files intended. Vivado build junk
  (`<proj>.runs/.cache/.hw`, `.sim/`, `*.jou`, …) also shows untracked — don't
  clean it, just never stage it.

## Build & verification

- There is no CI/lint/test tooling. Don't invent test commands. The only
  verification is the fix-patch grep line in each machine's `README.md` plus
  running the download/unzip/build scripts.
- Order matters (hard prerequisite):
  1. `download_darfpga.sh` — downloads zips to `dloads/`
  2. `unzip_darfpga.sh` — extracts `vhdl_<game>_rev_*/` and applies fix patches
  3. `make_<game>_proms.sh` MUST run before synthesis: the `.xpr` references
     generated `*.vhd` in place under `tools/<game>_unzip/`, and synthesis fails
     on missing entities without them. `unzip_darfpga.sh`'s `GAMES` array is the
     authoritative dir ↔ zip ↔ patch mapping — don't guess dir names.
- Vivado builds run from `/tmp` so `vivado.log`/`vivado.jou` land outside the
  repo:
  `cd /tmp && <repo>/<Machine>-by-Dar/contrib/basys3/create_project.sh`
  (or `make hardware <name>` from the repo root).
- Tools/paths resolve `ENV_VAR → project default → interactive prompt`:
  - Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
  - romset: `ROMZIP` → `~/roms/`
  - Dar source zip: `DARZIP` → `<repo>/dloads/`
- `contrib/basys3/vga_scandoubler.v` is the canonical cleanroom import
  (hash-checked by `create_project.sh`) — never modify it.

## Per-machine Makefile (Pooyan)

Pooyan has a `Makefile` with useful targets (run from `Pooyan-by-Dar/`):

- `make` / `make build` — runs `create_project.sh` from `/tmp` (full build)
- `make setup-roms` — runs `create_project.sh --stage-roms` (stages ROMs and
  generates PROM VHDL only; no Vivado needed)
- `make clean` — removes Vivado build outputs (`.runs/`, `.cache/`, `.gen/`,
  `.hw/`, `.sim/`, `.ip_user_files/`, `*.jou`, `*.log`, `*.str`, `*.wdb`)
  but keeps the project sources
- `make distclean` — removes the entire extracted `vhdl_pooyan_rev_*/` tree
  (staged ROMs, generated PROM VHDL, rebuilt tools, regenerated project);
  restores the directory to just repo-tracked content

## Key porting gotchas (from Pooyan, apply broadly)

- `video_clk` declared on core entity but never driven — leave unconnected.
- DE10 `.qsf` may list PROM files the core never instantiates — omit from
  Vivado project.
- Core RGB is often 3:3:2; widen to 6:6:6 by bit duplication (`r&r`, `g&g`,
  `b&b&b`) for scandoubler, then truncate to 4:4:4 (`[5:2]`) for VGA.
- Sound board instantiated inside core — wrapper wires only top entity.
- DECA `vga_scandoubler.v` is a cleanroom import (hash-checked); modifying is
  off-limits — behavioral changes go in the wrapper.
- Vivado 2020.2 mixed-language elaboration: bare `'1'`/`'0'` literals to
  Verilog `input wire` ports fail (`Synth 8-2396`). Use qualified literals:
  `std_logic'('1')`.
- Keyboard decoder runs on half-rate clock (`clock_6` = `clock_12` / 2) for
  sync with core.
- Shipped `make_vhdl_prom` is a 32-bit ELF; rebuild from
  `tools/tools_prom_src/src/make_vhdl_prom.c` with `gcc -lm` for 64-bit hosts.
- Shipped `make_<game>_proms.bat` uses CRLF; mechanical translation to `.sh`
  must strip `\r` or filenames corrupt.
- **Video blanking**: the core's `blankn` signal must gate RGB output — when
  `blankn = '0'`, drive zeros to RGB (e.g., `r6 <= (others => '0') when
  blankn = '0' else ...`). This was missed in the DE10→Basys3 port.
