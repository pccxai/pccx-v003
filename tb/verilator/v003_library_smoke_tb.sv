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

  tensor_stream_if #(.DATA_W(DataW)) softmax_logits_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) softmax_prob_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) ffn_activation_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) ffn_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) ffn_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) silu_input_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) silu_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) matmul_activation_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) matmul_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) matmul_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) matmul_i8_activation_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) matmul_i8_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) matmul_i8_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) rms_input_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) rms_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) rms_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) gelu_input_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) gelu_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) layernorm_input_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) layernorm_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) layernorm_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) accum_input_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) accum_output_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) argmax_logits_if (.clk(clk), .rst_n(rst_n));
  token_out_if argmax_token_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) topk_logits_if (.clk(clk), .rst_n(rst_n));
  token_out_if topk_token_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) kv_write_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) kv_lookup_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) kv_read_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) arb_req0_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) arb_req1_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) arb_grant_if (.clk(clk), .rst_n(rst_n));

  tensor_stream_if #(.DATA_W(DataW)) xbar_s0_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) xbar_s1_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) xbar_m0_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) xbar_m1_if (.clk(clk), .rst_n(rst_n));

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

  softmax_unit #(.DATA_W(DataW)) u_softmax_unit (
      .clk(clk),
      .rst_n(rst_n),
      .S_LOGITS(softmax_logits_if),
      .M_PROB(softmax_prob_if)
  );

  ffn_core #(.DATA_W(DataW)) u_ffn_core (
      .clk(clk),
      .rst_n(rst_n),
      .S_ACTIVATION(ffn_activation_if),
      .S_WEIGHT(ffn_weight_if),
      .M_ACTIVATION(ffn_output_if)
  );

  silu_unit #(.DATA_W(DataW)) u_silu_unit (
      .clk(clk),
      .rst_n(rst_n),
      .S_INPUT(silu_input_if),
      .M_OUTPUT(silu_output_if)
  );

  matmul_int4_int8 #(.DATA_W(DataW)) u_matmul_int4_int8 (
      .clk(clk),
      .rst_n(rst_n),
      .sparse_meta(sparse_meta),
      .S_ACTIVATION_INT8(matmul_activation_if),
      .S_WEIGHT_INT4(matmul_weight_if),
      .M_ACCUM_INT32(matmul_output_if)
  );

  matmul_int8_int8 #(.DATA_W(DataW)) u_matmul_int8_int8 (
      .clk(clk),
      .rst_n(rst_n),
      .S_ACTIVATION_INT8(matmul_i8_activation_if),
      .S_WEIGHT_INT8(matmul_i8_weight_if),
      .M_ACCUM_INT32(matmul_i8_output_if)
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

  gelu_unit #(.DATA_W(DataW)) u_gelu_unit (
      .clk(clk),
      .rst_n(rst_n),
      .S_INPUT(gelu_input_if),
      .M_OUTPUT(gelu_output_if)
  );

  layernorm_core #(.DATA_W(DataW)) u_layernorm_core (
      .clk(clk),
      .rst_n(rst_n),
      .S_INPUT(layernorm_input_if),
      .S_WEIGHT(layernorm_weight_if),
      .M_OUTPUT(layernorm_output_if)
  );

  accumulator #(.DATA_W(DataW)) u_accumulator (
      .clk(clk),
      .rst_n(rst_n),
      .S_PARTIAL_INT32(accum_input_if),
      .M_SUM_INT32(accum_output_if)
  );

  argmax_unit #(.DATA_W(DataW)) u_argmax_unit (
      .clk(clk),
      .rst_n(rst_n),
      .S_LOGITS(argmax_logits_if),
      .M_TOKEN(argmax_token_if)
  );

  topk_sampler #(
      .DATA_W(DataW),
      .K(2)
  ) u_topk_sampler (
      .clk(clk),
      .rst_n(rst_n),
      .S_LOGITS(topk_logits_if),
      .M_TOKEN(topk_token_if)
  );

  kv_cache_core #(
      .DATA_W(DataW),
      .DEPTH(16)
  ) u_kv_cache_core (
      .clk(clk),
      .rst_n(rst_n),
      .S_KV_WRITE(kv_write_if),
      .S_KV_LOOKUP(kv_lookup_if),
      .M_KV_READ(kv_read_if)
  );

  arbiter #(.DATA_W(DataW)) u_arbiter (
      .clk(clk),
      .rst_n(rst_n),
      .S_REQ0(arb_req0_if),
      .S_REQ1(arb_req1_if),
      .M_GRANT(arb_grant_if)
  );

  crossbar #(.DATA_W(DataW)) u_crossbar (
      .clk(clk),
      .rst_n(rst_n),
      .S_PORT0(xbar_s0_if),
      .S_PORT1(xbar_s1_if),
      .M_PORT0(xbar_m0_if),
      .M_PORT1(xbar_m1_if)
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

  task automatic expect_token(
      input string name,
      input logic [31:0] actual,
      input logic [31:0] expected
  );
    if (actual !== expected) begin
      $fatal(1, "%s expected token 0x%08x got 0x%08x", name, expected, actual);
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

  task automatic run_softmax_smoke;
    softmax_prob_if.ready = 1'b1;
    softmax_logits_if.data = 32'h00000000;
    softmax_logits_if.keep = 4'hf;
    softmax_logits_if.user = 32'h000000a4;
    softmax_logits_if.last = 1'b1;
    softmax_logits_if.valid = 1'b1;

    @(posedge clk);
    #1;
    softmax_logits_if.valid = 1'b0;

    if (!softmax_prob_if.valid) begin
      $fatal(1, "softmax output did not become valid");
    end
    expect_word("softmax", softmax_prob_if.data, 32'h3f3f3f3f);
    expect_word("softmax user", softmax_prob_if.user, 32'h000000a4);
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

  task automatic run_silu_smoke;
    silu_output_if.ready = 1'b1;
    silu_input_if.data = 32'h402000c0;
    silu_input_if.keep = 4'hf;
    silu_input_if.user = 32'h000000b3;
    silu_input_if.last = 1'b1;
    silu_input_if.valid = 1'b1;

    @(posedge clk);
    #1;
    silu_input_if.valid = 1'b0;

    if (!silu_output_if.valid) begin
      $fatal(1, "silu output did not become valid");
    end
    expect_word("silu", silu_output_if.data, 32'h301400f0);
    expect_word("silu user", silu_output_if.user, 32'h000000b3);
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

  task automatic run_matmul_int8_smoke;
    matmul_i8_output_if.ready = 1'b1;
    matmul_i8_activation_if.data = 32'h04fd0201;
    matmul_i8_weight_if.data = 32'h05060708;
    matmul_i8_activation_if.keep = 4'hf;
    matmul_i8_weight_if.keep = 4'hf;
    matmul_i8_activation_if.user = 32'h000000c3;
    matmul_i8_weight_if.user = 32'h000000c4;
    matmul_i8_activation_if.last = 1'b1;
    matmul_i8_weight_if.last = 1'b1;
    matmul_i8_activation_if.valid = 1'b1;
    matmul_i8_weight_if.valid = 1'b1;

    @(posedge clk);
    #1;
    matmul_i8_activation_if.valid = 1'b0;
    matmul_i8_weight_if.valid = 1'b0;

    if (!matmul_i8_output_if.valid) begin
      $fatal(1, "matmul int8 output did not become valid");
    end
    expect_word("matmul int8", matmul_i8_output_if.data, 32'h00000018);
    expect_word("matmul int8 user", matmul_i8_output_if.user, 32'h000000c3);
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

  task automatic run_gelu_smoke;
    gelu_output_if.ready = 1'b1;
    gelu_input_if.data = 32'h402000c0;
    gelu_input_if.keep = 4'hf;
    gelu_input_if.user = 32'h000000e1;
    gelu_input_if.last = 1'b1;
    gelu_input_if.valid = 1'b1;

    @(posedge clk);
    #1;
    gelu_input_if.valid = 1'b0;

    if (!gelu_output_if.valid) begin
      $fatal(1, "gelu output did not become valid");
    end
    expect_word("gelu", gelu_output_if.data, 32'h40180000);
    expect_word("gelu user", gelu_output_if.user, 32'h000000e1);
  endtask

  task automatic run_layernorm_smoke;
    layernorm_output_if.ready = 1'b1;
    layernorm_input_if.data = 32'h03020100;
    layernorm_weight_if.data = 32'h01010101;
    layernorm_input_if.keep = 4'hf;
    layernorm_weight_if.keep = 4'hf;
    layernorm_input_if.user = 32'h000000e2;
    layernorm_weight_if.user = 32'h000000e3;
    layernorm_input_if.last = 1'b1;
    layernorm_weight_if.last = 1'b1;
    layernorm_input_if.valid = 1'b1;
    layernorm_weight_if.valid = 1'b1;

    @(posedge clk);
    #1;
    layernorm_input_if.valid = 1'b0;
    layernorm_weight_if.valid = 1'b0;

    if (!layernorm_output_if.valid) begin
      $fatal(1, "layernorm output did not become valid");
    end
    expect_word("layernorm", layernorm_output_if.data, 32'h020100ff);
    expect_word("layernorm user", layernorm_output_if.user, 32'h000000e2);
  endtask

  task automatic run_accumulator_smoke;
    accum_output_if.ready = 1'b1;
    accum_input_if.data = 32'h00000001;
    accum_input_if.keep = 4'hf;
    accum_input_if.user = 32'h000000e4;
    accum_input_if.last = 1'b0;
    accum_input_if.valid = 1'b1;

    @(posedge clk);
    #1;
    if (accum_output_if.valid) begin
      $fatal(1, "accumulator emitted before last");
    end

    accum_input_if.data = 32'h00000002;
    accum_input_if.last = 1'b1;
    @(posedge clk);
    #1;
    accum_input_if.valid = 1'b0;

    if (!accum_output_if.valid) begin
      $fatal(1, "accumulator output did not become valid");
    end
    expect_word("accumulator", accum_output_if.data, 32'h00000003);
    expect_word("accumulator user", accum_output_if.user, 32'h000000e4);
  endtask

  task automatic run_sampling_smoke;
    argmax_token_if.ready = 1'b1;
    topk_token_if.ready = 1'b1;
    argmax_logits_if.data = 32'h7f1080ff;
    topk_logits_if.data = 32'h7f1080ff;
    argmax_logits_if.keep = 4'hf;
    topk_logits_if.keep = 4'hf;
    argmax_logits_if.user = 32'h000000e5;
    topk_logits_if.user = 32'h000000e6;
    argmax_logits_if.last = 1'b1;
    topk_logits_if.last = 1'b1;
    argmax_logits_if.valid = 1'b1;
    topk_logits_if.valid = 1'b1;

    @(posedge clk);
    #1;
    argmax_logits_if.valid = 1'b0;
    topk_logits_if.valid = 1'b0;

    if (!argmax_token_if.valid || !topk_token_if.valid) begin
      $fatal(1, "sampling outputs did not become valid");
    end
    expect_token("argmax", argmax_token_if.token, 32'h00000003);
    expect_token("topk", topk_token_if.token, 32'h00000003);
    expect_token("argmax sequence", argmax_token_if.sequence_id, 32'h000000e5);
    expect_token("topk sequence", topk_token_if.sequence_id, 32'h000000e6);
  endtask

  task automatic run_kv_cache_smoke;
    kv_read_if.ready = 1'b1;
    kv_write_if.data = 32'hcafebeef;
    kv_write_if.keep = 4'hf;
    kv_write_if.user = 32'h00000002;
    kv_write_if.last = 1'b1;
    kv_write_if.valid = 1'b1;

    @(posedge clk);
    #1;
    kv_write_if.valid = 1'b0;

    kv_lookup_if.data = '0;
    kv_lookup_if.keep = '0;
    kv_lookup_if.user = 32'h00000002;
    kv_lookup_if.last = 1'b1;
    kv_lookup_if.valid = 1'b1;

    @(posedge clk);
    #1;
    kv_lookup_if.valid = 1'b0;

    if (!kv_read_if.valid) begin
      $fatal(1, "kv cache output did not become valid");
    end
    expect_word("kv cache", kv_read_if.data, 32'hcafebeef);
    expect_word("kv cache user", kv_read_if.user, 32'h00000002);
  endtask

  task automatic run_interconnect_smoke;
    arb_grant_if.ready = 1'b1;
    arb_req0_if.data = 32'h000000a0;
    arb_req1_if.data = 32'h000000b0;
    arb_req0_if.keep = 4'hf;
    arb_req1_if.keep = 4'hf;
    arb_req0_if.user = 32'h000000f0;
    arb_req1_if.user = 32'h000000f1;
    arb_req0_if.last = 1'b1;
    arb_req1_if.last = 1'b1;
    arb_req0_if.valid = 1'b1;
    arb_req1_if.valid = 1'b1;

    @(posedge clk);
    #1;
    arb_req0_if.valid = 1'b0;
    arb_req1_if.valid = 1'b0;

    if (!arb_grant_if.valid) begin
      $fatal(1, "arbiter output did not become valid");
    end
    expect_word("arbiter", arb_grant_if.data, 32'h000000a0);

    xbar_m0_if.ready = 1'b1;
    xbar_m1_if.ready = 1'b1;
    xbar_s0_if.data = 32'h000000c0;
    xbar_s1_if.data = 32'h000000d0;
    xbar_s0_if.keep = 4'hf;
    xbar_s1_if.keep = 4'hf;
    xbar_s0_if.user = 32'h00000000;
    xbar_s1_if.user = 32'h00000001;
    xbar_s0_if.last = 1'b1;
    xbar_s1_if.last = 1'b1;
    xbar_s0_if.valid = 1'b1;
    xbar_s1_if.valid = 1'b1;

    @(posedge clk);
    #1;
    xbar_s0_if.valid = 1'b0;
    xbar_s1_if.valid = 1'b0;

    if (!xbar_m0_if.valid || !xbar_m1_if.valid) begin
      $fatal(1, "crossbar outputs did not become valid");
    end
    expect_word("crossbar port0", xbar_m0_if.data, 32'h000000c0);
    expect_word("crossbar port1", xbar_m1_if.data, 32'h000000d0);
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
    softmax_logits_if.data = '0;
    softmax_logits_if.keep = '0;
    softmax_logits_if.user = '0;
    softmax_logits_if.valid = 1'b0;
    softmax_logits_if.last = 1'b0;
    softmax_prob_if.ready = 1'b0;
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
    silu_input_if.data = '0;
    silu_input_if.keep = '0;
    silu_input_if.user = '0;
    silu_input_if.valid = 1'b0;
    silu_input_if.last = 1'b0;
    silu_output_if.ready = 1'b0;
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
    matmul_i8_activation_if.data = '0;
    matmul_i8_activation_if.keep = '0;
    matmul_i8_activation_if.user = '0;
    matmul_i8_activation_if.valid = 1'b0;
    matmul_i8_activation_if.last = 1'b0;
    matmul_i8_weight_if.data = '0;
    matmul_i8_weight_if.keep = '0;
    matmul_i8_weight_if.user = '0;
    matmul_i8_weight_if.valid = 1'b0;
    matmul_i8_weight_if.last = 1'b0;
    matmul_i8_output_if.ready = 1'b0;
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
    gelu_input_if.data = '0;
    gelu_input_if.keep = '0;
    gelu_input_if.user = '0;
    gelu_input_if.valid = 1'b0;
    gelu_input_if.last = 1'b0;
    gelu_output_if.ready = 1'b0;
    layernorm_input_if.data = '0;
    layernorm_input_if.keep = '0;
    layernorm_input_if.user = '0;
    layernorm_input_if.valid = 1'b0;
    layernorm_input_if.last = 1'b0;
    layernorm_weight_if.data = '0;
    layernorm_weight_if.keep = '0;
    layernorm_weight_if.user = '0;
    layernorm_weight_if.valid = 1'b0;
    layernorm_weight_if.last = 1'b0;
    layernorm_output_if.ready = 1'b0;
    accum_input_if.data = '0;
    accum_input_if.keep = '0;
    accum_input_if.user = '0;
    accum_input_if.valid = 1'b0;
    accum_input_if.last = 1'b0;
    accum_output_if.ready = 1'b0;
    argmax_logits_if.data = '0;
    argmax_logits_if.keep = '0;
    argmax_logits_if.user = '0;
    argmax_logits_if.valid = 1'b0;
    argmax_logits_if.last = 1'b0;
    argmax_token_if.ready = 1'b0;
    topk_logits_if.data = '0;
    topk_logits_if.keep = '0;
    topk_logits_if.user = '0;
    topk_logits_if.valid = 1'b0;
    topk_logits_if.last = 1'b0;
    topk_token_if.ready = 1'b0;
    kv_write_if.data = '0;
    kv_write_if.keep = '0;
    kv_write_if.user = '0;
    kv_write_if.valid = 1'b0;
    kv_write_if.last = 1'b0;
    kv_lookup_if.data = '0;
    kv_lookup_if.keep = '0;
    kv_lookup_if.user = '0;
    kv_lookup_if.valid = 1'b0;
    kv_lookup_if.last = 1'b0;
    kv_read_if.ready = 1'b0;
    arb_req0_if.data = '0;
    arb_req0_if.keep = '0;
    arb_req0_if.user = '0;
    arb_req0_if.valid = 1'b0;
    arb_req0_if.last = 1'b0;
    arb_req1_if.data = '0;
    arb_req1_if.keep = '0;
    arb_req1_if.user = '0;
    arb_req1_if.valid = 1'b0;
    arb_req1_if.last = 1'b0;
    arb_grant_if.ready = 1'b0;
    xbar_s0_if.data = '0;
    xbar_s0_if.keep = '0;
    xbar_s0_if.user = '0;
    xbar_s0_if.valid = 1'b0;
    xbar_s0_if.last = 1'b0;
    xbar_s1_if.data = '0;
    xbar_s1_if.keep = '0;
    xbar_s1_if.user = '0;
    xbar_s1_if.valid = 1'b0;
    xbar_s1_if.last = 1'b0;
    xbar_m0_if.ready = 1'b0;
    xbar_m1_if.ready = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    run_attention_smoke();
    @(posedge clk);
    run_softmax_smoke();
    @(posedge clk);
    run_ffn_smoke();
    @(posedge clk);
    run_silu_smoke();
    @(posedge clk);
    run_matmul_smoke();
    @(posedge clk);
    run_matmul_int8_smoke();
    @(posedge clk);
    run_rmsnorm_smoke();
    @(posedge clk);
    run_gelu_smoke();
    @(posedge clk);
    run_layernorm_smoke();
    @(posedge clk);
    run_accumulator_smoke();
    @(posedge clk);
    run_sampling_smoke();
    @(posedge clk);
    run_kv_cache_smoke();
    @(posedge clk);
    run_interconnect_smoke();

    $display("v003 library smoke PASS");
    $finish;
  end
endmodule
