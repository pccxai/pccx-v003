# scripts

`run_verilator_smoke.sh` runs the standalone v003 common-library and Gemma 4
E4B one-layer smoke tests when Verilator is installed locally.

`run_vivado_aws_f2_synth.tcl` runs out-of-context Vivado synthesis for
`npu_v003_top`. Set `AWS_F2_PART` to the official AWS F2 shell FPGA part before
launching Vivado.

See [`SOURCE_MANIFEST.md`](../SOURCE_MANIFEST.md) and
[`docs/`](../docs/) for the planning narrative.
