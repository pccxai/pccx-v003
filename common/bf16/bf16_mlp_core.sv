import bf16_lane_pkg::*;

module bf16_mlp_core #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_ACTIVATION,
    tensor_stream_if.consumer S_WEIGHT,
    tensor_stream_if.producer M_ACTIVATION
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int LaneCount = DATA_W / 16;

  logic [DATA_W-1:0]     activation_data_q;
  logic [(DATA_W/8)-1:0] activation_keep_q;
  logic [31:0]           activation_user_q;
  logic                  activation_valid_q;
  logic                  activation_last_q;

  wire output_fire = activation_valid_q && M_ACTIVATION.ready;
  wire core_ready = !activation_valid_q || M_ACTIVATION.ready;
  wire input_fire = core_ready && S_ACTIVATION.valid && S_WEIGHT.valid;

  assign S_ACTIVATION.ready = core_ready && S_WEIGHT.valid;
  assign S_WEIGHT.ready = core_ready && S_ACTIVATION.valid;

  assign M_ACTIVATION.data = activation_data_q;
  assign M_ACTIVATION.keep = activation_keep_q;
  assign M_ACTIVATION.user = activation_user_q;
  assign M_ACTIVATION.valid = activation_valid_q;
  assign M_ACTIVATION.last = activation_last_q;

  function automatic logic [DATA_W-1:0] apply_mlp(
      input logic [DATA_W-1:0] input_data,
      input logic [DATA_W-1:0] weight_data,
      input logic [(DATA_W/8)-1:0] input_keep,
      input logic [(DATA_W/8)-1:0] weight_keep
  );
    logic [DATA_W-1:0] result;

    result = '0;
    for (int lane = 0; lane < LaneCount; lane++) begin
      int low_byte;
      int high_byte;

      low_byte = lane * 2;
      high_byte = low_byte + 1;
      if (input_keep[low_byte] && input_keep[high_byte] &&
          weight_keep[low_byte] && weight_keep[high_byte]) begin
        result[(lane * 16) +: 16] = bf16_relu(
            bf16_mul(input_data[(lane * 16) +: 16], weight_data[(lane * 16) +: 16])
        );
      end
    end

    apply_mlp = result;
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
      activation_data_q  <= '0;
      activation_keep_q  <= '0;
      activation_user_q  <= '0;
      activation_valid_q <= 1'b0;
      activation_last_q  <= 1'b0;
    end else begin
      if (output_fire) begin
        activation_valid_q <= 1'b0;
      end

      if (input_fire) begin
        activation_data_q <= apply_mlp(
            S_ACTIVATION.data,
            S_WEIGHT.data,
            S_ACTIVATION.keep,
            S_WEIGHT.keep
        );
        activation_keep_q  <= lane_keep(S_ACTIVATION.keep, S_WEIGHT.keep);
        activation_user_q  <= S_ACTIVATION.user;
        activation_valid_q <= 1'b1;
        activation_last_q  <= S_ACTIVATION.last & S_WEIGHT.last;
      end
    end
  end
endmodule
