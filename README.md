# fpga_conversions

Staging area for converting DarFPGA FPGA projects ("by Dar", darfpga@aol.fr)
to the **Basys 3 (Artix-7)** trainer board.

The converted projects will be created in this directory, alongside the
upstream source archives and any conversion tooling.

## Status

Porting progress is deliberately **not tracked in this repository** (see
`AGENTS.md`). All ports are work-in-progress and the state of this tree changes
— and can appear to regress — as work proceeds; don't treat any status
statement in these docs as current.

By default, **no git history is read** — not to restore artifacts and not even
to peek at a previous port. A port regeneration is completely from scratch and
depends only on information derived from the readmes (this file and the
per-game `README.md`s). Even when a game's `basys3/` tree exists in git history,
never `git checkout` it and never read its files out of history — reconstruct
the port from the documented procedure and wiring.

## Cleanroom sourcing

The ports are built cleanroom: the only user-supplied input is the copyrighted
MAME ROM set (never committed, never fetched from a repository). Every other
file a port needs must be present in this repo, either:

- vendored from the Dar archives in `downloads/` (unzipped in-tree by
  `unzip_darfpga.sh`), or
- a copy obtained from an external project (e.g. the DECA `vga_scandoubler.v`).

Any file copied from an external project must be **committed into this repo**
and its origin documented (URL + revision) in the per-game `README.md`. Never
link files from external projects by path, never fetch them at build time, and
never read them unless explicitly instructed — keep the sources self-contained.

### Repository hygiene

- MAME ROMs stay gitignored (enforced); the generated PROM VHDL (`*.vhd`) is
  re-included by `.gitignore` as a convention, so it shows as untracked — never
  `git add .` / `git add -A` (it would stage it); stage only the specific files
  intended.
- The `.gitignore` negations are generic (`**/vhdl_*/*` with `!**` re-includes
  for `tools/`, `tools/*_unzip/`, the `make_*_proms.sh` scripts, the `basys3/`
  port dirs, and generated `*.vhd`), so a new game needs no `.gitignore` edits.
- Vivado build junk is only partially ignored: `*.jou`, `*.log`, `*.str`,
  `*.wdb` match, but the dir patterns `**/.runs/` etc. do NOT match Vivado
  2020.2's `<proj>.runs`-style names — so a game's `<proj>.{runs,cache,hw}`
  build tree (and `.sim/` once a simulation has run) shows as untracked. Don't
  try to clean it; just never stage it.

## Contents

- `download_darfpga.sh` — downloads the DarFPGA source archives used by the
  ports (see below).
- `unzip_darfpga.sh` — unzips each archive into its machine's project directory
  and applies that machine's fix patch where one exists (see below).
- `downloads/` — the downloaded `vhdl_<game>_rev_*.zip` archives.
- Per-machine project directories (`Bagman-FPGA-Dar/` … `Time-Pilot-by-Dar/`)
  — each holding its machine's `readme-dar.txt` (see below), a `README.md`
  documenting that port's IO mapping, features supported, and required MAME ROM
  set, any `<game>_*.patch` fix for pristine Dar sources, and the upstream
  sources unzipped into `vhdl_<game>_rev_<...>/`.

## Downloading the sources

The archives come from
<https://sourceforge.net/projects/darfpga/files/Software%20VHDL/>:

| Machine | SourceForge folder | Zip |
|------|--------------------|-----|
| Bagman | `bagman` | `vhdl_bagman_rev_0_1_2018_06_05.zip` |
| Berzerk | `berzerk` | `vhdl_berzerk_rev_0_1_2018_08_08.zip` |
| Burnin Rubber | `burnin_rubber` | `vhdl_burnin_rubber_rev_0_0_2017_12_22.zip` |
| Galaga | `galaga` | `vhdl_galaga_rev_0_3_2018_05_06.zip` |
| Kick | `Kick_kickman` | `vhdl_kick_rev_0_2_2019_11_22.zip` |
| Pooyan | `pooyan` | `vhdl_pooyan_rev_0_2_2020_04_26.zip` |
| Popeye | `popeye` | `vhdl_popeye_rev_0_3_2020_01_27.zip` |
| Sky Skipper | `sky_skipper` | `vhdl_sky_skipper_rev_01_2020_01_28.zip` |
| Solar Fox | `Solarfox` | `vhdl_solar_fox_rev_0_1_2019_11_22.zip` |
| Time Pilot | `time_pilot` | `vhdl_time_pilot_rev_0_0_2017_11_05.zip` |

Run:

```bash
./download_darfpga.sh            # downloads into ./downloads/, skips existing
./download_darfpga.sh --force    # re-download everything
```

An optional positional `OUTDIR` defaults to `<script dir>/downloads`. Each
download is verified as a real zip (the `PK` magic header), so SourceForge HTML
error pages are rejected and removed rather than being mistaken for archives.

## Unzipping the sources

`unzip_darfpga.sh` maps each zip in `downloads/` to its machine's project
directory (e.g. `vhdl_kick_rev_*` → `Kick-Midway-MCR-by-Dar/`) and unzips it
there, preserving the archive's top-level `vhdl_<game>_rev_<...>/` folder. When
that machine has a fix patch (Bagman, Berzerk, Galaga, Pooyan, Popeye), it is
applied with `patch -p1 -N` afterwards, so an already-applied patch is skipped
rather than failing. Existing unzipped trees are skipped unless `--force` is
given:

```bash
./unzip_darfpga.sh            # unzips all archives into their project dirs
./unzip_darfpga.sh --force    # re-unzip everything and re-apply patches
```

The script's `GAMES` array is the authoritative game-dir ↔ zip ↔ patch mapping
— don't guess dir names from the tree.

## Per-machine project directories

Each zip maps to a project directory named after its machine (e.g.
`Bagman-FPGA-Dar/`, `Solar-Fox-by-Dar/`). Each holds its machine's
`readme-dar.txt`, from
`https://sourceforge.net/projects/darfpga/files/Software%20VHDL/<sf_folder>/README.txt/download`,
a `README.md` describing the Basys 3 port: IO mapping, features supported, and
the MAME ROM set(s) required, and the upstream sources under
`vhdl_<game>_rev_<...>/` (extracted by `unzip_darfpga.sh`). Each machine's
`README.md` is the source of truth for its wiring (IO mapping). Machines whose
pristine sources need fixing (Bagman, Berzerk, Galaga, Pooyan, Popeye) also
carry a `<game>_*.patch`; how to apply and verify it is described in that
machine's `README.md`.

Gotcha: Galaga's upstream file is named `README.TXT` (uppercase) — save it as
`readme-dar.txt` for consistency with the other games.

## How the projects are ported to the Basys 3

### What the originals look like
Each Dar release is a self-contained **DE10-Lite (Intel MAX 10)** project. The interesting logic — the machine core (`<game>.vhd`), sound board, YM2149 (MikeJ), Z80/6502 CPU core, and shared helpers (`gen_ram`, `io_ps2_keyboard`, `kbd_joystick`) — is written as **board-independent RTL**. A thin top wrapper (`<game>_de10_lite.vhd`) is the *only* file that talks to the hardware: the MAX 10 50 MHz oscillator, a `max10_pll_*.vhd` Altera PLL, active-low pushbuttons, switches, the PS/2 keyboard on GPIO pins, and a PWM audio output.

### The porting strategy: replace only the board-facing layer
The core is reused **verbatim**. The entire Basys 3 port lives in one new wrapper (`<game>_basys3.vhd` — the naming convention for all top layer wrapper files) plus project glue. It mirrors the DE10-Lite wrapper, with these substitutions:

**1. Clocking — the Altera PLL becomes a Xilinx MMCM**
The DE10-Lite PLL turns 50 MHz into the machine's clock frequencies (e.g. 12.288 MHz + 14.318 MHz for Pooyan). The port replaces it with a Vivado `clk_wiz_0` MMCM IP (in `sources_1/imports/clk_wiz_0/`) that produces the *same* frequencies from the Basys 3's 100 MHz oscillator. Nothing downstream changes — the machine core still sees identical clocks.

**2. Reset polarity**
DE10-Lite keys are active-low (`reset <= not key(0)`); Basys 3 buttons are active-high, so the wrapper simply does `reset <= btnC`.

**3. I/O remapping**
The same machine signals are wired to Basys 3 PMODs instead of MAX 10 GPIO, following a consistent scheme across every port:
- PS/2 keyboard on **JB** (JB1 = `ps2_dat`, JB3 = `ps2_clk`) via the unchanged `io_ps2_keyboard` scancode decoder + `kbd_joystick` scancode→button mapper (note: the specific F-key bindings differ per machine).
- **JA** joystick (active-low, switch to GND) OR-merged into the same `joyPCFRLDU` bus, with combo presses (e.g. Fire+Up = Coin, Fire+Left = Start 1) decoded in the wrapper.
- Audio on **PmodAMP2** (JC: JC1 = `AIN`, JC2 = `GAIN`, JC4 = `SHUTD`): the core's digital `audio_out` feeds a PWM accumulator (same technique as the DE10-Lite) whose MSB drives `AIN`; `sw(15)`/`sw(14)` control AMP gain/shutdown.

**4. Video — making 15 kHz timing display on a VGA monitor**
The cores output ~15 kHz timing with composite sync, which modern VGA monitors reject. Two solutions are used:
- **External scandoubler**: an imported DECA `vga_scandoubler.v` (origin:
  <https://github.com/DECAfpga/Arcade_Pooyan/blob/main/deca/vga_scandoubler.v>)
  doubles the pixel clock to 31 kHz progressive. The core's 3:3:2 RGB is widened
  to 6:6:6 by bit duplication (`r&r`, `g&g`, `b&b&b`), fed to the scandoubler,
  then truncated to 4:4:4 (`[5:2]`) for the Basys 3 VGA connector. `clkvga` must
  be double `clkvideo` (the wrapper divides `clock_12` by 2 to get `clock_6`).
  With `enable_scandoubling = '0'` the module passes 15 kHz through unchanged
  (`hsync <= csync`, `vsync <= '1'`) — its built-in TV bypass.
- **Core-internal doubling**: other cores already scan-double when `tv15Khz_mode = '0'`, so only the mode-select exposure changes (fixed `'0'`, a switch, or an F8 keyboard toggle).

Which approach a given machine uses is listed in that project's `README.md`.

**5. Physical constraints**
A modified Digilent `Basys-3-Master.xdc` (in `constrs_1/imports/digilent-xdc-master/`) maps the wrapper's ports to the board's physical pins — the MAX 10 `.qsf` pin assignments are simply replaced by this XDC.

**6. Default video: 31 kHz VGA on the Basys 3 VGA connector; 15 kHz CRT output is an optional mode**
Every port defaults to **31 kHz progressive VGA** on the Basys 3 VGA connector — the only timing a modern VGA monitor accepts. In addition, every Dar core produces the **native 15 kHz composite-sync video** (`video_csync`) that the DE10-Lite put on its VGA connector (`vga_hs <= csync` / `vga_vs <= '1'`); the ports bring that same 15 kHz signal out on the same VGA connector as an optional mode, selected with `tv15Khz_mode` ('0' = 31 kHz, '1' = 15 kHz), driven by a switch (Popeye uses `sw(13)`) or an F8 keyboard toggle (Kick, Sky Skipper, Solar Fox), per machine:

```vhdl
vga_hs <= csync  when tv15Khz_mode = '1' else hsync;
vga_vs <= '1'    when tv15Khz_mode = '1' else vsync;
```

RGB stays 4:4:4 in both modes. Two groups:

- **Cores that scan-double internally** (`tv15Khz_mode` is a real core input): Bagman, Berzerk, Kick, Popeye, Sky Skipper, Solar Fox. 31 kHz is the core's internal line doubler, so exposing the switch is all that's needed.
- **Native 15 kHz cores** (no internal doubler, `tv15Khz_mode` absent/commented out): Galaga, Pooyan, Burnin' Rubber, Time Pilot. Their Basys 3 ports route through the DECA scandoubler; 15 kHz mode is its built-in passthrough — drive `enable_scandoubling` low (`hsync <= csync`, RGB straight through).

| Machine | Core scan-doubles internally? | Basys 3 15 kHz status |
|------|-------------------------------|------------------------|
| Bagman | yes | `tv15Khz_mode` currently fixed `'0'` — wire the switch |
| Berzerk | yes | `tv15Khz_mode` currently fixed `'0'` — wire the switch |
| Kick | yes | F8 toggle — done |
| Sky Skipper | yes | F8 toggle — done |
| Solar Fox | yes | F8 toggle — done |
| Popeye | yes | sw(13) toggle — done |
| Galaga | no (external scandoubler) | add scandoubler bypass |
| Pooyan | no (external scandoubler) | add scandoubler bypass |
| Burnin' Rubber | no (external scandoubler) | add scandoubler bypass |
| Time Pilot | no (external scandoubler) | add scandoubler bypass |

The monitor must accept 15 kHz (a CRT, multisync monitor, or a 15→31 kHz
converter) — a modern VGA monitor will not sync.

### What is *not* touched
The machine core, sound/CPU cores, and the ROM PROM generation pipeline are shared as-is. The Vivado `.xpr` references the generated `*_prog.vhd` / `*_grphx*.vhd` / `*_palette*.vhd` files **in place** under `tools/<game>_unzip/`, so the only build prerequisite is running `make_<game>_proms.sh` on the MAME ROMs. In other words: port = new top wrapper + MMCM + scandoubler + XDC, over an untouched machine core.

The exact MAME ROM set(s) and staged-file details for each machine are listed in
that project's `README.md`.

## Creating the porting artifacts (per machine)

Porting is work-in-progress and deliberately not tracked here — see the
**Status** note at the top. Each machine's port is produced in this order. The
machine's `README.md` documents its exact ROM sets, wrapper ports, and
generated PROM file names.

> **Build prerequisite — do step 1 first.** Every core instantiates the
> generated PROM VHDL files (`*_prog.vhd`, `*_grphx*.vhd`, `*_palette*.vhd`) by
> entity name and the `.xpr` references them in place under
> `tools/<game>_unzip/`; `rtl_dar/proms/` is empty in the tree. Without them
> synthesis fails with missing entities, so `make_<game>_proms.sh` must be run
> before the project is assembled. This is the only ROM-dependent prerequisite
> (MAME ROMs are user-supplied and copyrighted — never commit them).

### 1. Stage the ROMs and generate the PROM VHDL

Unzip the required MAME ROM set(s) into
`vhdl_<game>_rev_<...>/tools/<game>_unzip/`, then run the PROM generator there.

`make_<game>_proms.sh` is a port of the Dar
`make_<game>_proms.bat` that ships in the archive. The `.bat` only concatenates
ROM binaries (`copy /B a+b c.bin`) and calls `make_vhdl_prom in.bin out.vhd`;
the `.sh` is a mechanical translation (`cat`/`rm`) that emits the
`*_prog.vhd` / `*_grphx*.vhd` / `*_palette*.vhd` outputs in place next to the
ROMs. The shipped `tools/tools_prom_src/binaries/linux32/make_vhdl_prom` is a
32-bit ELF that will NOT run on a 64-bit host without a 32-bit loader
(`/lib/ld-linux.so.2`) — rebuild it first from
`tools/tools_prom_src/src/make_vhdl_prom.c`: `gcc make_vhdl_prom.c -lm` (build
commands in `src/doc_compilation.txt`; no `.bat` uses `duplicate_byte`). The
Vivado
project references these files in place, so this step must precede project
assembly and is the only ROM-dependent build prerequisite.

For a game whose `make_<game>_proms.sh` does not yet exist, creating it is a
prerequisite of this step — a mechanical translation of the shipped
`make_<game>_proms.bat` (`cat`-concat the ROMs + one `make_vhdl_prom` call per
output VHD), run from the game's own `tools/<game>_unzip/` dir. Machine-specific
details (which input ROM files feed which output VHD) follow the game's `.bat`
and are captured in that machine's `README.md` as needed.

Game ROMs and the generated PROM VHDL are copyrighted — never commit or
redistribute them.

### 2. Generate the `clk_wiz_0` MMCM IP

In Vivado, create a Clocking Wizard named `clk_wiz_0` producing the machine
clock(s) from the Basys 3's 100 MHz oscillator (e.g. Pooyan's 12.288 + 14.318
MHz), matching the DE10-Lite PLL frequencies exactly. It lives at
`sources_1/imports/clk_wiz_0/`.

### 3. Write the `<game>_basys3.vhd` top wrapper

Copy the DE10-Lite wrapper and apply the substitutions from the porting
strategy above: Xilinx `clk_wiz_0` in place of the Altera PLL, `reset <= btnC`
(active-high), PS/2 on JB1/JB3, JA joystick, PWM audio on JC, VGA output, and
the `tv15Khz_mode` wiring per the machine's row in the video status table.

### 4. Import the scandoubler

Only for the native-15 kHz cores (Galaga, Pooyan, Burnin' Rubber, Time Pilot):
import the DECA `vga_scandoubler.v` (origin link in the video section above).
Wire `clkvideo` to half the VGA clock and `clkvga` to the full VGA clock, and
drive `enable_scandoubling` from the wrapper's `tv15Khz_mode` switch — the
module's `'0'` state IS the 15 kHz bypass (`hsync <= csync`), so no extra
muxing is needed.

Gotcha: Vivado 2020.2 mixed-language elaboration cannot resolve bare `'1'`/`'0'`
literals mapped to the Verilog `input wire` ports (`enable_scandoubling`,
`disable_scaneffect`) — it fails with `Synth 8-2396: near character '1' ; 3
visible types match here`; use qualified literals `std_logic'('1')` there.

### 5. Create the XDC constraints

Start from the Digilent `Basys-3-Master.xdc` and trim it to the wrapper's ports
(`constrs_1/imports/digilent-xdc-master/`).

### 6. Assemble the Vivado project

Create the `.xpr` with the core RTL taken verbatim from
`vhdl_<game>_rev_<...>/` plus the wrapper, IP, scandoubler, and XDC from the
steps above. Project path and top entity follow the machine's `README.md`: most
use `basys3/<game>_basys3.xpr` with top `<game>_basys3`; Berzerk and Popeye use
`rtl_top` in `<game>_xc7/`; Kick's project is `basys3/kickman_basys.xpr` (no
trailing "3").

### 7. Verify the fix and build

Apply/verify the machine's fix patch with the exact grep in its `README.md`,
then synthesize in Vivado 2020.2. A machine with no patch yet (Burnin' Rubber,
Kick, Sky Skipper, Solar Fox, Time Pilot) is expected to hit synthesis issues
similar to the fixed ones — resolve them the same way: minimal patch plus a grep
verification line added to its `README.md`.

There is no CI/build/lint tooling in this repo — the only verification is the
grep line above and running `download_darfpga.sh` / `unzip_darfpga.sh`. Don't
invent test commands.
