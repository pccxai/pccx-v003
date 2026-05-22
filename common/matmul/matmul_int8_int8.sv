module matmul_int8_int8 #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_ACTIVATION_INT8,
    tensor_stream_if.consumer S_WEIGHT_INT8,
    tensor_stream_if.producer M_ACCUM_INT32
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int ActivationLaneCount = DATA_W / 8;
  localparam int AccumLaneCount = DATA_W / 32;
  localparam int BlockElemCount = ActivationLaneCount / AccumLaneCount;

  logic [DATA_W-1:0]     accum_data_q;
  logic [(DATA_W/8)-1:0] accum_keep_q;
  logic [31:0]           accum_user_q;
  logic                  accum_valid_q;
  logic                  accum_last_q;

  wire output_fire = accum_valid_q && M_ACCUM_INT32.ready;
  wire core_ready = !accum_valid_q || M_ACCUM_INT32.ready;
  wire input_fire = core_ready && S_ACTIVATION_INT8.valid && S_WEIGHT_INT8.valid;

  assign S_ACTIVATION_INT8.ready = core_ready && S_WEIGHT_INT8.valid;
  assign S_WEIGHT_INT8.ready = core_ready && S_ACTIVATION_INT8.valid;

  assign M_ACCUM_INT32.data = accum_data_q;
  assign M_ACCUM_INT32.keep = accum_keep_q;
  assign M_ACCUM_INT32.user = accum_user_q;
  assign M_ACCUM_INT32.valid = accum_valid_q;
  assign M_ACCUM_INT32.last = accum_last_q;

  function automatic int signed int8_lane(
      input logic [DATA_W-1:0] data,
      input int unsigned lane
  );
    int8_lane = $signed(data[(lane * 8) +: 8]);
  endfunction

  function automatic logic [DATA_W-1:0] apply_matmul(
      input logic [DATA_W-1:0]     activation_data,
      input logic [DATA_W-1:0]     weight_data,
      input logic [(DATA_W/8)-1:0] activation_keep,
      input logic [(DATA_W/8)-1:0] weight_keep
  );
    logic [DATA_W-1:0] result;
    int signed accum;
    int unsigned lane_index;

    result = '0;
    for (int accum_lane = 0; accum_lane < AccumLaneCount; accum_lane++) begin
      accum = 0;
      for (int elem = 0; elem < BlockElemCount; elem++) begin
        lane_index = (accum_lane * BlockElemCount) + elem;
        if (lane_index < ActivationLaneCount &&
            activation_keep[lane_index] &&
            weight_keep[lane_index]) begin
          accum += int8_lane(activation_data, lane_index) *
                   int8_lane(weight_data, lane_index);
        end
      end
      result[(accum_lane * 32) +: 32] = accum[31:0];
    end

    apply_matmul = result;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      accum_data_q  <= '0;
      accum_keep_q  <= '0;
      accum_user_q  <= '0;
      accum_valid_q <= 1'b0;
      accum_last_q  <= 1'b0;
    end else begin
      if (output_fire) begin
        accum_valid_q <= 1'b0;
      end

      if (input_fire) begin
        accum_data_q <= apply_matmul(
            S_ACTIVATION_INT8.data,
            S_WEIGHT_INT8.data,
            S_ACTIVATION_INT8.keep,
            S_WEIGHT_INT8.keep
        );
        accum_keep_q  <= '1;
        accum_user_q  <= S_ACTIVATION_INT8.user;
        accum_valid_q <= 1'b1;
        accum_last_q  <= S_ACTIVATION_INT8.last & S_WEIGHT_INT8.last;
      end
    end
  end
endmodule
