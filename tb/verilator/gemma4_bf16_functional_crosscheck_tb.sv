`include "tb/verilator/gemma4_bf16_functional_vectors.svh"

module gemma4_bf16_functional_crosscheck_tb;
  import gemma4_bf16_functional_vectors_pkg::*;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int DataW = FuncDataW;
  localparam int KeepW = FuncKeepW;

  logic clk;
  logic rst_n;

  tensor_stream_if #(.DATA_W(DataW)) rms_input_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) rms_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) rms_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) attn_query_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) attn_key_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) attn_value_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) attn_context_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) mlp_activation_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) mlp_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) mlp_output_if (.clk(clk), .rst_n(rst_n));

  bf16_rmsnorm_core #(.DATA_W(DataW)) u_rmsnorm (
      .clk(clk),
      .rst_n(rst_n),
      .S_INPUT(rms_input_if),
      .S_WEIGHT(rms_weight_if),
      .M_OUTPUT(rms_output_if)
  );

  bf16_attention_core #(.DATA_W(DataW)) u_attention (
      .clk(clk),
      .rst_n(rst_n),
      .S_QUERY(attn_query_if),
      .S_KEY(attn_key_if),
      .S_VALUE(attn_value_if),
      .M_CONTEXT(attn_context_if)
  );

  bf16_mlp_core #(.DATA_W(DataW)) u_mlp (
      .clk(clk),
      .rst_n(rst_n),
      .S_ACTIVATION(mlp_activation_if),
      .S_WEIGHT(mlp_weight_if),
      .M_ACTIVATION(mlp_output_if)
  );

  always #5 clk = !clk;

  task automatic expect_packet(
      input string name,
      input logic [DataW-1:0] actual_data,
      input logic [DataW-1:0] expected_data,
      input logic [KeepW-1:0] actual_keep,
      input logic [KeepW-1:0] expected_keep,
      input logic [31:0] actual_user,
      input logic [31:0] expected_user,
      input logic actual_last,
      input logic expected_last
  );
    if (actual_data !== expected_data) begin
      $fatal(1, "%s data expected 0x%016x got 0x%016x", name, expected_data, actual_data);
    end
    if (actual_keep !== expected_keep) begin
      $fatal(1, "%s keep expected 0x%02x got 0x%02x", name, expected_keep, actual_keep);
    end
    if (actual_user !== expected_user) begin
      $fatal(1, "%s user expected 0x%08x got 0x%08x", name, expected_user, actual_user);
    end
    if (actual_last !== expected_last) begin
      $fatal(1, "%s last expected %0d got %0d", name, expected_last, actual_last);
    end
  endtask

  task automatic run_rmsnorm_crosscheck;
    rms_output_if.ready = 1'b1;
    rms_input_if.data = FUNC_RMS_INPUT_DATA;
    rms_input_if.keep = FUNC_RMS_INPUT_KEEP;
    rms_input_if.user = FUNC_RMS_INPUT_USER;
    rms_input_if.last = FUNC_RMS_INPUT_LAST;
    rms_input_if.valid = 1'b1;
    rms_weight_if.data = FUNC_RMS_WEIGHT_DATA;
    rms_weight_if.keep = FUNC_RMS_WEIGHT_KEEP;
    rms_weight_if.user = FUNC_RMS_WEIGHT_USER;
    rms_weight_if.last = FUNC_RMS_WEIGHT_LAST;
    rms_weight_if.valid = 1'b1;

    @(posedge clk);
    #1;
    rms_input_if.valid = 1'b0;
    rms_weight_if.valid = 1'b0;

    if (!rms_output_if.valid) begin
      $fatal(1, "rmsnorm functional cross-check did not emit output");
    end
    expect_packet(
        "rmsnorm",
        rms_output_if.data,
        FUNC_RMS_EXPECTED_DATA,
        rms_output_if.keep,
        FUNC_RMS_EXPECTED_KEEP,
        rms_output_if.user,
        FUNC_RMS_EXPECTED_USER,
        rms_output_if.last,
        FUNC_RMS_EXPECTED_LAST
    );
  endtask

  task automatic run_attention_crosscheck;
    attn_context_if.ready = 1'b1;
    attn_query_if.data = FUNC_ATTN_QUERY_DATA;
    attn_query_if.keep = FUNC_ATTN_QUERY_KEEP;
    attn_query_if.user = FUNC_ATTN_QUERY_USER;
    attn_query_if.last = FUNC_ATTN_QUERY_LAST;
    attn_query_if.valid = 1'b1;
    attn_key_if.data = FUNC_ATTN_KEY_DATA;
    attn_key_if.keep = FUNC_ATTN_KEY_KEEP;
    attn_key_if.user = FUNC_ATTN_KEY_USER;
    attn_key_if.last = FUNC_ATTN_KEY_LAST;
    attn_key_if.valid = 1'b1;
    attn_value_if.data = FUNC_ATTN_VALUE_DATA;
    attn_value_if.keep = FUNC_ATTN_VALUE_KEEP;
    attn_value_if.user = FUNC_ATTN_VALUE_USER;
    attn_value_if.last = FUNC_ATTN_VALUE_LAST;
    attn_value_if.valid = 1'b1;

    @(posedge clk);
    #1;
    attn_query_if.valid = 1'b0;
    attn_key_if.valid = 1'b0;
    attn_value_if.valid = 1'b0;

    if (!attn_context_if.valid) begin
      $fatal(1, "attention functional cross-check did not emit output");
    end
    expect_packet(
        "attention",
        attn_context_if.data,
        FUNC_ATTN_EXPECTED_DATA,
        attn_context_if.keep,
        FUNC_ATTN_EXPECTED_KEEP,
        attn_context_if.user,
        FUNC_ATTN_EXPECTED_USER,
        attn_context_if.last,
        FUNC_ATTN_EXPECTED_LAST
    );
  endtask

  task automatic run_mlp_crosscheck;
    mlp_output_if.ready = 1'b1;
    mlp_activation_if.data = FUNC_MLP_ACTIVATION_DATA;
    mlp_activation_if.keep = FUNC_MLP_ACTIVATION_KEEP;
    mlp_activation_if.user = FUNC_MLP_ACTIVATION_USER;
    mlp_activation_if.last = FUNC_MLP_ACTIVATION_LAST;
    mlp_activation_if.valid = 1'b1;
    mlp_weight_if.data = FUNC_MLP_WEIGHT_DATA;
    mlp_weight_if.keep = FUNC_MLP_WEIGHT_KEEP;
    mlp_weight_if.user = FUNC_MLP_WEIGHT_USER;
    mlp_weight_if.last = FUNC_MLP_WEIGHT_LAST;
    mlp_weight_if.valid = 1'b1;

    @(posedge clk);
    #1;
    mlp_activation_if.valid = 1'b0;
    mlp_weight_if.valid = 1'b0;

    if (!mlp_output_if.valid) begin
      $fatal(1, "mlp functional cross-check did not emit output");
    end
    expect_packet(
        "mlp",
        mlp_output_if.data,
        FUNC_MLP_EXPECTED_DATA,
        mlp_output_if.keep,
        FUNC_MLP_EXPECTED_KEEP,
        mlp_output_if.user,
        FUNC_MLP_EXPECTED_USER,
        mlp_output_if.last,
        FUNC_MLP_EXPECTED_LAST
    );
  endtask

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;

    rms_input_if.data = '0;
    rms_input_if.keep = '0;
    rms_input_if.user = '0;
    rms_input_if.valid = 1'b0;
    rms_input_if.last = 1'b0;
    rms_weight_if.data = '0;
    rms_weight_if.keep = '0;
    rms_weight_if.user = '0;
    rms_weight_if.valid = 1'b0;
    rms_weight_if.last = 1'b0;
    rms_output_if.ready = 1'b0;

    attn_query_if.data = '0;
    attn_query_if.keep = '0;
    attn_query_if.user = '0;
    attn_query_if.valid = 1'b0;
    attn_query_if.last = 1'b0;
    attn_key_if.data = '0;
    attn_key_if.keep = '0;
    attn_key_if.user = '0;
    attn_key_if.valid = 1'b0;
    attn_key_if.last = 1'b0;
    attn_value_if.data = '0;
    attn_value_if.keep = '0;
    attn_value_if.user = '0;
    attn_value_if.valid = 1'b0;
    attn_value_if.last = 1'b0;
    attn_context_if.ready = 1'b0;

    mlp_activation_if.data = '0;
    mlp_activation_if.keep = '0;
    mlp_activation_if.user = '0;
    mlp_activation_if.valid = 1'b0;
    mlp_activation_if.last = 1'b0;
    mlp_weight_if.data = '0;
    mlp_weight_if.keep = '0;
    mlp_weight_if.user = '0;
    mlp_weight_if.valid = 1'b0;
    mlp_weight_if.last = 1'b0;
    mlp_output_if.ready = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    run_rmsnorm_crosscheck();
    run_attention_crosscheck();
    run_mlp_crosscheck();

    $display("Gemma 4 BF16 functional cross-check PASS");
    $finish;
  end
endmodule
