module gemma4_attention_slice #(
    parameter int DATA_W = 256,
    parameter int HEADS = 8,
    parameter int KV_HEADS = 2,
    parameter int WINDOW_TOKENS = 0
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_QUERY,
    tensor_stream_if.consumer S_KEY,
    tensor_stream_if.consumer S_VALUE,
    tensor_stream_if.consumer S_QUERY_ROTATION,
    tensor_stream_if.consumer S_KEY_ROTATION,
    tensor_stream_if.producer M_CONTEXT
);
  timeunit 1ns;
  timeprecision 1ps;

  tensor_stream_if #(.DATA_W(DATA_W)) q_rope_if (
      .clk  (clk),
      .rst_n(rst_n)
  );
  tensor_stream_if #(.DATA_W(DATA_W)) k_rope_if (
      .clk  (clk),
      .rst_n(rst_n)
  );

  rope_unit #(.DATA_W(DATA_W)) u_query_rope (
      .clk(clk),
      .rst_n(rst_n),
      .S_INPUT(S_QUERY),
      .S_ROTATION(S_QUERY_ROTATION),
      .M_OUTPUT(q_rope_if)
  );

  rope_unit #(.DATA_W(DATA_W)) u_key_rope (
      .clk(clk),
      .rst_n(rst_n),
      .S_INPUT(S_KEY),
      .S_ROTATION(S_KEY_ROTATION),
      .M_OUTPUT(k_rope_if)
  );

  mha_sliding_window_core #(
      .DATA_W(DATA_W),
      .HEADS(HEADS),
      .KV_HEADS(KV_HEADS),
      .WINDOW_TOKENS(WINDOW_TOKENS)
  ) u_mha (
      .clk(clk),
      .rst_n(rst_n),
      .S_QUERY(q_rope_if),
      .S_KEY(k_rope_if),
      .S_VALUE(S_VALUE),
      .M_CONTEXT(M_CONTEXT)
  );
endmodule
