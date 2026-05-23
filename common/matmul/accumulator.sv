module accumulator #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_PARTIAL_INT32,
    tensor_stream_if.producer M_SUM_INT32
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int LaneCount = DATA_W / 32;

  logic [DATA_W-1:0]     running_sum_q;
  logic [(DATA_W/8)-1:0] running_keep_q;
  logic [31:0]           running_user_q;
  logic [DATA_W-1:0]     output_data_q;
  logic [(DATA_W/8)-1:0] output_keep_q;
  logic [31:0]           output_user_q;
  logic                  output_valid_q;
  logic                  output_last_q;

  wire output_fire = output_valid_q && M_SUM_INT32.ready;
  wire core_ready = !output_valid_q || M_SUM_INT32.ready;
  wire input_fire = core_ready && S_PARTIAL_INT32.valid;

  assign S_PARTIAL_INT32.ready = core_ready;

  assign M_SUM_INT32.data = output_data_q;
  assign M_SUM_INT32.keep = output_keep_q;
  assign M_SUM_INT32.user = output_user_q;
  assign M_SUM_INT32.valid = output_valid_q;
  assign M_SUM_INT32.last = output_last_q;

  function automatic logic [DATA_W-1:0] add_i32_lanes(
      input logic [DATA_W-1:0] lhs,
      input logic [DATA_W-1:0] rhs,
      input logic [(DATA_W/8)-1:0] rhs_keep
  );
    logic [DATA_W-1:0] result;
    int signed lane_sum;
    logic lane_active;

    result = lhs;
    for (int lane = 0; lane < LaneCount; lane++) begin
      lane_active = |rhs_keep[(lane * 4) +: 4];
      if (lane_active) begin
        lane_sum = $signed(lhs[(lane * 32) +: 32]) +
                   $signed(rhs[(lane * 32) +: 32]);
        result[(lane * 32) +: 32] = lane_sum[31:0];
      end
    end

    add_i32_lanes = result;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      running_sum_q   <= '0;
      running_keep_q  <= '0;
      running_user_q  <= '0;
      output_data_q   <= '0;
      output_keep_q   <= '0;
      output_user_q   <= '0;
      output_valid_q  <= 1'b0;
      output_last_q   <= 1'b0;
    end else begin
      if (output_fire) begin
        output_valid_q <= 1'b0;
      end

      if (input_fire) begin
        if (S_PARTIAL_INT32.last) begin
          output_data_q <= add_i32_lanes(
              running_sum_q,
              S_PARTIAL_INT32.data,
              S_PARTIAL_INT32.keep
          );
          output_keep_q   <= running_keep_q | S_PARTIAL_INT32.keep;
          output_user_q   <= running_user_q;
          output_valid_q  <= 1'b1;
          output_last_q   <= 1'b1;
          running_sum_q   <= '0;
          running_keep_q  <= '0;
          running_user_q  <= '0;
        end else begin
          running_sum_q <= add_i32_lanes(
              running_sum_q,
              S_PARTIAL_INT32.data,
              S_PARTIAL_INT32.keep
          );
          running_keep_q <= running_keep_q | S_PARTIAL_INT32.keep;
          running_user_q <= S_PARTIAL_INT32.user;
        end
      end
    end
  end
endmodule
