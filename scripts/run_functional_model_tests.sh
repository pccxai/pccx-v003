#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 -m unittest discover -s tests/functional -p 'test_*.py'
python3 tests/functional/rtl_vectors.py --check tb/verilator/gemma4_bf16_functional_vectors.svh
