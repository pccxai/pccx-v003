set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ..]]

if {![info exists ::env(AWS_F2_PART)] || $::env(AWS_F2_PART) eq ""} {
  error "Set AWS_F2_PART to the AWS F2 shell FPGA part before running synthesis."
}

set part_name $::env(AWS_F2_PART)
set build_dir [file join $repo_root build v003_aws_f2_synth]
file mkdir $build_dir

create_project -force v003_aws_f2_synth $build_dir -part $part_name
set_property target_language SystemVerilog [current_project]
set_property include_dirs [list [file join $repo_root hw rtl v003]] [current_fileset]

read_verilog -sv [list \
  [file join $repo_root hw rtl v003 isa_pkg_v003.sv] \
  [file join $repo_root hw rtl v003 npu_v003_constants.sv] \
  [file join $repo_root hw rtl v003 npu_v003_dispatcher.sv] \
  [file join $repo_root hw rtl v003 npu_v003_l2_uram.sv] \
  [file join $repo_root hw rtl v003 npu_v003_top.sv] \
]

read_xdc [file join $repo_root constraints v003_aws_f2.xdc]

synth_design -top npu_v003_top -part $part_name -mode out_of_context

report_utilization -file [file join $build_dir utilization_synth.rpt]
report_timing_summary -file [file join $build_dir timing_synth.rpt]
write_checkpoint -force [file join $build_dir npu_v003_top_synth.dcp]
