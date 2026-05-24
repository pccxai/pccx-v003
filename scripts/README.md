# scripts

`run_verilator_smoke.sh` runs the standalone v003 common-library, Gemma 4 E4B
one-layer, and Gemma 4 E2B BF16 decode-slice smoke tests when Verilator is
installed locally.

`run_verilator_full_sim.sh` is the v003 decision gate wrapper for the full
available local Verilator simulation set.

`run_xsim_smoke.sh` runs the Gemma 4 E2B BF16 decode-slice smoke through the
Vivado xsim toolchain when `xvlog`, `xelab`, and `xsim` are available.

`run_vivado_aws_f2_synth.tcl` runs out-of-context Vivado synthesis for
`npu_v003_top` as the AWS F2 deploy-preview anchor. Set `AWS_F2_PART` to the
official AWS F2 shell FPGA part before launching Vivado.

`aws_f2_deploy_preview.sh` checks for the synthesis checkpoint and reports
the next gated packaging step without uploading artifacts or calling AWS APIs.

See [`SOURCE_MANIFEST.md`](../SOURCE_MANIFEST.md) and
[`docs/`](../docs/) for the implementation narrative.
