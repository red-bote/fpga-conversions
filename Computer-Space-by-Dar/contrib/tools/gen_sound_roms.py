#!/usr/bin/env python3
# Generate the six Computer Space sound ROM VHDL files from the Intel-HEX
# .hex files in the pristine Dar rtl/ tree.
#
# Computer Space is a discrete TTL game with no tools/, no make_vhdl_prom, and
# no .bat files. Its six sound waveform ROMs are the .hex files already present
# in rtl/ (bakamb/explosion/rotate/rocket_shooting/thrust/saucer_shooting).
# The original Altera altsyncram blocks were initialized from these .hex files.
#
# Vivado cannot read textio .hex at elaboration from the project tree (CWD
# issues) and the files are Intel-HEX records, not the simple hex-dump bytes
# a naive hread expects. Instead of loading them at synthesis time, this
# script parses the Intel-HEX and emits regular VHDL with an inline
# constant ROM initializer (the same style make_vhdl_prom produces for other
# ports), so synthesis infers BRAM with fixed content and needs no .hex file.
#
# The generated VHDL embeds copyrighted waveform data, so it is written into a
# gitignored location (vhdl_..._2017_11_22/basys3/generated_sound_roms/) and
# is never committed. Only this generator script is tracked.
#
# Usage: gen_sound_roms.py <rtl_dir> <out_dir>

import os
import sys

# (hex basename, entity name, address width-in-bits (-> depth), rom depth)
ROMS = [
    ("bakamb_8_11.hex", "bakam", 13, 16384),
    ("explosion_8_11.hex", "explosion", 13, 16384),
    ("rotate_8_11.hex", "rocket_rotate", 12, 8192),
    ("rocket_shooting_8_11.hex", "rocket_shooting", 14, 32768),
    ("thrust_8_11.hex", "rocket_thrust", 12, 8192),
    ("saucer_shooting_8_11.hex", "saucer_shooting", 12, 8192),
]

PER_LINE = 16


def parse_intel_hex(path):
    """Return a bytearray of the data payload, in record address order."""
    data = bytearray()
    for lineno, raw in enumerate(open(path), 1):
        line = raw.strip()
        if not line:
            continue
        if line[0] != ":":
            raise ValueError("%s:%d: not an Intel-HEX record: %r" % (path, lineno, line[:24]))
        try:
            rec = bytes.fromhex(line[1:])
        except ValueError as e:
            raise ValueError("%s:%d: bad hex in record: %s" % (path, lineno, e))
        if len(rec) < 5:
            raise ValueError("%s:%d: record too short" % (path, lineno))
        count = rec[0]
        if len(rec) != count + 5:
            raise ValueError(
                "%s:%d: record length mismatch (declared %d, got %d)"
                % (path, lineno, count, len(rec) - 5)
            )
        if (sum(rec) & 0xFF) != 0:
            raise ValueError("%s:%d: bad checksum" % (path, lineno))
        rtype = rec[3]
        if rtype == 0:
            data.extend(rec[4:4 + count])
        elif rtype == 1:
            break  # EOF record
        # types 2/3/4 (segment/linear addressing) are not present and unsupported
    return data


def emit_rom(name, addr_bits, depth, data, out_path):
    if len(data) > depth:
        raise ValueError(
            "%s: %d data bytes exceed declared depth %d" % (name, len(data), depth)
        )
    words = ['X"%02X"' % b for b in data]
    words += ["X\"00\""] * (depth - len(data))
    lit_rows = []
    for i in range(0, len(words), PER_LINE):
        lit_rows.append(", ".join(words[i:i + PER_LINE]))
    init = (",\n\t\t").join(lit_rows)
    vhdl = (
        "library ieee;\n"
        "use ieee.std_logic_1164.all;\n"
        "use ieee.numeric_std.all;\n"
        "\n"
        "entity %s is\n"
        "\tport (\n"
        "\t\taddress : in  std_logic_vector(%d downto 0);\n"
        "\t\tclock   : in  std_logic := '1';\n"
        "\t\tq       : out std_logic_vector(7 downto 0)\n"
        "\t);\n"
        "end %s;\n"
        "\n"
        "architecture rtl of %s is\n"
        "\ttype rom_t is array(0 to %d) of std_logic_vector(7 downto 0);\n"
        "\tsignal rom : rom_t := ( %s );\n"
        "begin\n"
        "\tprocess(clock)\n"
        "\tbegin\n"
        "\t\tif rising_edge(clock) then\n"
        "\t\t\tq <= rom(to_integer(unsigned(address)));\n"
        "\t\tend if;\n"
        "\tend process;\n"
        "end rtl;\n"
    ) % (
        name, addr_bits, name, name, depth - 1, init
    )
    with open(out_path, "w") as fh:
        fh.write(vhdl)


def main():
    if len(sys.argv) != 3:
        print("usage: %s <rtl_dir> <out_dir>" % sys.argv[0], file=sys.stderr)
        return 2
    rtl_dir, out_dir = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    for hex_name, entity, addr_bits, depth in ROMS:
        src = os.path.join(rtl_dir, hex_name)
        dst = os.path.join(out_dir, "rom_%s.vhd" % entity)
        data = parse_intel_hex(src)
        emit_rom(entity, addr_bits, depth, data, dst)
        print("generated %s (%d bytes -> %s)" % (entity, len(data), os.path.relpath(dst)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
