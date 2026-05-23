module softmax_unit #(
    parameter int DATA_W = 256,
    parameter int PROB_W = 8
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_LOGITS,
    tensor_stream_if.producer M_PROB
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int ByteCount = DATA_W / 8;

  logic [DATA_W-1:0]     prob_data_q;
  logic [(DATA_W/8)-1:0] prob_keep_q;
  logic [31:0]           prob_user_q;
  logic                  prob_valid_q;
  logic                  prob_last_q;

  wire output_fire = prob_valid_q && M_PROB.ready;
  wire core_ready = !prob_valid_q || M_PROB.ready;
  wire input_fire = core_ready && S_LOGITS.valid;

  assign S_LOGITS.ready = core_ready;

  assign M_PROB.data = prob_data_q;
  assign M_PROB.keep = prob_keep_q;
  assign M_PROB.user = prob_user_q;
  assign M_PROB.valid = prob_valid_q;
  assign M_PROB.last = prob_last_q;

  function automatic int signed lane_i8(
      input logic [DATA_W-1:0] data,
      input int unsigned lane
  );
    lane_i8 = $signed(data[(lane * 8) +: 8]);
  endfunction

  function automatic int signed max_logit(
      input logic [DATA_W-1:0] data,
      input logic [(DATA_W/8)-1:0] keep
  );
    int signed max_value;

    max_value = -128;
    for (int lane = 0; lane < ByteCount; lane++) begin
      if (keep[lane] && lane_i8(data, lane) > max_value) begin
        max_value = lane_i8(data, lane);
      end
    end

    max_logit = max_value;
  endfunction

  function automatic int unsigned exp_lut(
      input int signed value,
      input int signed maximum
  );
    int signed delta;

    delta = value - maximum;
    if (delta >= 0) begin
      exp_lut = 256;
    end else if (delta >= -8) begin
      exp_lut = 192;
    end else if (delta >= -16) begin
      exp_lut = 128;
    end else if (delta >= -32) begin
      exp_lut = 64;
    end else if (delta >= -64) begin
      exp_lut = 16;
    end else begin
      exp_lut = 1;
    end
  endfunction

  function automatic logic [DATA_W-1:0] apply_softmax(
      input logic [DATA_W-1:0]     logits,
      input logic [(DATA_W/8)-1:0] keep
  );
    logic [DATA_W-1:0] result;
    int signed maximum;
    int unsigned exp_sum;
    int unsigned exp_lane;
    int unsigned prob_lane;

    result = '0;
    maximum = max_logit(logits, keep);
    exp_sum = 0;

    for (int lane = 0; lane < ByteCount; lane++) begin
      if (keep[lane]) begin
        exp_sum += exp_lut(lane_i8(logits, lane), maximum);
      end
    end

    for (int lane = 0; lane < ByteCount; lane++) begin
      if (keep[lane] && exp_sum != 0) begin
        exp_lane = exp_lut(lane_i8(logits, lane), maximum);
        prob_lane = (exp_lane * ((1 << PROB_W) - 1)) / exp_sum;
        result[(lane * 8) +: 8] = prob_lane[7:0];
      end
    end

    apply_softmax = result;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prob_data_q  <= '0;
      prob_keep_q  <= '0;
      prob_user_q  <= '0;
      prob_valid_q <= 1'b0;
      prob_last_q  <= 1'b0;
    end else begin
      if (output_fire) begin
        prob_valid_q <= 1'b0;
      end

      if (input_fire) begin
        prob_data_q  <= apply_softmax(S_LOGITS.data, S_LOGITS.keep);
        prob_keep_q  <= S_LOGITS.keep;
        prob_user_q  <= S_LOGITS.user;
        prob_valid_q <= 1'b1;
        prob_last_q  <= S_LOGITS.last;
      end
    end
  end
endmodule
