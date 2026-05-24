import bf16_lane_pkg::*;

module bf16_attention_core #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_QUERY,
    tensor_stream_if.consumer S_KEY,
    tensor_stream_if.consumer S_VALUE,
    tensor_stream_if.producer M_CONTEXT
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int LaneCount = DATA_W / 16;

  logic [DATA_W-1:0]      context_data_q;
  logic [(DATA_W/8)-1:0]  context_keep_q;
  logic [31:0]            context_user_q;
  logic                   context_valid_q;
  logic                   context_last_q;

  wire output_fire = context_valid_q && M_CONTEXT.ready;
  wire core_ready = !context_valid_q || M_CONTEXT.ready;
  wire input_fire = core_ready && S_QUERY.valid && S_KEY.valid && S_VALUE.valid;

  assign S_QUERY.ready = core_ready && S_KEY.valid && S_VALUE.valid;
  assign S_KEY.ready = core_ready && S_QUERY.valid && S_VALUE.valid;
  assign S_VALUE.ready = core_ready && S_QUERY.valid && S_KEY.valid;

  assign M_CONTEXT.data = context_data_q;
  assign M_CONTEXT.keep = context_keep_q;
  assign M_CONTEXT.user = context_user_q;
  assign M_CONTEXT.valid = context_valid_q;
  assign M_CONTEXT.last = context_last_q;

  function automatic logic [DATA_W-1:0] apply_attention(
      input logic [DATA_W-1:0] query_data,
      input logic [DATA_W-1:0] key_data,
      input logic [DATA_W-1:0] value_data,
      input logic [(DATA_W/8)-1:0] query_keep,
      input logic [(DATA_W/8)-1:0] key_keep,
      input logic [(DATA_W/8)-1:0] value_keep
  );
    logic [DATA_W-1:0] result;
    logic [15:0] score;
    logic [15:0] value_lane;

    result = '0;
    for (int lane = 0; lane < LaneCount; lane++) begin
      int low_byte;
      int high_byte;

      low_byte = lane * 2;
      high_byte = low_byte + 1;
      if (query_keep[low_byte] && query_keep[high_byte] &&
          key_keep[low_byte] && key_keep[high_byte] &&
          value_keep[low_byte] && value_keep[high_byte]) begin
        score = bf16_mul(
            query_data[(lane * 16) +: 16],
            key_data[(lane * 16) +: 16]
        );
        value_lane = value_data[(lane * 16) +: 16];
        result[(lane * 16) +: 16] = bf16_mul(score, value_lane);
      end
    end

    apply_attention = result;
  endfunction

  function automatic logic [(DATA_W/8)-1:0] lane_keep(
      input logic [(DATA_W/8)-1:0] query_keep,
      input logic [(DATA_W/8)-1:0] key_keep,
      input logic [(DATA_W/8)-1:0] value_keep
  );
    logic [(DATA_W/8)-1:0] result;

    result = '0;
    for (int lane = 0; lane < LaneCount; lane++) begin
      int low_byte;
      int high_byte;

      low_byte = lane * 2;
      high_byte = low_byte + 1;
      if (query_keep[low_byte] && query_keep[high_byte] &&
          key_keep[low_byte] && key_keep[high_byte] &&
          value_keep[low_byte] && value_keep[high_byte]) begin
        result[low_byte] = 1'b1;
        result[high_byte] = 1'b1;
      end
    end

    lane_keep = result;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      context_data_q  <= '0;
      context_keep_q  <= '0;
      context_user_q  <= '0;
      context_valid_q <= 1'b0;
      context_last_q  <= 1'b0;
    end else begin
      if (output_fire) begin
        context_valid_q <= 1'b0;
      end

      if (input_fire) begin
        context_data_q <= apply_attention(
            S_QUERY.data,
            S_KEY.data,
            S_VALUE.data,
            S_QUERY.keep,
            S_KEY.keep,
            S_VALUE.keep
        );
        context_keep_q  <= lane_keep(S_QUERY.keep, S_KEY.keep, S_VALUE.keep);
        context_user_q  <= S_QUERY.user;
        context_valid_q <= 1'b1;
        context_last_q  <= S_QUERY.last & S_KEY.last & S_VALUE.last;
      end
    end
  end
endmodule
