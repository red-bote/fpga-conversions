#!/usr/bin/env bash
# Create (or re-create) the pooyan_basys3 Vivado project. Run from any
# directory: the script locates the game tree relative to itself.
#
# Everything the project needs is regenerated on every run:
#   - the generated PROM VHDL (*.vhd) from the MAME ROM zip
#     (make_pooyan_proms.sh itself is translated from the shipped
#     make_pooyan_proms.bat when missing)
#   - the pooyan_basys3.vhd top wrapper, assembled from the IO mapping and
#     Wiring facts tables in Pooyan-by-Dar/README.md (the source of truth),
#     always regenerated into sources_1/new/
#   - the pooyan_basys3.xdc constraints, generated from the same IO mapping
#     (one set_property per pin) into constrs_1/imports/digilent-xdc-master/
#   - the DECA vga_scandoubler.v cleanroom import: the canonical committed
#     copy is contrib/basys3/vga_scandoubler.v (origin + SHA-256 in the
#     README); it is copied into the project only when absent or
#     hash-mismatched
#   - the clk_wiz_0 MMCM IP (frequencies from the README's Wiring facts table)
#
# No generated content or wiring data is embedded in this script: the wrapper
# and XDC are assembled entirely from the machine README. The only
# user-supplied inputs are the copyrighted MAME ROM zip (pooyan.zip) and a
# Vivado 2020.2 install; neither is ever fetched.
#
# If the extracted vhdl_pooyan_rev_0_2_2020_04_26/ tree is missing or not yet
# T80-patched, it is extracted from <repo>/dloads/ and the fix patch applied
# before the ROM pipeline (see 'Dar source zip resolution' below).
#
# Vivado resolution (first hit wins):
#   $VIVADO                                        env var
#   /tools/Xilinx/Vivado/2020.2/bin/vivado         default
#   interactive prompt
#
# Dar source zip resolution (only used when the extracted
# vhdl_pooyan_rev_0_2_2020_04_26/ tree is missing or not yet T80-patched):
#   $DARZIP                              env var
#   <repo>/dloads/vhdl_pooyan_rev_0_2_2020_04_26.zip   default
#   interactive prompt
#
# ROM zip resolution:
#   $ROMZIP                    env var
#   ~/roms/pooyan.zip          default
#   interactive prompt
#
# Run with CWD=/tmp so the vivado.log / vivado.jou that Vivado writes to the
# launch directory land outside the repo:
#   cd /tmp && /path/to/create_project.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
GAME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REV="$GAME_DIR/vhdl_pooyan_rev_0_2_2020_04_26"
PROJECT_DIR="$REV/basys3/pooyan_basys3"
SRC_ROOT="$PROJECT_DIR/pooyan_basys3.srcs"
WRAPPER="$SRC_ROOT/sources_1/new/pooyan_basys3.vhd"
XDC="$SRC_ROOT/constrs_1/imports/digilent-xdc-master/pooyan_basys3.xdc"
SCANDOUBLER="$SRC_ROOT/sources_1/imports/deca/vga_scandoubler.v"
PROM_DIR="$REV/tools/pooyan_unzip"
CONTRIB_DIR="$SCRIPT_DIR"
README="$GAME_DIR/README.md"

prom_files=(
  pooyan_prog.vhd pooyan_sound_prog.vhd \
  pooyan_char_grphx1.vhd pooyan_char_grphx2.vhd \
  pooyan_sprite_grphx1.vhd pooyan_sprite_grphx2.vhd \
  pooyan_palette.vhd pooyan_char_color_lut.vhd pooyan_sprite_color_lut.vhd
)
rom_files=(
  1.4a 2.5a 3.6a 4.7a 5.8a 6.9a 7.9g 8.10g xx.7a xx.8a \
  pooyan.pr1 pooyan.pr2 pooyan.pr3
)

die() { echo "error: $*" >&2; exit 1; }

# Source-of-truth data parsed from Pooyan-by-Dar/README.md: the IO mapping
# table (one row per wrapper port) and the Wiring facts table (key/value).
io_port=() io_dir=() io_width=() io_pins=()
declare -A fact

parse_readme() {
  [[ -f "$README" ]] || die "missing $README (source of truth)"
  local row port dir width pins func
  while IFS=$'\t' read -r row port dir width pins func; do
    case "$row" in
      I) io_port+=("$port"); io_dir+=("$dir"); io_width+=("$width"); io_pins+=("$pins") ;;
      F) fact["$port"]="$dir" ;;
    esac
  done < <(awk -F'|' '
    $0 ~ /^## IO mapping/ { sec="io"; next }
    $0 ~ /^## Wiring facts/ { sec="facts"; next }
    $0 ~ /^## / { sec=""; next }
    sec=="io" && $0 ~ /^\|/ {
      port=$2; dir=$3; width=$4; pins=$5; func=$6
      gsub(/^[ \t]+|[ \t]+$/, "", port)
      gsub(/^[ \t]+|[ \t]+$/, "", dir)
      gsub(/^[ \t]+|[ \t]+$/, "", width)
      gsub(/^[ \t]+|[ \t]+$/, "", pins)
      if (port == "" || port == "Port") next
      if (dir != "in" && dir != "out") next
      printf "I\t%s\t%s\t%s\t%s\t%s\n", port, dir, width, pins, func
    }
    sec=="facts" && $0 ~ /^\|/ {
      key=$2; val=$3
      gsub(/^[ \t]+|[ \t]+$/, "", key)
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      if (key == "" || key == "Fact") next
      printf "F\t%s\t%s\n", key, val
    }
  ' "$README")
  [[ ${#io_port[@]} -gt 0 ]] || die "no IO mapping rows parsed from $README"
  echo "readme  $(basename "$README"): ${#io_port[@]} ports, ${#fact[@]} wiring facts"
}

resolve_vivado() {
  if [[ -n "${VIVADO:-}" ]]; then
    echo "vivado  $VIVADO (env)"
  elif [[ -x /tools/Xilinx/Vivado/2020.2/bin/vivado ]]; then
    VIVADO=/tools/Xilinx/Vivado/2020.2/bin/vivado
    echo "vivado  $VIVADO (default)"
  else
    read -r -p "vivado binary path: " VIVADO || die "no vivado given"
    echo "vivado  $VIVADO"
  fi
  [[ -x "$VIVADO" ]] || die "$VIVADO is not executable"
  "$VIVADO" -version 2>/dev/null | head -1 | sed 's/^/vivado  /'
}

resolve_romzip() {
  if [[ -n "${ROMZIP:-}" ]]; then
    echo "roms    $ROMZIP (env)"
  elif [[ -f "$HOME/roms/pooyan.zip" ]]; then
    ROMZIP="$HOME/roms/pooyan.zip"
    echo "roms    $ROMZIP (default)"
  else
    read -r -p "path to pooyan.zip (MAME ROM set): " ROMZIP || die "no ROM zip given"
    echo "roms    $ROMZIP"
  fi
  [[ -f "$ROMZIP" ]] || die "$ROMZIP not found"
}

resolve_darzip() {
  local default="$GAME_DIR/../dloads/vhdl_pooyan_rev_0_2_2020_04_26.zip"
  if [[ -n "${DARZIP:-}" ]]; then
    echo "dar     $DARZIP (env)"
  elif [[ -f "$default" ]]; then
    DARZIP="$default"
    echo "dar     $DARZIP (default)"
  else
    read -r -p "path to vhdl_pooyan_rev_0_2_2020_04_26.zip (Dar source): " DARZIP || die "no Dar zip given"
    echo "dar     $DARZIP"
  fi
  [[ -f "$DARZIP" ]] || die "$DARZIP not found"
}

# The extracted Dar source tree is a derived, gitignored artifact (normally
# produced by unzip_darfpga.sh). If vhdl_pooyan_rev_0_2_2020_04_26/ is missing,
# extract it from dloads/vhdl_pooyan_rev_0_2_2020_04_26.zip before the ROM
# pipeline needs tools/ and rtl_*. And if the T80 XOR-width fix
# (pooyan_t80_xor_width.patch) is not applied yet, apply it - it is mandatory
# for Vivado synthesis. The README's verification grep
# ("'0'&x\"07\"" in rtl_t80_350/T80.vhd) is the idempotence gate.
ensure_dar_source() {
  local t80="$REV/rtl_t80_350/T80.vhd"
  if [[ -f "$t80" ]] && grep -q "'0'&x\"07\"" "$t80"; then
    echo "dar     $REV present, T80 fix applied"
    return
  fi
  if [[ -d "$REV" ]]; then
    [[ -f "$t80" ]] || die "unexpected: $REV exists but $t80 is missing (run unzip_darfpga.sh --force or clean up)"
  else
    resolve_darzip
    command -v unzip >/dev/null 2>&1 || die "unzip not found"
    command -v patch >/dev/null 2>&1 || die "patch not found"
    echo "dar     unzip $(basename "$DARZIP") -> $GAME_DIR/"
    unzip -q "$DARZIP" -d "$GAME_DIR"
    [[ -d "$REV" ]] || die "$DARZIP did not extract into $REV"
  fi
  echo "dar     applying pooyan_t80_xor_width.patch"
  patch -p1 -N -d "$GAME_DIR" < "$CONTRIB_DIR/pooyan_t80_xor_width.patch"
  grep -q "'0'&x\"07\"" "$t80" || die "T80 fix patch did not apply (see README 'Applying the T80 XOR-width fix')"
  echo "dar     T80 fix verified"
}

count_proms() {
  local n=0 f
  for f in "${prom_files[@]}"; do
    [[ -f "$PROM_DIR/$f" ]] && n=$((n + 1))
  done
  echo $n
}

stage_roms() {
  command -v unzip >/dev/null 2>&1 || die "unzip not found"
  echo "roms    unzip $(basename "$ROMZIP") -> tools/pooyan_unzip/"
  unzip -q -o "$ROMZIP" -d "$PROM_DIR"
  local f missing=0
  for f in "${rom_files[@]}"; do
    [[ -f "$PROM_DIR/$f" ]] || { echo "error: $f not in $(basename "$ROMZIP")" >&2; missing=1; }
  done
  [[ $missing -eq 0 ]] || die "ROM set does not match pooyan.zip"
  echo "roms    ${#rom_files[@]} files staged"
}

ensure_make_vhdl_prom() {
  local bin="$PROM_DIR/make_vhdl_prom"
  local src="$REV/tools/tools_prom_src/src/make_vhdl_prom.c"
  if [[ -x "$bin" ]] && file "$bin" 2>/dev/null | grep -q "ELF 64-bit"; then
    echo "build   make_vhdl_prom present (64-bit)"
    return
  fi
  [[ -f "$src" ]] || die "missing $src (run unzip_darfpga.sh first)"
  command -v gcc >/dev/null 2>&1 || die "gcc not found"
  echo "build   make_vhdl_prom from tools_prom_src/src (linux32 ELF unusable on 64-bit)"
  (cd "$REV/tools/tools_prom_src/src" && gcc make_vhdl_prom.c -lm -o make_vhdl_prom && cp make_vhdl_prom "$PROM_DIR/")
}

# make_pooyan_proms.sh is a mechanical translation of the shipped
# make_pooyan_proms.bat (copy /B a+b c.bin -> cat a b > c.bin, make_vhdl_prom ->
# ./make_vhdl_prom, del -> rm -f); see the top-level README. It is recreated
# here when missing (or CR-poisoned - the shipped .bat uses CRLF line endings,
# which would otherwise corrupt the emitted filenames), so its content never
# lives in this script.
ensure_make_pooyan_proms_sh() {
  local sh="$PROM_DIR/make_pooyan_proms.sh"
  local bat="$PROM_DIR/make_pooyan_proms.bat"
  if [[ -f "$sh" ]] && ! grep -q $'\r' "$sh"; then
    echo "build   make_pooyan_proms.sh present"
    return
  fi
  if [[ -f "$sh" ]]; then
    echo "build   make_pooyan_proms.sh CR-poisoned - regenerating"
  fi
  [[ -f "$bat" ]] || die "missing $bat (run unzip_darfpga.sh first)"
  {
    echo '#!/bin/bash'
    echo '# Port of the shipped make_pooyan_proms.bat (mechanical translation,'
    echo '# see top-level README "Stage the ROMs and generate the PROM VHDL").'
    echo '# Created by contrib/basys3/create_project.sh when missing.'
    echo 'set -e'
    echo ''
    awk '
      { sub(/\r$/, "", $0) }
      /^[ \t]*copy \/B / {
        sub(/^[ \t]*copy \/B +/, "");
        n = split($0, parts, / *\+ */);
        out = parts[n]; sub(/^[^ ]+ +/, "", out);
        sub(/ +[^ ]+$/, "", parts[n]);
        printf "cat"; for (i = 1; i <= n; i++) printf " %s", parts[i]; printf " > %s\n", out;
        next;
      }
      /^[ \t]*make_vhdl_prom / {
        sub(/^[ \t]*/, ""); $1 = "./make_vhdl_prom"; print; next;
      }
      /^[ \t]*del / {
        sub(/^[ \t]*del +/, "rm -f "); print; next;
      }
      { next }
    ' "$bat"
  } > "$sh"
  chmod +x "$sh"
  echo "build   make_pooyan_proms.sh translated from make_pooyan_proms.bat"
}

run_proms() {
  local n
  n="$(count_proms)"
  if [[ $n -eq ${#prom_files[@]} ]]; then
    echo "proms   $n/${#prom_files[@]} present - skip staging"
    return
  fi
  resolve_romzip
  stage_roms
  ensure_make_vhdl_prom
  ensure_make_pooyan_proms_sh
  echo "proms   make_pooyan_proms.sh -> ${#prom_files[@]} *.vhd"
  (cd "$PROM_DIR" && ./make_pooyan_proms.sh)
  n="$(count_proms)"
  [[ $n -eq ${#prom_files[@]} ]] || die "prom generation incomplete ($n/${#prom_files[@]})"
}

# Top wrapper, assembled from the README's IO mapping (entity) and Wiring
# facts (body) tables. Always regenerated fresh on every run - it is never
# committed and its content never lives in this script.
regenerate_wrapper() {
  mkdir -p "$(dirname "$WRAPPER")"
  local clock12="${fact[clk_wiz.out1_signal]:-clock_12}"
  local clock14="${fact[clk_wiz.out2_signal]:-clock_14}"
  local scand_vga="${fact[scandoubler.clkvga]:-clock_12}"
  local kbd_clk="${fact[kbd_clk]:-clock_6}"
  local scand_vid="${fact[scandoubler.clkvideo]:-clock_6}"
  local pwm_clk="${fact[pwm_clk]:-clock_14}"
  local sw6="${fact[scandoubler.rgb_width]:-6}"
  local vga_w="${fact[rgb_vga]:-4}"
  local dip1="${fact[dip_switch_1]:-FF}"
  local dip2="${fact[dip_switch_2]:-7F}"
  local sden="${fact[scandoubler.enable]:-1}"
  local sdse="${fact[scandoubler.scaneffect]:-1}"
  local amp_gain="${fact[amp.gain_from]:-sw(15)}"
  local amp_shutdown="${fact[amp.shutdown_from]:-sw(14)}"
  local in_freq="${fact[clk_wiz.input]:-100.000}"
  local out1="${fact[clk_wiz.out1]:-12.288}"
  local out2="${fact[clk_wiz.out2]:-14.318}"
  local rw gw bw
  IFS=';' read -r rw gw bw <<< "${fact[rgb_core]:-3;3;2}"
  local en_lit="std_logic'('0')"; [[ "$sden" == "1" ]] && en_lit="std_logic'('1')"
  local se_lit="std_logic'('0')"; [[ "$sdse" == "1" ]] && se_lit="std_logic'('1')"
  local vclk="${fact[video_clk]:-open}"
  local r6hi=$((sw6 - 1))
  local r6lo=$((sw6 - vga_w))
  local i j s dup

  {
    echo "---------------------------------------------------------------------------------"
    echo "-- Pooyan Basys 3 port by Red~Bote, for the Dar pooyan core (darfpga@aol.fr)"
    echo "-- http://darfpga.blogspot.fr"
    echo "--"
    echo "-- Basys 3 (Artix-7, xc7a35tcpg236-1) top wrapper, regenerated on every run by"
    echo "-- contrib/basys3/create_project.sh from the IO mapping + Wiring facts tables in"
    echo "-- Pooyan-by-Dar/README.md (source of truth). Do not hand-edit; change the README."
    echo "--"
    echo "-- Clocks  : ${in_freq} MHz -> clk_wiz_0 MMCM -> ${clock12} (${out1} MHz, game core)"
    echo "--           + ${clock14} (${out2} MHz, sound board)"
    echo "-- Video   : 31 kHz progressive VGA via the DECA vga_scandoubler.v cleanroom import;"
    echo "--           clkvga = ${scand_vga}, clkvideo = ${scand_vid} (half-rate)"
    echo "-- Controls: PS/2 keyboard on JB1/JB3 + JA joystick (active-low, OR-merged),"
    echo "--           btnC = reset (active-high)"
    echo "-- Audio   : PWM on PmodAMP2 (JC1=AIN); sw(15)/sw(14) select amp gain/shutdown"
    echo "---------------------------------------------------------------------------------"
    echo ""
    echo "library ieee;"
    echo "use ieee.std_logic_1164.all;"
    echo "use ieee.std_logic_unsigned.all;"
    echo "use ieee.numeric_std.all;"
    echo ""
    echo "entity pooyan_basys3 is"
    echo "port("
    local n=${#io_port[@]}
    for i in "${!io_port[@]}"; do
      local port="${io_port[$i]}" dir="${io_dir[$i]}" width="${io_width[$i]}"
      if (( width > 1 )); then
        decl=$(printf '%-18s : %-3s std_logic_vector(%d downto 0)' "$port" "$dir" $((width - 1)))
      else
        decl=$(printf '%-18s : %-3s std_logic' "$port" "$dir")
      fi
      if (( i == n - 1 )); then
        printf ' %s\n' "$decl"
      else
        printf ' %s;\n' "$decl"
      fi
    done
    echo ");"
    echo "end pooyan_basys3;"
    echo ""
    echo "architecture struct of pooyan_basys3 is"
    echo ""
    echo " signal ${clock12} : std_logic;"
    echo " signal ${clock14} : std_logic;"
    echo " signal ${scand_vid} : std_logic;"
    echo " signal reset    : std_logic;"
    echo " signal pll_locked : std_logic;"
    echo ""
    echo " signal r      : std_logic_vector($((rw - 1)) downto 0);"
    echo " signal g      : std_logic_vector($((gw - 1)) downto 0);"
    echo " signal b      : std_logic_vector($((bw - 1)) downto 0);"
    echo " signal csync  : std_logic;"
    echo " signal hsync  : std_logic;"
    echo " signal vsync  : std_logic;"
    echo " signal blankn : std_logic;"
    echo ""
    echo " signal r6, g6, b6    : std_logic_vector(${r6hi} downto 0);"
    echo " signal r6o, g6o, b6o : std_logic_vector(${r6hi} downto 0);"
    echo ""
    echo " signal audio           : std_logic_vector(10 downto 0);"
    echo " signal pwm_accumulator : std_logic_vector(12 downto 0);"
    echo ""
    echo " signal kbd_intr     : std_logic;"
    echo " signal kbd_scancode : std_logic_vector(7 downto 0);"
    echo " signal kbd_joy      : std_logic_vector(7 downto 0);"
    echo " signal joyPCFRLDU   : std_logic_vector(7 downto 0);"
    echo ""
    echo "begin"
    echo ""
    echo " reset <= btnC;"
    echo ""
    echo " O_PMODAMP2_GAIN  <= ${amp_gain};"
    echo " O_PMODAMP2_SHUTD <= ${amp_shutdown};"
    echo ""
    echo " -- ${in_freq} MHz -> ${clock12} (${out1} MHz, game core) + ${clock14} (${out2} MHz, sound)"
    echo " clk_wiz_0 : entity work.clk_wiz_0"
    echo " port map("
    echo "  clk_in1  => clk,"
    echo "  clk_out1 => ${clock12},"
    echo "  clk_out2 => ${clock14},"
    echo "  locked   => pll_locked"
    echo " );"
    echo ""
    echo " -- Pooyan core (untouched Dar RTL). video_clk is declared on the core entity"
    echo " -- but never driven - leave it unconnected (see README)."
    echo " pooyan : entity work.pooyan"
    echo " port map("
    echo "  clock_12     => ${clock12},"
    echo "  clock_14     => ${clock14},"
    echo "  reset        => reset,"
    echo "  video_r      => r,"
    echo "  video_g      => g,"
    echo "  video_b      => b,"
    echo "  video_clk    => ${vclk},"
    echo "  video_csync  => csync,"
    echo "  video_blankn => blankn,"
    echo "  video_hs     => hsync,"
    echo "  video_vs     => vsync,"
    echo "  audio_out    => audio,"
    echo "  dip_switch_1 => X\"${dip1}\", -- Coinage_B / Coinage_A"
    echo "  dip_switch_2 => X\"${dip2}\", -- Sound(8)/Difficulty(7-5)/Bonus(4)/Cocktail(3)/lives(2-1)"
    echo "  start2       => joyPCFRLDU(7),"
    echo "  start1       => joyPCFRLDU(6),"
    echo "  coin1        => joyPCFRLDU(5),"
    echo "  fire1        => joyPCFRLDU(4),"
    echo "  right1       => joyPCFRLDU(3),"
    echo "  left1        => joyPCFRLDU(2),"
    echo "  down1        => joyPCFRLDU(1),"
    echo "  up1          => joyPCFRLDU(0),"
    echo "  fire2        => joyPCFRLDU(4),"
    echo "  right2       => joyPCFRLDU(3),"
    echo "  left2        => joyPCFRLDU(2),"
    echo "  down2        => joyPCFRLDU(1),"
    echo "  up2          => joyPCFRLDU(0),"
    echo "  dbg_cpu_addr => open"
    echo " );"
    echo ""
    echo " -- widen ${rw}:${gw}:${bw} core RGB to ${sw6}:${sw6}:${sw6} for the scandoubler"
    s=""; for ((j = 0; j < sw6 / rw; j++)); do s+="r & "; done
    printf ' r6 <= %s;\n' "${s% & }"
    s=""; for ((j = 0; j < sw6 / gw; j++)); do s+="g & "; done
    printf ' g6 <= %s;\n' "${s% & }"
    s=""; for ((j = 0; j < sw6 / bw; j++)); do s+="b & "; done
    printf ' b6 <= %s;\n' "${s% & }"
    echo ""
    echo " -- DECA scandoubler: 15 kHz composite-sync video -> 31 kHz progressive VGA."
    echo " -- enable_scandoubling = '1' (the 15 kHz bypass is not wired on this port)."
    echo " scandoubler : entity work.vga_scandoubler"
    echo " port map("
    echo "  clkvideo            => ${scand_vid},"
    echo "  clkvga              => ${scand_vga},"
    echo "  enable_scandoubling => ${en_lit},"
    echo "  disable_scaneffect  => ${se_lit},"
    echo "  ri                  => r6,"
    echo "  gi                  => g6,"
    echo "  bi                  => b6,"
    echo "  hsync_ext_n         => hsync,"
    echo "  vsync_ext_n         => vsync,"
    echo "  csync_ext_n         => csync,"
    echo "  ro                  => r6o,"
    echo "  go                  => g6o,"
    echo "  bo                  => b6o,"
    echo "  hsync               => vgaHsync,"
    echo "  vsync               => vgaVsync"
    echo " );"
    echo ""
    echo " -- truncate ${sw6}:${sw6}:${sw6} to ${vga_w}:${vga_w}:${vga_w} for the Basys 3 VGA connector"
    echo " vgaRed   <= r6o(${r6hi} downto ${r6lo});"
    echo " vgaGreen <= g6o(${r6hi} downto ${r6lo});"
    echo " vgaBlue  <= b6o(${r6hi} downto ${r6lo});"
    echo ""
    echo " -- keyboard/joystick run on ${kbd_clk} (the core's synchronous half-rate clock)"
    echo " process (reset, ${clock12})"
    echo " begin"
    echo "  if reset = '1' then"
    echo "   ${kbd_clk} <= '0';"
    echo "  elsif rising_edge(${clock12}) then"
    echo "   ${kbd_clk} <= not ${kbd_clk};"
    echo "  end if;"
    echo " end process;"
    echo ""
    echo " keyboard : entity work.io_ps2_keyboard"
    echo " port map("
    echo "  clk       => ${kbd_clk},"
    echo "  kbd_clk   => ps2_clk,"
    echo "  kbd_dat   => ps2_dat,"
    echo "  interrupt => kbd_intr,"
    echo "  scancode  => kbd_scancode"
    echo " );"
    echo ""
    echo " joystick : entity work.kbd_joystick"
    echo " port map("
    echo "  clk          => ${kbd_clk},"
    echo "  kbdint       => kbd_intr,"
    echo "  kbdscancode  => std_logic_vector(kbd_scancode),"
    echo "  joyPCFRLDU   => kbd_joy"
    echo " );"
    echo ""
    echo " -- OR-merge the JA joystick (active-low, switch to GND) into the keyboard"
    echo " -- bus and decode the combo presses:"
    echo " --   JA1=right JA2=left JA3=down JA4=up JA7=fire"
    echo " --   Coin = fire+up, Start 1 = fire+left, Start 2 = fire+right"
    echo " joyPCFRLDU(0) <= kbd_joy(0) or not JA(3); -- up"
    echo " joyPCFRLDU(1) <= kbd_joy(1) or not JA(2); -- down"
    echo " joyPCFRLDU(2) <= kbd_joy(2) or not JA(1); -- left"
    echo " joyPCFRLDU(3) <= kbd_joy(3) or not JA(0); -- right"
    echo " joyPCFRLDU(4) <= kbd_joy(4) or not JA(4); -- fire"
    echo " joyPCFRLDU(5) <= kbd_joy(5) or (not JA(4) and not JA(3)); -- coin"
    echo " joyPCFRLDU(6) <= kbd_joy(6) or (not JA(4) and not JA(1)); -- start 1"
    echo " joyPCFRLDU(7) <= kbd_joy(7) or (not JA(4) and not JA(0)); -- start 2"
    echo ""
    echo " -- PWM audio on ${pwm_clk} (same clock as the sound board); MSB drives AIN"
    echo " process(${pwm_clk})"
    echo " begin"
    echo "  if rising_edge(${pwm_clk}) then"
    echo "   pwm_accumulator <= std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned(audio & \"00\"));"
    echo "  end if;"
    echo " end process;"
    echo ""
    echo " O_PMODAMP2_AIN <= pwm_accumulator(12);"
    echo ""
    echo "end struct;"
  } > "$WRAPPER"
  echo "port    pooyan_basys3.vhd -> sources_1/new/ (regenerated from README)"
}

# One set_property per pin from the README IO mapping (pins LSB->MSB).
generate_xdc() {
  mkdir -p "$(dirname "$XDC")"
  local i idx port width pins
  {
    echo "# pooyan_basys3.xdc - generated by contrib/basys3/create_project.sh"
    echo "# from the IO mapping in Pooyan-by-Dar/README.md (source of truth)."
    echo "# Pins from the Digilent Basys-3-Master.xdc; sys clock verbatim from"
    echo "# its line 8 (uncommented)."
    for i in "${!io_port[@]}"; do
      port="${io_port[$i]}"; width="${io_width[$i]}"
      IFS=';' read -r -a pins <<< "${io_pins[$i]}"
      for idx in "${!pins[@]}"; do
        if (( width > 1 )); then
          printf 'set_property -dict { PACKAGE_PIN %-6s IOSTANDARD LVCMOS33 } [get_ports {%s[%d]}]\n' "${pins[$idx]}" "$port" "$idx"
        else
          printf 'set_property -dict { PACKAGE_PIN %-6s IOSTANDARD LVCMOS33 } [get_ports {%s}]\n' "${pins[$idx]}" "$port"
        fi
      done
    done
    # -add keeps this alongside clk_wiz_0's in-context create_clock instead of
    # overriding it (Constraints 18-1056 / scoped-clock DRC otherwise fires).
    local period
    period="$(awk "BEGIN{printf \"%.2f\", 1000 / ${fact[clk_wiz.input]:-100.000}}")"
    printf 'create_clock -add -name sys_clk_pin -period %s -waveform {0 5} [get_ports clk]\n' "$period"
  } > "$XDC"
  echo "port    pooyan_basys3.xdc -> constrs_1/imports/digilent-xdc-master/ (generated from README)"
}

regenerate_scandoubler() {
  local canonical="$CONTRIB_DIR/vga_scandoubler.v"
  [[ -f "$canonical" ]] || die "missing canonical cleanroom copy $canonical (commit it; origin + SHA-256 recorded in the README)"
  mkdir -p "$(dirname "$SCANDOUBLER")"
  local want have
  want="$(sha256sum "$canonical" | cut -d' ' -f1)"
  have=""
  if [[ -f "$SCANDOUBLER" ]]; then
    have="$(sha256sum "$SCANDOUBLER" | cut -d' ' -f1)"
  fi
  if [[ "$have" != "$want" ]]; then
    cp -f "$canonical" "$SCANDOUBLER"
    echo "port    vga_scandoubler.v -> sources_1/imports/deca/ (copied, hash mismatch)"
  else
    echo "port    vga_scandoubler.v hash ok, untouched"
  fi
}

# Phase 1: create the project and the clk_wiz_0 MMCM IP. This also creates the
# pooyan_basys3.srcs tree that the regenerated port files live in.
create_project_ip() {
  local tclfile
  tclfile="$(mktemp /tmp/pooyan_ip.XXXXXX.tcl)"
  trap 'rm -f "$tclfile"' RETURN

  cat > "$tclfile" <<EOF
create_project -force pooyan_basys3 $PROJECT_DIR -part xc7a35tcpg236-1
set_property target_language VHDL [current_project]

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \\
  CONFIG.NUM_OUT_CLKS {2} \\
  CONFIG.PRIM_IN_FREQ {${fact[clk_wiz.input]:-100.000}} \\
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {${fact[clk_wiz.out1]:-12.288}} \\
  CONFIG.CLKOUT2_USED {true} \\
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {${fact[clk_wiz.out2]:-14.318}} \\
  CONFIG.USE_RESET {false} \\
] [get_ips clk_wiz_0]
generate_target all [get_ips clk_wiz_0]
close_project
puts "PROJECT_CREATED: $PROJECT_DIR/pooyan_basys3.xpr"
EOF

  echo "ip      clk_wiz_0 (${fact[clk_wiz.input]:-100.000} MHz -> ${fact[clk_wiz.out1]:-12.288} + ${fact[clk_wiz.out2]:-14.318} MHz, solved MMCM)"
  echo "proj    create pooyan_basys3.xpr (xc7a35tcpg236-1)"
  "$VIVADO" -mode batch -source "$tclfile"
}

# Phase 2: open the project and reference the regenerated sources/constraints
# in place.
assemble_project() {
  local vhdl_files=(
    "$REV/rtl_t80_350/T80.vhd"
    "$REV/rtl_t80_350/T80_ALU.vhd"
    "$REV/rtl_t80_350/T80_MCode.vhd"
    "$REV/rtl_t80_350/T80_Reg.vhd"
    "$REV/rtl_t80_350/T80s.vhd"
    "$REV/rtl_dar/gen_ram.vhd"
    "$REV/rtl_dar/io_ps2_keyboard.vhd"
    "$REV/rtl_dar/kbd_joystick.vhd"
    "$REV/rtl_mikej/YM2149_linmix_sep.vhd"
    "$REV/rtl_dar/pooyan_sound_board.vhd"
    "$REV/rtl_dar/pooyan.vhd"
    "$WRAPPER"
    "$SCANDOUBLER"
  )
  local f
  for f in "${prom_files[@]}"; do vhdl_files+=("$PROM_DIR/$f"); done

  echo "proj    add ${#vhdl_files[@]} sources"
  echo "proj    add constraints, top pooyan_basys3"

  local tclfile
  tclfile="$(mktemp /tmp/pooyan_sources.XXXXXX.tcl)"
  trap 'rm -f "$tclfile"' RETURN

  cat > "$tclfile" <<EOF
open_project $PROJECT_DIR/pooyan_basys3.xpr
add_files -norecurse ${vhdl_files[@]}
add_files -fileset constrs_1 -norecurse $XDC
set_property top pooyan_basys3 [current_fileset]
update_compile_order -fileset sources_1
close_project
puts "PROJECT_ASSEMBLED: $PROJECT_DIR/pooyan_basys3.xpr"
EOF

  "$VIVADO" -mode batch -source "$tclfile"
}

resolve_vivado
parse_readme
ensure_dar_source
run_proms
create_project_ip
regenerate_wrapper
generate_xdc
regenerate_scandoubler
assemble_project

echo "----------------------------------------"
echo "done: $PROJECT_DIR/pooyan_basys3.xpr created"
