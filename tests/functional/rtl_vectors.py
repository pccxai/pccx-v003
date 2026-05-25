#!/usr/bin/env python3
"""Emit SV localparams derived from the Python functional reference."""

from __future__ import annotations

import argparse
from pathlib import Path

from gemma4_smallest_reference import TensorPacket, functional_crosscheck_vectors


HEADER = """// Derived from tests/functional/rtl_vectors.py.
// Checked in so RTL smoke tests can compare against the Python reference.
"""


def _hex(value: int, bits: int) -> str:
    digits = (bits + 3) // 4
    return f"{bits}'h{value & ((1 << bits) - 1):0{digits}x}"


def _packet_params(prefix: str, packet: TensorPacket) -> list[str]:
    return [
        f"  localparam logic [FuncDataW-1:0] {prefix}_DATA = {_hex(packet.data_word(), packet.data_w)};",
        f"  localparam logic [FuncKeepW-1:0] {prefix}_KEEP = {_hex(packet.keep, packet.keep_w)};",
        f"  localparam logic [31:0] {prefix}_USER = {_hex(packet.user, 32)};",
        f"  localparam logic {prefix}_LAST = 1'b{1 if packet.last else 0};",
    ]


def render() -> str:
    vectors = functional_crosscheck_vectors()
    data_w = vectors["rms_input"].data_w
    lines = [
        HEADER.rstrip(),
        "`ifndef GEMMA4_BF16_FUNCTIONAL_VECTORS_SVH",
        "`define GEMMA4_BF16_FUNCTIONAL_VECTORS_SVH",
        "",
        "package gemma4_bf16_functional_vectors_pkg;",
        f"  localparam int FuncDataW = {data_w};",
        "  localparam int FuncKeepW = FuncDataW / 8;",
        "",
    ]

    ordered_names = (
        "rms_input",
        "rms_weight",
        "rms_expected",
        "attn_query",
        "attn_key",
        "attn_value",
        "attn_expected",
        "mlp_activation",
        "mlp_weight",
        "mlp_expected",
    )
    for name in ordered_names:
        lines.extend(_packet_params(f"FUNC_{name.upper()}", vectors[name]))
        lines.append("")

    lines.extend(["endpackage", "", "`endif", ""])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", type=Path, help="fail if PATH does not match generated vectors")
    parser.add_argument("--write", type=Path, help="write generated vectors to PATH")
    args = parser.parse_args()

    content = render()
    if args.write:
        args.write.write_text(content, encoding="utf-8")
    if args.check:
        current = args.check.read_text(encoding="utf-8")
        if current != content:
            print(f"{args.check} is stale; regenerate with tests/functional/rtl_vectors.py --write {args.check}")
            return 1
    if not args.write and not args.check:
        print(content, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
