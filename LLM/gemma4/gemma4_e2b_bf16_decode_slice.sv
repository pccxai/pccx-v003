module gemma4_e2b_bf16_decode_slice #(
    parameter int DATA_W = 256,
    parameter int TOKEN_W = 32,
    parameter int SEQUENCE_W = 32
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_EMBEDDING,
    tensor_stream_if.consumer S_RMS_WEIGHT,
    tensor_stream_if.consumer S_ROPE_ROTATION,
    tensor_stream_if.consumer S_KV_WRITE,
    tensor_stream_if.consumer S_KV_LOOKUP,
    tensor_stream_if.consumer S_VALUE,
    tensor_stream_if.consumer S_MLP_WEIGHT,
    token_out_if.producer M_TOKEN
);
  timeunit 1ns;
  timeprecision 1ps;

  tensor_stream_if #(.DATA_W(DATA_W)) rms_out_if (
      .clk  (clk),
      .rst_n(rst_n)
  );
  tensor_stream_if #(.DATA_W(DATA_W)) rope_out_if (
      .clk  (clk),
      .rst_n(rst_n)
  );
  tensor_stream_if #(.DATA_W(DATA_W)) kv_read_if (
      .clk  (clk),
      .rst_n(rst_n)
  );
  tensor_stream_if #(.DATA_W(DATA_W)) attn_out_if (
      .clk  (clk),
      .rst_n(rst_n)
  );
  tensor_stream_if #(.DATA_W(DATA_W)) mlp_out_if (
      .clk  (clk),
      .rst_n(rst_n)
  );

  bf16_rmsnorm_core #(.DATA_W(DATA_W)) u_rmsnorm (
      .clk(clk),
      .rst_n(rst_n),
      .S_INPUT(S_EMBEDDING),
      .S_WEIGHT(S_RMS_WEIGHT),
      .M_OUTPUT(rms_out_if)
  );

  bf16_rope_unit #(.DATA_W(DATA_W)) u_rope (
      .clk(clk),
      .rst_n(rst_n),
      .S_INPUT(rms_out_if),
      .S_ROTATION(S_ROPE_ROTATION),
      .M_OUTPUT(rope_out_if)
  );

  kv_cache_core #(
      .DATA_W(DATA_W),
      .DEPTH(64)
  ) u_kv_cache (
      .clk(clk),
      .rst_n(rst_n),
      .S_KV_WRITE(S_KV_WRITE),
      .S_KV_LOOKUP(S_KV_LOOKUP),
      .M_KV_READ(kv_read_if)
  );

  bf16_attention_core #(.DATA_W(DATA_W)) u_attention (
      .clk(clk),
      .rst_n(rst_n),
      .S_QUERY(rope_out_if),
      .S_KEY(kv_read_if),
      .S_VALUE(S_VALUE),
      .M_CONTEXT(attn_out_if)
  );

  bf16_mlp_core #(.DATA_W(DATA_W)) u_mlp (
      .clk(clk),
      .rst_n(rst_n),
      .S_ACTIVATION(attn_out_if),
      .S_WEIGHT(S_MLP_WEIGHT),
      .M_ACTIVATION(mlp_out_if)
  );

  assign mlp_out_if.ready = M_TOKEN.ready;
  assign M_TOKEN.valid = mlp_out_if.valid;
  assign M_TOKEN.last = mlp_out_if.last;
  assign M_TOKEN.sequence_id = mlp_out_if.user[SEQUENCE_W-1:0];
  assign M_TOKEN.token = mlp_out_if.data[TOKEN_W-1:0];
endmodule
