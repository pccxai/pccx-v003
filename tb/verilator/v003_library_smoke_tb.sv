module v003_library_smoke_tb;
  timeunit 1ns;
  timeprecision 1ps;

  localparam int DataW = 32;

  logic clk;
  logic rst_n;

  npu_common_pkg::npu_sparse_meta_t sparse_meta;

  tensor_stream_if #(.DATA_W(DataW)) attn_query_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) attn_key_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) attn_value_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) attn_context_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) ffn_activation_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) ffn_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) ffn_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) matmul_activation_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) matmul_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) matmul_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) rms_input_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) rms_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) rms_output_if (.clk(clk), .rst_n(rst_n));

  attention_core #(
      .DATA_W(DataW),
      .SCORE_SCALE_SHIFT(5)
  ) u_attention_core (
      .clk(clk),
      .rst_n(rst_n),
      .S_QUERY(attn_query_if),
      .S_KEY(attn_key_if),
      .S_VALUE(attn_value_if),
      .M_CONTEXT(attn_context_if)
  );

  ffn_core #(.DATA_W(DataW)) u_ffn_core (
      .clk(clk),
      .rst_n(rst_n),
      .S_ACTIVATION(ffn_activation_if),
      .S_WEIGHT(ffn_weight_if),
      .M_ACTIVATION(ffn_output_if)
  );

  matmul_int4_int8 #(.DATA_W(DataW)) u_matmul_int4_int8 (
      .clk(clk),
      .rst_n(rst_n),
      .sparse_meta(sparse_meta),
      .S_ACTIVATION_INT8(matmul_activation_if),
      .S_WEIGHT_INT4(matmul_weight_if),
      .M_ACCUM_INT32(matmul_output_if)
  );

  rmsnorm_core #(
      .DATA_W(DataW),
      .EPSILON(0)
  ) u_rmsnorm_core (
      .clk(clk),
      .rst_n(rst_n),
      .S_INPUT(rms_input_if),
      .S_WEIGHT(rms_weight_if),
      .M_OUTPUT(rms_output_if)
  );

  always #5 clk = !clk;

  task automatic expect_word(
      input string name,
      input logic [DataW-1:0] actual,
      input logic [DataW-1:0] expected
  );
    if (actual !== expected) begin
      $fatal(1, "%s expected 0x%08x got 0x%08x", name, expected, actual);
    end
  endtask

  task automatic run_attention_smoke;
    attn_context_if.ready = 1'b1;
    attn_query_if.data = 32'h01010101;
    attn_key_if.data = 32'h01010101;
    attn_value_if.data = 32'he020c040;
    attn_query_if.keep = 4'hf;
    attn_key_if.keep = 4'hf;
    attn_value_if.keep = 4'hf;
    attn_query_if.user = 32'h000000a1;
    attn_key_if.user = 32'h000000a2;
    attn_value_if.user = 32'h000000a3;
    attn_query_if.last = 1'b1;
    attn_key_if.last = 1'b1;
    attn_value_if.last = 1'b1;
    attn_query_if.valid = 1'b1;
    attn_key_if.valid = 1'b1;
    attn_value_if.valid = 1'b1;

    @(posedge clk);
    #1;
    attn_query_if.valid = 1'b0;
    attn_key_if.valid = 1'b0;
    attn_value_if.valid = 1'b0;

    if (!attn_context_if.valid) begin
      $fatal(1, "attention output did not become valid");
    end
    expect_word("attention", attn_context_if.data, 32'he01fc03f);
    expect_word("attention user", attn_context_if.user, 32'h000000a1);
  endtask

  task automatic run_ffn_smoke;
    ffn_output_if.ready = 1'b1;
    ffn_activation_if.data = 32'hf010f808;
    ffn_weight_if.data = 32'hf8f80808;
    ffn_activation_if.keep = 4'hf;
    ffn_weight_if.keep = 4'hf;
    ffn_activation_if.user = 32'h000000b1;
    ffn_weight_if.user = 32'h000000b2;
    ffn_activation_if.last = 1'b1;
    ffn_weight_if.last = 1'b1;
    ffn_activation_if.valid = 1'b1;
    ffn_weight_if.valid = 1'b1;

    @(posedge clk);
    #1;
    ffn_activation_if.valid = 1'b0;
    ffn_weight_if.valid = 1'b0;

    if (!ffn_output_if.valid) begin
      $fatal(1, "ffn output did not become valid");
    end
    expect_word("ffn", ffn_output_if.data, 32'h02000001);
    expect_word("ffn user", ffn_output_if.user, 32'h000000b1);
  endtask

  task automatic run_matmul_smoke;
    matmul_output_if.ready = 1'b1;
    sparse_meta.mode = npu_common_pkg::NPU_SPARSE_DENSE;
    sparse_meta.mask = '1;
    sparse_meta.group_size = 8'd0;
    matmul_activation_if.data = 32'h04fd0201;
    matmul_weight_if.data = 32'h0000c3e1;
    matmul_activation_if.keep = 4'hf;
    matmul_weight_if.keep = 4'hf;
    matmul_activation_if.user = 32'h000000c1;
    matmul_weight_if.user = 32'h000000c2;
    matmul_activation_if.last = 1'b1;
    matmul_weight_if.last = 1'b1;
    matmul_activation_if.valid = 1'b1;
    matmul_weight_if.valid = 1'b1;

    @(posedge clk);
    #1;
    matmul_activation_if.valid = 1'b0;
    matmul_weight_if.valid = 1'b0;

    if (!matmul_output_if.valid) begin
      $fatal(1, "matmul output did not become valid");
    end
    expect_word("matmul", matmul_output_if.data, 32'hffffffe4);
    expect_word("matmul user", matmul_output_if.user, 32'h000000c1);
  endtask

  task automatic run_rmsnorm_smoke;
    rms_output_if.ready = 1'b1;
    rms_input_if.data = 32'h00000403;
    rms_weight_if.data = 32'h02020202;
    rms_input_if.keep = 4'hf;
    rms_weight_if.keep = 4'hf;
    rms_input_if.user = 32'h000000d1;
    rms_weight_if.user = 32'h000000d2;
    rms_input_if.last = 1'b1;
    rms_weight_if.last = 1'b1;
    rms_input_if.valid = 1'b1;
    rms_weight_if.valid = 1'b1;

    @(posedge clk);
    #1;
    rms_input_if.valid = 1'b0;
    rms_weight_if.valid = 1'b0;

    if (!rms_output_if.valid) begin
      $fatal(1, "rmsnorm output did not become valid");
    end
    expect_word("rmsnorm", rms_output_if.data, 32'h00000403);
    expect_word("rmsnorm user", rms_output_if.user, 32'h000000d1);
  endtask

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    sparse_meta = '0;

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
    ffn_activation_if.data = '0;
    ffn_activation_if.keep = '0;
    ffn_activation_if.user = '0;
    ffn_activation_if.valid = 1'b0;
    ffn_activation_if.last = 1'b0;
    ffn_weight_if.data = '0;
    ffn_weight_if.keep = '0;
    ffn_weight_if.user = '0;
    ffn_weight_if.valid = 1'b0;
    ffn_weight_if.last = 1'b0;
    ffn_output_if.ready = 1'b0;
    matmul_activation_if.data = '0;
    matmul_activation_if.keep = '0;
    matmul_activation_if.user = '0;
    matmul_activation_if.valid = 1'b0;
    matmul_activation_if.last = 1'b0;
    matmul_weight_if.data = '0;
    matmul_weight_if.keep = '0;
    matmul_weight_if.user = '0;
    matmul_weight_if.valid = 1'b0;
    matmul_weight_if.last = 1'b0;
    matmul_output_if.ready = 1'b0;
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

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    run_attention_smoke();
    @(posedge clk);
    run_ffn_smoke();
    @(posedge clk);
    run_matmul_smoke();
    @(posedge clk);
    run_rmsnorm_smoke();

    $display("v003 library smoke PASS");
    $finish;
  end
endmodule
