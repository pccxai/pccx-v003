module topk_sampler #(
    parameter int DATA_W = 256,
    parameter int K = 8
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_LOGITS,
    token_out_if.producer M_TOKEN
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int ByteCount = DATA_W / 8;
  localparam int KeepTop = (K < 1) ? 1 : K;

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

  function automatic logic [31:0] deterministic_topk_pick(
      input logic [DATA_W-1:0]     logits,
      input logic [(DATA_W/8)-1:0] keep
  );
    int signed top_score [KeepTop];
    logic [31:0] top_index [KeepTop];
    int signed candidate_value;
    int unsigned insert_at;

    for (int slot = 0; slot < KeepTop; slot++) begin
      top_score[slot] = -129;
      top_index[slot] = '0;
    end

    for (int lane = 0; lane < ByteCount; lane++) begin
      if (keep[lane]) begin
        candidate_value = lane_i8(logits, lane);
        insert_at = KeepTop;
        for (int slot = 0; slot < KeepTop; slot++) begin
          if (candidate_value > top_score[slot] && insert_at == KeepTop) begin
            insert_at = slot;
          end
        end

        if (insert_at < KeepTop) begin
          for (int slot = KeepTop - 1; slot > int'(insert_at); slot--) begin
            top_score[slot] = top_score[slot - 1];
            top_index[slot] = top_index[slot - 1];
          end
          top_score[insert_at] = candidate_value;
          top_index[insert_at] = lane;
        end
      end
    end

    deterministic_topk_pick = top_index[0];
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
        token_q       <= deterministic_topk_pick(S_LOGITS.data, S_LOGITS.keep);
        sequence_id_q <= S_LOGITS.user;
        valid_q       <= 1'b1;
        last_q        <= S_LOGITS.last;
      end
    end
  end
endmodule
