#!/usr/bin/env python3
"""Benchmark the pure-Python Gemma 4 smallest functional model."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "tests" / "functional"))

from gemma4_smallest_reference import (  # noqa: E402
    BF16_ONE,
    attention,
    decode_one_token,
    deterministic_packet,
    mlp,
    packet_from_lanes,
    rmsnorm,
)


def _measure(name: str, iterations: int, fn) -> dict[str, float | int | str]:
    checksum = 0
    start = time.perf_counter_ns()
    for iteration in range(iterations):
        packet = fn()
        word = packet.data_word() if hasattr(packet, "data_word") else packet.token
        checksum = (checksum + (word ^ iteration)) & 0xFFFFFFFFFFFFFFFF
    elapsed_ns = time.perf_counter_ns() - start
    return {
        "name": name,
        "iterations": iterations,
        "elapsed_ns": elapsed_ns,
        "ns_per_iter": elapsed_ns / iterations,
        "iters_per_sec": (iterations * 1_000_000_000) / elapsed_ns if elapsed_ns else 0,
        "checksum": checksum,
    }


def run_benchmark(iterations: int, lanes: int) -> list[dict[str, float | int | str]]:
    activation = deterministic_packet(lanes, user=0x1000, offset=0)
    weight = deterministic_packet(lanes, user=0x1001, offset=1)
    query = deterministic_packet(lanes, user=0x2000, offset=0)
    key = deterministic_packet(lanes, user=0x2001, offset=1)
    value = deterministic_packet(lanes, user=0x2002, offset=2)
    rotation = packet_from_lanes(
        [BF16_ONE if lane % 2 == 0 else 0x0000 for lane in range(lanes)],
        user=0x3000,
    )

    return [
        _measure("rmsnorm", iterations, lambda: rmsnorm(activation, weight)),
        _measure("attention", iterations, lambda: attention(query, key, value)),
        _measure("mlp", iterations, lambda: mlp(activation, weight)),
        _measure(
            "decode_one_token",
            iterations,
            lambda: decode_one_token(activation, weight, rotation, key, value, weight),
        ),
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--iterations", type=int, default=5000)
    parser.add_argument("--lanes", type=int, default=16)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    if args.iterations <= 0:
        parser.error("--iterations must be positive")
    if args.lanes <= 0 or args.lanes % 2:
        parser.error("--lanes must be a positive even integer")

    results = run_benchmark(args.iterations, args.lanes)
    if args.json:
        print(json.dumps(results, indent=2, sort_keys=True))
    else:
        print(f"functional model benchmark: lanes={args.lanes} iterations={args.iterations}")
        for result in results:
            print(
                "{name}: {ns_per_iter:.1f} ns/iter, {iters_per_sec:.1f} iter/s, checksum=0x{checksum:x}".format(
                    **result
                )
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
