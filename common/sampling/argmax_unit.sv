module argmax_unit #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_LOGITS,
    token_out_if.producer M_TOKEN
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int ByteCount = DATA_W / 8;

  logic [31:0] token_q;
  logic [31:0] sequence_id_q;
  logic        valid_q;
  logic        last_q;

  wire output_fire = valid_q && M_TOKEN.ready;
  wire core_ready = !valid_q || M_TOKEN.ready;
  wire input_fire = core_ready && S_LOGITS.valid;

  assign S_LOGITS.ready = core_ready;

  assign M_TOKEN.token = token_q;
  assign M_TOKEN.sequence_id = sequence_id_q;
  assign M_TOKEN.valid = valid_q;
  assign M_TOKEN.last = last_q;

  function automatic int signed lane_i8(
      input logic [DATA_W-1:0] data,
      input int unsigned lane
  );
    lane_i8 = $signed(data[(lane * 8) +: 8]);
  endfunction

  function automatic logic [31:0] argmax_index(
      input logic [DATA_W-1:0]     logits,
      input logic [(DATA_W/8)-1:0] keep
  );
    int signed best_value;
    int signed candidate_value;
    logic [31:0] best_index;

    best_value = -129;
    best_index = '0;
    for (int lane = 0; lane < ByteCount; lane++) begin
      if (keep[lane]) begin
        candidate_value = lane_i8(logits, lane);
        if (candidate_value > best_value) begin
          best_value = candidate_value;
          best_index = lane;
        end
      end
    end

    argmax_index = best_index;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      token_q       <= '0;
      sequence_id_q <= '0;
      valid_q       <= 1'b0;
      last_q        <= 1'b0;
    end else begin
      if (output_fire) begin
        valid_q <= 1'b0;
      end

      if (input_fire) begin
        token_q       <= argmax_index(S_LOGITS.data, S_LOGITS.keep);
        sequence_id_q <= S_LOGITS.user;
        valid_q       <= 1'b1;
        last_q        <= S_LOGITS.last;
      end
    end
  end
endmodule
