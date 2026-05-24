import bf16_lane_pkg::*;

module bf16_rope_unit #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_INPUT,
    tensor_stream_if.consumer S_ROTATION,
    tensor_stream_if.producer M_OUTPUT
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int LaneCount = DATA_W / 16;
  localparam int PairCount = LaneCount / 2;

  logic [DATA_W-1:0]     output_data_q;
  logic [(DATA_W/8)-1:0] output_keep_q;
  logic [31:0]           output_user_q;
  logic                  output_valid_q;
  logic                  output_last_q;

  wire output_fire = output_valid_q && M_OUTPUT.ready;
  wire core_ready = !output_valid_q || M_OUTPUT.ready;
  wire input_fire = core_ready && S_INPUT.valid && S_ROTATION.valid;

  assign S_INPUT.ready = core_ready && S_ROTATION.valid;
  assign S_ROTATION.ready = core_ready && S_INPUT.valid;

  assign M_OUTPUT.data = output_data_q;
  assign M_OUTPUT.keep = output_keep_q;
  assign M_OUTPUT.user = output_user_q;
  assign M_OUTPUT.valid = output_valid_q;
  assign M_OUTPUT.last = output_last_q;

  function automatic logic [DATA_W-1:0] rotate_pairs(
      input logic [DATA_W-1:0] input_data,
      input logic [DATA_W-1:0] rotation_data,
      input logic [(DATA_W/8)-1:0] input_keep,
      input logic [(DATA_W/8)-1:0] rotation_keep
  );
    logic [DATA_W-1:0] result;
    logic [15:0] x_even;
    logic [15:0] x_odd;
    logic [15:0] cos_lane;
    logic [15:0] sin_lane;

    result = '0;
    for (int pair = 0; pair < PairCount; pair++) begin
      int even_lane;
      int odd_lane;
      int even_byte;
      int odd_byte;

      even_lane = pair * 2;
      odd_lane = even_lane + 1;
      even_byte = even_lane * 2;
      odd_byte = odd_lane * 2;
      if (input_keep[even_byte] && input_keep[even_byte + 1] &&
          input_keep[odd_byte] && input_keep[odd_byte + 1] &&
          rotation_keep[even_byte] && rotation_keep[even_byte + 1] &&
          rotation_keep[odd_byte] && rotation_keep[odd_byte + 1]) begin
        x_even = input_data[(even_lane * 16) +: 16];
        x_odd = input_data[(odd_lane * 16) +: 16];
        cos_lane = rotation_data[(even_lane * 16) +: 16];
        sin_lane = rotation_data[(odd_lane * 16) +: 16];
        result[(even_lane * 16) +: 16] =
            bf16_sub(bf16_mul(x_even, cos_lane), bf16_mul(x_odd, sin_lane));
        result[(odd_lane * 16) +: 16] =
            bf16_add(bf16_mul(x_even, sin_lane), bf16_mul(x_odd, cos_lane));
      end
    end

    rotate_pairs = result;
  endfunction

  function automatic logic [(DATA_W/8)-1:0] rotate_keep(
      input logic [(DATA_W/8)-1:0] input_keep,
      input logic [(DATA_W/8)-1:0] rotation_keep
  );
    logic [(DATA_W/8)-1:0] result;

    result = '0;
    for (int pair = 0; pair < PairCount; pair++) begin
      int even_lane;
      int odd_lane;
      int even_byte;
      int odd_byte;

      even_lane = pair * 2;
      odd_lane = even_lane + 1;
      even_byte = even_lane * 2;
      odd_byte = odd_lane * 2;
      if (input_keep[even_byte] && input_keep[even_byte + 1] &&
          input_keep[odd_byte] && input_keep[odd_byte + 1] &&
          rotation_keep[even_byte] && rotation_keep[even_byte + 1] &&
          rotation_keep[odd_byte] && rotation_keep[odd_byte + 1]) begin
        result[even_byte] = 1'b1;
        result[even_byte + 1] = 1'b1;
        result[odd_byte] = 1'b1;
        result[odd_byte + 1] = 1'b1;
      end
    end

    rotate_keep = result;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      output_data_q  <= '0;
      output_keep_q  <= '0;
      output_user_q  <= '0;
      output_valid_q <= 1'b0;
      output_last_q  <= 1'b0;
    end else begin
      if (output_fire) begin
        output_valid_q <= 1'b0;
      end

      if (input_fire) begin
        output_data_q <= rotate_pairs(
            S_INPUT.data,
            S_ROTATION.data,
            S_INPUT.keep,
            S_ROTATION.keep
        );
        output_keep_q  <= rotate_keep(S_INPUT.keep, S_ROTATION.keep);
        output_user_q  <= S_INPUT.user;
        output_valid_q <= 1'b1;
        output_last_q  <= S_INPUT.last & S_ROTATION.last;
      end
    end
  end
endmodule
