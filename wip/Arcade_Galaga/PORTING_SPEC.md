# Arcade_Galaga (Somhi) → Basys3 porting spec

This spec defines the port of the **Arcade_Galaga** tree (Somhi / DECAfpga's multi-board
Galaga, adapted from Dar's DE10-lite core) to the Digilent Basys 3. It mirrors the generic
reference spec and the per-machine specs (Pooyan / Time-Pilot /
`Galaga-Midway-by-Dar/PORTING_SPEC.md`), which is also the **porting reference**: the Basys3
external signal wiring (XDC pin assignments for JA/JB/JC/VGA, switch semantics) is reused
from that port verbatim — both trees implement the same Namco Galaga hardware and share a
near-identical core.

Layout divergence from other machines (intentional): the upstream tree itself *is* the
machine directory — `Arcade_Galaga/` contains the Somhi board variants (`de10_lite/`,
`deca_lcd/`, `a100t_deca/`, `neptuno*/`, `tangnano20k/`, `a35t_zxtres/`), the shared RTL
(`rtl_dar/`, `rtl_T80/`, `mist/`) and tools, and gains the usual `contrib/`, `Makefile`,
scripts, and docs alongside. There is **no download step**: the tree is checked into the
repo, so `setup` skips the cache/SHA-256 machinery other machines need.

- Upstream: https://github.com/DECAfpga/Arcade_Galaga (Somhi), adapted from Dar's
  `vhdl_galaga_rev_0_3_2018_05_06` (SourceForge)
- Top entity: `arcade_galaga_basys3` (target file
  `basys3/arcade_galaga_basys3.srcs/sources_1/new/arcade_galaga_basys3.vhd`; the `_basys3`
  suffix disambiguates from the existing `galaga_basys3` of the Midway port)
- Part: `xc7a35tcpg236-1`, VHDL target language

## 1. Port list (DE10-lite → Basys3)

Against the pristine `rtl_dar/galaga_de10_lite.vhd` top:

| DE10-lite (pristine) | Basys 3 wrapper | Function |
|---|---|---|
| `max10_clk1_50` (50 MHz) | `clk` (W5, 100 MHz) | into `clk_wiz_0` MMCM |
| `key(0)` (active-low, aliased `reset_n`) | `btnC` (active-high) | reset |
| `key(1)`, `sw(9:0)`, `ledr(9:0)` | (dropped) | unused on the DE10 top |
| — | `sw(15:0)` | see §5/§6 (video mode, amp control) |
| `gpio(35)`/`gpio(34)` (aliased `ps2_clk`/`ps2_dat`) | `ps2_dat` / `ps2_clk` (JB1/JB3) | PS/2 keyboard |
| — | `JA(4:0)` (JA1-4, JA7) | joystick (active-low); keyboard-only on the DE10 top |
| `gpio(1)`/`gpio(3)` (aliased `pwm_audio_out_l`/`_r`, one PWM accumulator) | `O_PMODAMP2_AIN/GAIN/SHUTD` (JC1/2/4) | PWM audio (PmodAMP2), mono |
| `vga_r/g/b(3:0)`, `vga_hs`, `vga_vs` | `vga_r/g/b(3:0)`, `vga_hs`, `vga_vs` | 4-4-4 RGB; source changes from direct `csync`/`'1'` to the scandoubler path (§5) |

The DE10-lite top drives everything through GPIO-header aliases; the Basys3 wrapper moves
those functions onto the dedicated Pmod/VGA connectors per the Midway reference XDC
(`contrib/basys3/vivado/Basys-3-Master.xdc`, copied verbatim from
`Galaga-Midway-by-Dar/contrib/basys3/vivado/Basys-3-Master.xdc`). Constrained ports only —
no `led`/`btnU/L/R/D` declarations (they would fail placement, `Place 30-58`).

## 2. Clocking

- `clk_wiz_0` MMCM (100 MHz in) produces a single **36 MHz** `clk_out1`. Expected solved
  constants (per the Midway port, same frequency): `DIVCLK_DIVIDE=5`,
  `CLKFBOUT_MULT_F=49.5`, `CLKOUT0_DIVIDE_F=27.5`; confirm against the generated IP after
  `make clk_wiz`.
- Replaces the Altera `max10_pll_18M_11M` (18 MHz + 11 MHz from 50 MHz) used by every
  Somhi board top; that IP is excluded from the Vivado project.
- Core chain: `clock_36` ÷ 2 → `clock_18` (galaga core), ÷ 2 again → `clock_9`
  (PS/2 keyboard/joystick logic). Toggle-on-rising-edge halving pattern carried over from
  the Midway wrapper. (Somhi's tops clock the keyboard logic at ~11 MHz; the
  `io_ps2_keyboard` module is byte-identical across both trees and proven at 9 MHz in the
  Midway port.)
- Scan doubler clocks `clock_12`/`clock_6` come from a dedicated mod-6 counter on
  `clock_36` (§12) — wiring `clock_18`/`clock_36` directly did not work upstream
  (`-- clock_18, video_clk i clock_36 no funciona`).

## 3. Reset polarity

Project-standard structure (going forward, supersedes the bare-btnC form):

```vhdl
reset <= btnC or not mmcm_locked;   -- core in reset while pressed OR MMCM unlocking

clk_wiz_0 port map( ..., reset => btnC, locked => mmcm_locked );
```

DE10-lite original: `reset <= not reset_n` with `reset_n` aliased to active-low `key(0)`.

## 4. Core instantiation

`galaga` entity (`rtl_dar/galaga.vhd`, verified): `clock_18`, `reset` in;
`video_r(2:0)`, `video_g(2:0)`, `video_b(1:0)`, `video_clk` (unused, open),
`video_csync`, `video_blankn`, `video_hs`, `video_vs` out; `audio(9:0)` out;
`b_test`, `b_svce` tied `'1'`; inputs `coin`, `start1/2`, `left1/2`, `right1/2`, `fire1/2`.

Unlike Dar's pristine rev 0.3 core, Somhi's fork **already wires** `video_hs`/`video_vs`
(`galaga.vhd` instantiates `gen_video` with `hsync => video_hs`, `vsync => video_vs`) —
the `galaga_vga_sync.patch` step from the Midway port is **not needed**. `tv15Khz_mode`
does not exist on this entity (commented out upstream); there is no internal line-doubler
mode — 31 kHz VGA comes entirely from the external scan doubler (§5).

## 5. Video / scan doubler (31 kHz VGA)

- Imported **MiST `scandoubler.v`** — taken from Somhi's own `mist/scandoubler.v`, which is
  byte-identical to the Midway port's canonical pristine import
  (`Galaga-Midway-by-Dar/contrib/code/scandoubler.v`), copied to
  `imports/mist/scandoubler.v` by `create_project.sh`. This is the Galaga-family doubler,
  **not** the DECA `vga_scandoubler.v` used by Pooyan/Time-Pilot.
- Wiring (component declaration, port map, blanking-gated 3/3/2→6-bit RGB padding by MSB
  replication, 6→4-bit output narrowing, direct `hs_in`/`vs_in`): specified in §12,
  carried over from the Midway spec unchanged apart from file names.
- **Display-mode switch** via `sw(13)` (same convention as the Midway port):
  - `sw(13)=0` (default): 31 kHz VGA — scan-doubled 6-bit RGB narrowed to 4 bits
    (`*_o(5 downto 2)`), `hsync_o`/`vsync_o`.
  - `sw(13)=1`: 15 kHz TV — native core RGB padded to 4 bits (`r&'0'`, `g&'0'`, `b&"00"`,
    blanked on `blankn`), `vga_hs <= csync`, `vga_vs <= '1'`. Needs a 15 kHz RGB monitor
    or RGB→composite converter. Doubler keeps running (not clock-gated).

## 6. Audio (mono PWM on PmodAMP2)

- PWM accumulator clocked at `clock_18`: accumulate `'0' & pwm_accumulator(11 downto 0) +
  unsigned(audio & "000")` into 13 bits; MSB drives `O_PMODAMP2_AIN` (same pattern as the
  DE10-lite top and the Midway wrapper).
- Switch semantics (PmodAMP2):
  - `sw(15)` → `O_PMODAMP2_GAIN`: gain 0 = 12 dB, 1 = 6 dB
  - `sw(14)` → `O_PMODAMP2_SHUTD`: shutdown 0 = off, 1 = on

## 7. Inputs

### 7.1 PS/2 keyboard (Somhi `kbd_joystick` interface)

Chain: `io_ps2_keyboard` @ `clock_9` → `kbd_joystick` @ `clock_9`.

Somhi rewrote `kbd_joystick` relative to Dar's. Entity (verified):
`Clk`, `KbdInt`, `KbdScanCode` in; **`joy_BBBBFRLDU(8 downto 0)`**,
**`fn_pulse(7 downto 0)`**, **`fn_toggle(7 downto 0)`** out (inout-mode ports). Map
(scancodes are PS/2 set 2 makes; `fn_pulse(i)` rides the F-key level, `fn_toggle(i)`
flips once per press-release cycle):

| Key | Scancode | Signal |
|---|---|---|
| ↑ ↓ ← → | 0x75 0x72 0x6B 0x74 | `joy_BBBBFRLDU(0..3)` |
| Space | 0x29 | `joy_BBBBFRLDU(4)` (fire) |
| f g t v | 0x2B 0x34 0x2C 0x2A | `joy_BBBBFRLDU(5..8)` (spare buttons) |
| F1–F8 | 05 06 04 0C 03 0B 83 0A | `fn_pulse(0..7)` / `fn_toggle(0..7)` |

Core input wiring follows Somhi's own working top (`deca_lcd/galaga_deca.vhd:277-279`):

```
coin   <= fn_pulse(2)   -- F3 (0x04)
start1 <= fn_pulse(3)   -- F4 (0x0C)
start2 <= fn_pulse(4)   -- F5 (0x03)
left/right/fire <= joy_BBBBFRLDU(2)/(3)/(4)
```

(Somhi's inline comments label start1/start2 "F1"/"F2"; the scancode constants show they
are actually F4/F5, matching his README: F3 = add coins, F4 = start 1 player,
F5 = start 2 players.)

**Stale-source warning:** Somhi's `rtl_dar/galaga_de10_lite.vhd` predates this interface
rewrite — it declares `joyPCFRLDU(7 downto 0)` and instantiates `kbd_joystick` with a port
that no longer exists, so it will not compile against his own `rtl_dar`. The Basys3
wrapper is authored fresh against the real interface; the DE10-lite file serves only as
the diff base for the recorded top-level-rewrite patch (and is not a Vivado project
source).

### 7.2 JA joystick (Atari-style, active-low) — Midway reference wiring

`JA1=Right, JA2=Left, JA3=Down, JA4=Up, JA7=Fire` → `JA(0)=right, JA(1)=left, JA(2)=down,
JA(3)=up, JA(4)=fire`; inverted (`not JA`) to active-high at the wrapper. OR-merged with
the keyboard path:

```
left  <= kb_left  or not JA(1);
right <= kb_right or not JA(0);
fire  <= kb_fire  or not JA(4);
start1 <= kb_start1 or (not JA(4) and not JA(1));   -- fire+left
start2 <= kb_start2 or (not JA(4) and not JA(0));   -- fire+right
coin   <= kb_coin   or (not JA(4) and not JA(3));   -- fire+up
```

P2 mirrors P1 (`left2/right2/fire2` wired to the P1 signals). `btnC` = reset (§3).

## 8. Patches

Only **one** patch is required, and it is applied to an imported copy, never to the
pristine tree:

- **`scandoubler_fix.patch`** — Vivado 2020.2 Verilog parser fix. Somhi's
  `mist/scandoubler.v` contains the offending unpacked-array size declaration
  `reg [...] sd_buffer[2*2**HCNT_WIDTH];` (line 124) that Vivado rejects (Synth 8-2671).
  Since his copy is byte-identical to the Midway port's pristine canonical import, the
  Midway patch (`Galaga-Midway-by-Dar/contrib/code/scandoubler_fix.patch`) is reused
  verbatim, applied by `create_project.sh` to the copied instance at
  `basys3/arcade_galaga_basys3.srcs/sources_1/imports/mist/scandoubler.v` only.

Not needed (all three Dar-tree fixes are already present in Somhi's fork — verified):

- `galaga_vga_sync.patch` — superseded: `video_hs`/`video_vs` already driven (§4).
- `galaga_credit_mode_fix.patch` — superseded: `cs51XX_credit_mode <= '1'` already present
  at `galaga.vhd:710` and `:770` (two sites; Dar's patched tree had one at :848).
- `galaga_bgpalette_xor_length_fix.patch` — superseded: the `bgpalette_addr` expression is
  already parenthesized as the patch prescribes
  (`(hcnt(1 downto 0)) xor (flip_h & flip_h)`, `galaga.vhd:524-525`).

So `setup` applies **no** fix patches; the only generated patch is the recorded top-level
rewrite `contrib/basys3/code/galaga_de10_lite_to_basys3.patch` (authored by
`make_de10_lite_to_basys3_patch.sh`, applied to `rtl_dar/galaga_de10_lite.vhd` — kept for
convention/reviewability even though the wrapper is effectively a fresh authorship; see
the stale-source warning in §7.1).

## 9. PROM VHDL generation (required; never distributed)

- **Two romsets**, exactly as in the Midway port (verified against local sets):
  `$ROMZIP1` → `~/roms/galaga.zip` provides `prom-1.1d/2.5c/3.1c/4.2n/5.5n`,
  `54xx.bin` (and `51xx.bin`, unused here); the plain `galaga` set names its CPU/graphix
  ROMs `gg1_*` and does **not** provide the `3200a`-`3700g`/`2600j`/`2800l`/`2700k` bin
  files the generator expects. `$ROMZIP2` → `~/roms/galagamw.zip` provides all nine of
  those `.bin`s. Both unzip into `tools/galaga_unzip/`.
- `contrib/tools/prep_roms.sh` compiles `make_vhdl_prom` from
  `tools/tools_prom_src/src/make_vhdl_prom.c` on the host (gcc), regenerates
  `make_galaga_proms.sh` from the shipped `make_galaga_proms.bat` via the Time-Pilot-style
  sed conversion (the shipped `.sh` has CRLF endings and is bash-hostile; the conversion
  also strips `\r`), unzips both romsets, and runs the converted script.
- Generated PROM VHDL: `galaga_cpu1/2/3.vhd`, `cs54xx_prog.vhd` (**used** in this build,
  unlike some Somhi board ports), `bg_graphx.vhd`, `sp_graphx.vhd` (from
  `cat 2800l.bin 2700k.bin`), `rgb.vhd`, `bg_palette.vhd`, `sp_palette.vhd`,
  `sound_seq.vhd`, `sound_samples.vhd`.
- Destination: the generated `*.vhd` are **copied into `rtl_dar/`** — the qsf references
  `../rtl_dar/<name>.vhd` directly, despite the upstream README's `rtl_dar/proms` wording.
- Roms and generated PROM VHDL are copyrighted content — never commit or distribute
  (`.gitignore` already excludes `proms` and build outputs).

## 10. Build / project setup

- Non-nested project layout: `basys3/arcade_galaga_basys3.xpr` with sources under
  `basys3/arcade_galaga_basys3.srcs/` (Midway/Pooyan convention).
- Source list derives from `de10_lite/galaga_de10_lite.qsf` minus `max10_pll_18M_11M.vhd`
  (replaced by clk_wiz_0), minus the stale DE10-lite top (not a project source), plus the
  imported `mist/scandoubler.v` and the generated `arcade_galaga_basys3.vhd` top:
  - `rtl_dar/`: `galaga`, `galaga_video`, `gen_video`, `gen_ram`, `sound_machine`,
    `stars_machine`, `stars`, `mb88`, `cs54xx_prog`, `sp_graphx`, `sp_palette`,
    `bg_graphx`, `bg_palette`, `rgb`, `sound_seq`, `sound_samples`, `kbd_joystick`,
    `io_ps2_keyboard` (+ PROM VHDL per §9)
  - `rtl_T80/`: `T80se`, `T80_Pack`, `T80_MCode`, `T80_ALU`, `T80_Reg`
  - `imports/mist/scandoubler.v` (with §8 patch applied post-copy)
  - XDC: `contrib/basys3/vivado/Basys-3-Master.xdc`
- Scripted chain (targets mirror the other machines): `make setup` (tree check +
  `prep_roms.sh`), `make create_prj` (dirs, `.xpr` copy, XDC, scandoubler import+patch),
  `make clk_wiz` (`contrib/basys3/vivado/make_clk_wiz_0.sh`, Vivado-batch MMCM IP),
  `make patch` (top-level rewrite), `make synth`, `make bitstream`, `make clean`.
- Run synthesis/implementation from `/tmp` so `vivado.log`/`vivado.jou` stay outside the
  repo. Tool resolution: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`;
  `ROMZIP1`/`ROMZIP2` → `~/roms/galaga.zip` / `~/roms/galagamw.zip` (two-var deviation
  from the generic single-`ROMZIP`, inherited deliberately from the Midway port).

## 11. Open items

- Wrapper, scripts, `.xpr` and docs to be authored per this spec; verification ladder
  (`bash -n` → setup → create_prj → clk_wiz → patch + dry-run → bitstream → timing) to be
  executed end-to-end.
- Hardware verification pending: both display modes (VGA LCD + 15 kHz TV/converter),
  joystick combo inputs, F3/F4/F5 keys, audio on PmodAMP2. Known upstream issue worth
  watching: the Dar-core keyboard can randomly stick left/right (documented on the Midway
  port).
- `rtl_dar/kbd_joystick.vhd.bak` ships in the tree; excluded from any source list, left
  untouched otherwise.
- Root `README.md` machines index/status rows to be added with this port.

## 12. Scan doubler wiring (31 kHz VGA)

Carried over from `Galaga-Midway-by-Dar/PORTING_SPEC.md` §12 (same component, same
source, same clocks) with file names updated to this port. Authoritative for
`arcade_galaga_basys3.vhd`.

### 12.1 Component declaration

As declared in `arcade_galaga_basys3.vhd` (binds by name to Verilog module `scandoubler`,
parameters `COLOR_DEPTH = 6`, `HCNT_WIDTH = 9` at defaults):

```vhdl
component scandoubler
    port (
        clk_sys   : in  std_logic;
        scanlines : in  std_logic_vector (1 downto 0);
        ce_x1     : in  std_logic;
        ce_x2     : in  std_logic;
        hs_in     : in  std_logic;
        vs_in     : in  std_logic;
        r_in      : in  std_logic_vector (5 downto 0);
        g_in      : in  std_logic_vector (5 downto 0);
        b_in      : in  std_logic_vector (5 downto 0);
        hs_out    : out std_logic;
        vs_out    : out std_logic;
        r_out     : out std_logic_vector (5 downto 0);
        g_out     : out std_logic_vector (5 downto 0);
        b_out     : out std_logic_vector (5 downto 0)
    );
end component;
```

### 12.2 Port map (`scandoubler_inst`)

| Port | Connected signal |
|---|---|
| `clk_sys` | `clock_12` |
| `scanlines` | `"00"` (literal) |
| `ce_x1` | `clock_6` |
| `ce_x2` | `'1'` (literal) |
| `hs_in` / `vs_in` | `hsync` / `vsync` (core `video_hs`/`video_vs`) |
| `r_in` / `g_in` / `b_in` | `vga_r_i` / `vga_g_i` / `vga_b_i` |
| `hs_out` / `vs_out` | `hsync_o` / `vsync_o` |
| `r_out` / `g_out` / `b_out` | `vga_r_o` / `vga_g_o` / `vga_b_o` |

### 12.3 Upstream logic

- `hs_in`/`vs_in`: native undoubled core syncs (~15.6 kHz line rate); the core's
  `video_csync` is not connected to the doubler (used only by the TV path, §5).
- RGB in, blanking-gated MSB replication to 6 bits:

```vhdl
vga_r_i <= r & r     when blankn = '1' else "000000";
vga_g_i <= g & g     when blankn = '1' else "000000";
vga_b_i <= b & b & b when blankn = '1' else "000000";
```

- Clocks from one mod-6 counter on `clock_36`:

```vhdl
process (clock_36)
begin
    if rising_edge(clock_36) then
        clock_12 <= '0';
        if slot = "101" then
            slot <= (others => '0');
        else
            slot <= std_logic_vector(unsigned(slot) + 1);
        end if;
        if slot = "100" or slot = "001" then
            clock_6 <= not clock_6;
        end if;
        if slot = "100" or slot = "001" then
            clock_12 <= '1';
        end if;
    end if;
end process;
```

`clock_6`: 6 MHz 50%-duty square wave (toggles on slot states 1 and 4). `clock_12`: 12
MHz-*rate* pulse train (~1:3 duty, single-`clock_36` pulses on the same two states), used
directly as `clk_sys` — plain fabric logic, not a clock buffer/MMCM net. `ce_x2` ungated.

### 12.4 Downstream logic

```vhdl
vga_r <= ... vga_r_o(5 downto 2) ...;   -- VGA mode branch of the sw(13) mux
vga_g <= ... vga_g_o(5 downto 2) ...;
vga_b <= ... vga_b_o(5 downto 2) ...;
vga_hs <= hsync_o;                       -- VGA mode
vga_vs <= vsync_o;                       -- VGA mode
```

Two low-order bits of each 6-bit channel discarded; outputs constrained by
`Basys-3-Master.xdc` to the Basys 3 VGA connector pins.

### 12.5 Signal flow

```
galaga core                     arcade_galaga_basys3.vhd                scandoubler_inst         board pins
-----------                     ------------------------                ----------------         ----------
video_hs ----------------------> hsync --------------------------------> hs_in
video_vs ----------------------> vsync --------------------------------> vs_in
video_r/g/b, video_blankn -----> r,g,b,blankn --> vga_*_i (pad/blank) -> r/g/b_in
clock_36 --> [mod-6] --> clock_12 -------------------------------------> clk_sys
                        --> clock_6 -----------------------------------> ce_x1
                        '1' --------------------------------------------> ce_x2
                        "00" -------------------------------------------> scanlines
                                                                          hs_out --> hsync_o --(sw13=0)--> vga_hs
                                                                          vs_out --> vsync_o --(sw13=0)--> vga_vs
                                                                          r/g/b_out(5:2) -(sw13=0)------> vga_r/g/b --> VGA conn.
```

### 12.6 Signals not connected to the scan doubler

`video_csync` bypasses the doubler and feeds the `sw(13)='1'` TV branch only
(`vga_hs <= csync`, `vga_vs <= '1'`, native RGB padded/blanked) — mirroring the
commented-out `tv15Khz_mode` intent of the DE10 originals.
