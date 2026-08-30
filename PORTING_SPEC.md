# Generic DE10-lite → Basys3 porting spec

This spec describes how to prepare a new machine's Basys3 porting project in this repo.
It is written generically using `<machine>` / `<set>` placeholders; see the per-machine specs
for concrete values (`<Machine>-by-Dar/PORTING_SPEC.md`).

Bring up a new machine by mirroring an existing complete, working port in this repo: its
scripted Makefile and `contrib/basys3/` layout are the template. When a step below is
ambiguous, copy what an existing full port does.

## 1. Reference model

- Each machine lives in its own `<Machine>-by-Dar/` directory.
- Each machine's `README.md` is the single source of truth for that machine's design and build.
- Each machine carries a `PORTING_SPEC.md` documenting its specific porting decisions.
  Canonical location is `<Machine>-by-Dar/contrib/basys3/PORTING_SPEC.md`; some
  machines still have it at the machine-directory top level pending migration.
- Shared assets live under `<Machine>-by-Dar/contrib/basys3/`:
  - `code/` — `vga_scandoubler.v` (canonical, never modify) + `*.patch` (synthesis-fix records)
  - `vivado/` — `.xpr`, `.xdc`, clock-IP and project scripts
  - `tools/` — source-setup and rom-prep scripts

## 2. Prep workflow (order matters)

Bring the machine up in this order, mirroring an existing full port's scripts for each step.

1. **Scaffold** — create `README.md` at the machine root, `PORTING_SPEC.md` under
   `contrib/basys3/`, and the `contrib/basys3/{code,tools,vivado}` skeleton.
2. **Source archive** — obtain the Dar source zip (download index: `~/tmp/downloads.md`) and
   extract it into `vhdl_<machine>_rev_.../` at the machine root.
3. **Synthesis-fix patches** — any `contrib/basys3/code/*.patch` (e.g. a core-specific
   synthesis-fix record) applied idempotently with `patch -p1 --forward`. Only needed if the
   pristine core fails Vivado synthesis.
4. **Rom prep** — `prep_roms.sh`: compile `make_vhdl_prom` on the host (`gcc ... -lm`), convert
   `make_<machine>_proms.bat` → `.sh` (the `.bat`→`.sh` sed rules), unzip `~/roms/<set>.zip`,
   run the generator to produce the PROM VHDL in place.
5. **Source setup** — `setup_<machine>.sh`: download/extract the archive, apply patches, then
   chain into rom-prep.
6. **Clock IP** — `make_clk_wiz_0.sh`: generate the `clk_wiz_0` MMCM deriving the core/sound
   clocks from the 100 MHz Basys 3 oscillator; place its wrappers where the `.xpr` references them.
7. **Project** — `create_project.sh`: clone the starting project from
   `wip/machine/contrib/basys3/basys3-project-template/` (the sample project; see
   §3) as the port's own `.xpr`/`.xdc`, and copy the
   template constraints file `Basys-3-Master.xdc`, uncommenting/renaming only the
   port lines the port uses;
   add the core sources, scandoubler import, and clk_wiz_0 wrappers.
8. **Makefile** — wire `all / setup / clk_wiz / clean` to the scripts; add `patch / synth /
   bitstream` once their scripts exist.

Steps 4–7 are templated under `wip/machine/contrib/` (`tools/`, `basys3/tools/`,
`basys3/vivado/`); the build scripts derive from those templates by substituting
`<game>` / `<src_dir>` / archive URL+SHA / clock / romset tokens, and the top-level
VHDL body is authored per port.

## 3. External IO convention (standard Basys3 mapping)

Every new port starts from the sample Vivado project: the ported `.xpr` and `.xdc`
derive from `wip/machine/contrib/basys3/basys3-project-template/`
(part `xc7a35tcpg236-1`, board
`digilentinc.com:basys3:part0:1.2`), specifically
`basys3-project-template.xpr` and its in-project constraints
`basys3-project-template.srcs/constrs_1/imports/digilent-xdc-master/Basys-3-Master.xdc`. The template XDC ships with
every pin commented out; a port uncomments and renames only the lines it uses — never re-author
the XDC, and keep the XDC-constrained port set minimal (declaring unconstrained ports fails
placement with `Place 30-58`).

The default external-IO mapping below is used unless a specific source port forces otherwise:

| Function | Basys 3 resource | Notes |
|---|---|---|
| reset | `btnC` | active-high |
| coin-in | `btnU` | |
| second coin-in | `btnD` | only if the core has 2 coin inputs |
| 1P start | `btnL` | |
| 2P start | `btnR` | |
| joystick left/right/up/down/fire | PMODA `JA[0..4]` (JA1–4, JA7) | active-low, switch to GND; OR-merged with the keyboard |
| PS/2 keyboard | JB1/JB3 `ps2_dat`/`ps2_clk` (A14/B15) | take all keys defined in the DE10-lite top source being ported |
| dipswitches | `sw` bits | map all dipswitches from the DE10-lite top |
| audio PWM | `O_PMODAMP2_AIN/GAIN/SHUTD` (JC) | sound-enable + gain on the switches |
| VGA | `vgaRed/vgaGreen/vgaBlue(3:0)`, `Hsync`, `Vsync` | 4-4-4 RGB; see TV note below |

- **PS/2** uses the JB1/JB3 header (A14/B15 `ps2_dat`/`ps2_clk`), not the template's
  USB-HID block.
- **TV display**: VGA is always supported. Additionally keep 15 kHz TV display support
  (native RGB + composite sync on HS) if the source port provides it.
- **LEDs / 7-segment display**: if the port source actively drives LEDs or a 7-segment
  display (e.g. the DE10-lite top carries `ledr`, `hex0-3`, or a debug hex-display path),
  map them on the Basys 3 too by uncommenting the template XDC's `led[0..15]` /
  `seg[0..6]`/`dp`/`an[0..3]` lines. Only include these if the source actually drives them.

## 4. Porting steps (DE10-lite → Basys3)

The reusable transformations for the top-level wrapper. Each should be confirmed against the
pristine core, using an existing full port's top level as the worked example.

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

## 5. Shared conventions & hard rules

- **Non-nested project layout**: the `.xpr` lives directly in `basys3/` as
  `basys3/<machine>_basys3.xpr`, with the sources tree at `basys3/<machine>_basys3.srcs/`.
- **Vivado build scripts run from `/tmp`** so `vivado.log` / `vivado.jou` stay out of the repo.
- **Tool/path resolution** is `ENV_VAR → project default → interactive prompt`:
  - Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
  - roms: `ROMZIP` → `~/roms/`
- **Roms and generated PROM VHDL are copyrighted content** — never commit or
  distribute them. The `*.patch` files are the tracked record of changes to pristine Dar sources.
