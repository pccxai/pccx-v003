module matmul_int4_int8 #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    input npu_common_pkg::npu_sparse_meta_t sparse_meta,
    tensor_stream_if.consumer S_ACTIVATION_INT8,
    tensor_stream_if.consumer S_WEIGHT_INT4,
    tensor_stream_if.producer M_ACCUM_INT32
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int ActivationLaneCount = DATA_W / 8;
  localparam int WeightLaneCount = DATA_W / 4;
  localparam int AccumLaneCount = DATA_W / 32;
  localparam int BlockElemCount = ActivationLaneCount / AccumLaneCount;

  logic [DATA_W-1:0]     accum_data_q;
  logic [(DATA_W/8)-1:0] accum_keep_q;
  logic [31:0]           accum_user_q;
  logic                  accum_valid_q;
  logic                  accum_last_q;

  wire output_fire = accum_valid_q && M_ACCUM_INT32.ready;
  wire core_ready = !accum_valid_q || M_ACCUM_INT32.ready;
  wire input_fire = core_ready && S_ACTIVATION_INT8.valid && S_WEIGHT_INT4.valid;

  assign S_ACTIVATION_INT8.ready = core_ready && S_WEIGHT_INT4.valid;
  assign S_WEIGHT_INT4.ready = core_ready && S_ACTIVATION_INT8.valid;

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

  function automatic int signed int4_lane(
      input logic [DATA_W-1:0] data,
      input int unsigned lane
  );
    logic [3:0] nibble;

    nibble = data[(lane * 4) +: 4];
    int4_lane = $signed({{28{nibble[3]}}, nibble});
  endfunction

  function automatic logic sparse_lane_enabled(
      input int unsigned lane,
      input npu_common_pkg::npu_sparse_meta_t meta
  );
    int unsigned mask_index;

    mask_index = lane % npu_common_pkg::SparseMaskW;
    if (meta.mode == npu_common_pkg::NPU_SPARSE_STRUCTURED) begin
      if (meta.group_size != 0) begin
        mask_index = (lane / meta.group_size) % npu_common_pkg::SparseMaskW;
      end
      sparse_lane_enabled = meta.mask[mask_index];
    end else begin
      sparse_lane_enabled = 1'b1;
    end
  endfunction

  function automatic logic [DATA_W-1:0] apply_matmul(
      input logic [DATA_W-1:0] activation_data,
      input logic [DATA_W-1:0] weight_data,
      input logic [(DATA_W/8)-1:0] activation_keep,
      input logic [(DATA_W/8)-1:0] weight_keep,
      input npu_common_pkg::npu_sparse_meta_t meta
  );
    logic [DATA_W-1:0] result;
    int signed accum;
    int unsigned activation_lane;
    int unsigned weight_lane;

    result = '0;
    for (int accum_lane = 0; accum_lane < AccumLaneCount; accum_lane++) begin
      accum = 0;
      for (int elem = 0; elem < BlockElemCount; elem++) begin
        activation_lane = (accum_lane * BlockElemCount) + elem;
        weight_lane = activation_lane;

        if ((activation_lane < ActivationLaneCount) &&
            (weight_lane < WeightLaneCount) &&
            activation_keep[activation_lane] &&
            weight_keep[weight_lane / 2] &&
            sparse_lane_enabled(weight_lane, meta)) begin
          accum += int8_lane(activation_data, activation_lane) *
                   int4_lane(weight_data, weight_lane);
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
            S_WEIGHT_INT4.data,
            S_ACTIVATION_INT8.keep,
            S_WEIGHT_INT4.keep,
            sparse_meta
        );
        accum_keep_q  <= '1;
        accum_user_q  <= S_ACTIVATION_INT8.user;
        accum_valid_q <= 1'b1;
        accum_last_q  <= S_ACTIVATION_INT8.last & S_WEIGHT_INT4.last;
      end
    end
  end
endmodule
