# Generic DE10-lite → Basys3 porting spec

This spec describes how to prepare a new machine's Basys3 porting project in this repo.
It is written generically using `<machine>` / `<set>` placeholders; see the per-machine specs
for concrete values (`<Machine>-by-Dar/PORTING_SPEC.md`).

**`Pooyan-by-Dar/` is the complete, fully-working reference implementation.** Its scripted
Makefile and `contrib/basys3/` layout are the template to mirror when bringing up any new
machine. When a step below is ambiguous, copy what Pooyan does.

## 1. Reference model

- Each machine lives in its own `<Machine>-by-Dar/` directory.
- Each machine's `README.md` is the single source of truth for that machine's design and build.
- Each machine carries a `PORTING_SPEC.md` documenting its specific porting decisions.
- Shared assets live under `<Machine>-by-Dar/contrib/basys3/`:
  - `code/` — `vga_scandoubler.v` (canonical, never modify) + `*.patch` (synthesis-fix records)
  - `vivado/` — `.xpr`, `.xdc`, clock-IP and project scripts
  - `tools/` — source-setup and rom-prep scripts

## 2. Prep workflow (order matters)

Bring the machine up in this order, mirroring Pooyan's scripts for each step.

1. **Scaffold** — create `README.md`, `PORTING_SPEC.md`, and the `contrib/basys3/{code,tools,vivado}` skeleton.
2. **Source archive** — obtain the Dar source zip (download index: `~/tmp/downloads.md`) and
   extract it into `vhdl_<machine>_rev_.../` at the machine root.
3. **Synthesis-fix patches** — any `contrib/basys3/code/*.patch` (e.g. Pooyan's T80 xor-width
   fix) applied idempotently with `patch -p1 --forward`. Only needed if the pristine core fails
   Vivado synthesis.
4. **Rom prep** — `prep_roms.sh`: compile `make_vhdl_prom` on the host (`gcc ... -lm`), convert
   `make_<machine>_proms.bat` → `.sh` (Pooyan sed rules), unzip `~/roms/<set>.zip`, run the
   generator to produce the PROM VHDL in place.
5. **Source setup** — `setup_<machine>.sh`: download/extract the archive, apply patches, then
   chain into rom-prep.
6. **Clock IP** — `make_clk_wiz_0.sh`: generate the `clk_wiz_0` MMCM deriving the core/sound
   clocks from the 100 MHz Basys 3 oscillator; place its wrappers where the `.xpr` references them.
7. **Project** — `create_project.sh`: create the project tree, copy the `.xpr` (re-pointing the
   scandoubler reference to the local import), `.xdc`, and `vga_scandoubler.v`.
8. **Makefile** — wire `all / setup / clk_wiz / clean` to the scripts; add `patch / synth /
   bitstream` once their scripts exist.

## 3. Porting steps (DE10-lite → Basys3)

The reusable transformations for the top-level wrapper. Each should be confirmed against the
pristine core, using Pooyan's top level as the worked example.

1. **Port list** — replace the DE10-lite ports (`max10_clk1_50`, `ledr`, `key`, `sw(9:0)`,
   `hex0-3`, `gpio`) with the Basys 3 set (`clk` 100 MHz, `sw(15:0)`, `btnC`, `ps2_dat/ps2_clk`,
   `O_PMODAMP2_AIN/GAIN/SHUTD`, `JA(4:0)`, 4-4-4 RGB + `vga_hs/vs`).
2. **Clocking** — replace the DE10 PLL (`max10_pll_*`) with `clk_wiz_0` (MMCM, 100 MHz in →
   core + sound clocks); keep the internal clock divider that feeds the PS/2 path.
3. **Reset polarity** — DE10 uses an active-low key; Basys 3 uses active-high `btnC`.
4. **Core instantiation** — keep the core port map unchanged; wire `video_hs`/`video_vs` (often
   left `open` on the DE10) to feed the scandoubler.
5. **Video / scan doubler** — feed the core's native video (zero-extended to 6-bit) into the DECA
   `vga_scandoubler` (`enable_scandoubling`/`disable_scaneffect = 1`), narrow the 6-bit output to
   the Basys 3 4-bit/color connector; gate RGB on `blankn` before the doubler; wire the core's
   active-low HS/VS directly to the doubler's active-low inputs. Clock `clkvideo`/`clkvga` to give
   the ~2× read/write ratio for real horizontal doubling.
6. **Audio** — keep the PWM accumulator; drive mono `O_PMODAMP2_AIN`; route the sound-enable and
   gain switches to `O_PMODAMP2_SHUTD` / `O_PMODAMP2_GAIN`.
7. **Inputs** — keep the PS/2 keyboard + `kbd_joystick`; OR-merge the JA joystick (inverted
   active-low → active-high to match the core boundary); coin/start via fire+direction combos;
   P2 mirrors P1.
8. **PROM VHDL** — generated from the staged romset (never distributed).

## 4. Shared conventions & hard rules

- **Non-nested project layout**: the `.xpr` lives directly in `basys3/` as
  `basys3/<machine>_basys3.xpr`, with the sources tree at `basys3/<machine>_basys3.srcs/`.
- **Vivado build scripts run from `/tmp`** so `vivado.log` / `vivado.jou` stay out of the repo.
- **Tool/path resolution** is `ENV_VAR → project default → interactive prompt`:
  - Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
  - roms: `ROMZIP` → `~/roms/`
- **Roms and generated PROM VHDL are copyrighted MAME-derived content** — never commit or
  distribute them. The `*.patch` files are the tracked record of changes to pristine Dar sources.

## 5. Status

- **Pooyan** — complete, working reference port (scripted, verified).
- **Time-Pilot** — complete, working port (scripted, hardware-verified); no T80 synthesis fix
  was needed for its T80 variant. See `Time-Pilot-by-Dar/PORTING_SPEC.md`.

The full machine index lives in the root `README.md`.
