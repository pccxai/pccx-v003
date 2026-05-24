import bf16_lane_pkg::*;

module bf16_rmsnorm_core #(
    parameter int DATA_W = 256,
    parameter logic [15:0] INV_RMS_BF16 = 16'h3f80
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_INPUT,
    tensor_stream_if.consumer S_WEIGHT,
    tensor_stream_if.producer M_OUTPUT
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int LaneCount = DATA_W / 16;

  logic [DATA_W-1:0]     output_data_q;
  logic [(DATA_W/8)-1:0] output_keep_q;
  logic [31:0]           output_user_q;
  logic                  output_valid_q;
  logic                  output_last_q;

  wire output_fire = output_valid_q && M_OUTPUT.ready;
  wire core_ready = !output_valid_q || M_OUTPUT.ready;
  wire input_fire = core_ready && S_INPUT.valid && S_WEIGHT.valid;

  assign S_INPUT.ready = core_ready && S_WEIGHT.valid;
  assign S_WEIGHT.ready = core_ready && S_INPUT.valid;

  assign M_OUTPUT.data = output_data_q;
  assign M_OUTPUT.keep = output_keep_q;
  assign M_OUTPUT.user = output_user_q;
  assign M_OUTPUT.valid = output_valid_q;
  assign M_OUTPUT.last = output_last_q;

  function automatic logic [DATA_W-1:0] apply_rmsnorm(
      input logic [DATA_W-1:0] input_data,
      input logic [DATA_W-1:0] weight_data,
      input logic [(DATA_W/8)-1:0] input_keep,
      input logic [(DATA_W/8)-1:0] weight_keep
  );
    logic [DATA_W-1:0] result;
    logic [15:0] scaled_lane;

    result = '0;
    for (int lane = 0; lane < LaneCount; lane++) begin
      int low_byte;
      int high_byte;

      low_byte = lane * 2;
      high_byte = low_byte + 1;
      if (input_keep[low_byte] && input_keep[high_byte] &&
          weight_keep[low_byte] && weight_keep[high_byte]) begin
        scaled_lane = bf16_mul(input_data[(lane * 16) +: 16], INV_RMS_BF16);
        result[(lane * 16) +: 16] = bf16_mul(scaled_lane, weight_data[(lane * 16) +: 16]);
      end
    end

    apply_rmsnorm = result;
  endfunction

  function automatic logic [(DATA_W/8)-1:0] lane_keep(
      input logic [(DATA_W/8)-1:0] input_keep,
      input logic [(DATA_W/8)-1:0] weight_keep
  );
    logic [(DATA_W/8)-1:0] result;

    result = '0;
    for (int lane = 0; lane < LaneCount; lane++) begin
      int low_byte;
      int high_byte;

      low_byte = lane * 2;
      high_byte = low_byte + 1;
      if (input_keep[low_byte] && input_keep[high_byte] &&
          weight_keep[low_byte] && weight_keep[high_byte]) begin
        result[low_byte] = 1'b1;
        result[high_byte] = 1'b1;
      end
    end

    lane_keep = result;
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
        output_data_q <= apply_rmsnorm(
            S_INPUT.data,
            S_WEIGHT.data,
            S_INPUT.keep,
            S_WEIGHT.keep
        );
        output_keep_q  <= lane_keep(S_INPUT.keep, S_WEIGHT.keep);
        output_user_q  <= S_INPUT.user;
        output_valid_q <= 1'b1;
        output_last_q  <= S_INPUT.last & S_WEIGHT.last;
      end
    end
  end
endmodule
