module attention_core #(
    parameter int DATA_W = 256,
    parameter int SCORE_SCALE_SHIFT = 5
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

  localparam int ByteCount = DATA_W / 8;

  logic [DATA_W-1:0]     context_data_q;
  logic [(DATA_W/8)-1:0] context_keep_q;
  logic [31:0]           context_user_q;
  logic                  context_valid_q;
  logic                  context_last_q;

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

  function automatic logic [7:0] sat_i8(input int signed value);
    if (value > 127) begin
      sat_i8 = 8'h7f;
    end else if (value < -128) begin
      sat_i8 = 8'h80;
    end else begin
      sat_i8 = value[7:0];
    end
  endfunction

  function automatic int signed dot_i8(
      input logic [DATA_W-1:0]     query_data,
      input logic [DATA_W-1:0]     key_data,
      input logic [(DATA_W/8)-1:0] query_keep,
      input logic [(DATA_W/8)-1:0] key_keep
  );
    int signed sum;
    int signed query_lane;
    int signed key_lane;

    sum = 0;
    for (int lane = 0; lane < ByteCount; lane++) begin
      if (query_keep[lane] && key_keep[lane]) begin
        query_lane = $signed(query_data[(lane * 8) +: 8]);
        key_lane = $signed(key_data[(lane * 8) +: 8]);
        sum += query_lane * key_lane;
      end
    end

    dot_i8 = sum;
  endfunction

  function automatic int signed score_to_gate(input int signed score);
    int signed scaled_score;

    scaled_score = score <<< SCORE_SCALE_SHIFT;
    if (scaled_score > 127) begin
      score_to_gate = 127;
    end else if (scaled_score < -128) begin
      score_to_gate = -128;
    end else begin
      score_to_gate = scaled_score;
    end
  endfunction

  function automatic logic [DATA_W-1:0] apply_attention(
      input logic [DATA_W-1:0]     query_data,
      input logic [DATA_W-1:0]     key_data,
      input logic [DATA_W-1:0]     value_data,
      input logic [(DATA_W/8)-1:0] query_keep,
      input logic [(DATA_W/8)-1:0] key_keep,
      input logic [(DATA_W/8)-1:0] value_keep
  );
    logic [DATA_W-1:0] result;
    int signed score;
    int signed gate;
    int signed value_lane;
    int signed scaled_lane;

    result = '0;
    score = dot_i8(query_data, key_data, query_keep, key_keep);
    gate = score_to_gate(score);

    for (int lane = 0; lane < ByteCount; lane++) begin
      if (query_keep[lane] && key_keep[lane] && value_keep[lane]) begin
        value_lane = $signed(value_data[(lane * 8) +: 8]);
        scaled_lane = (value_lane * gate) >>> 7;
        result[(lane * 8) +: 8] = sat_i8(scaled_lane);
      end
    end

    apply_attention = result;
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
        context_keep_q  <= S_QUERY.keep & S_KEY.keep & S_VALUE.keep;
        context_user_q  <= S_QUERY.user;
        context_valid_q <= 1'b1;
        context_last_q  <= S_QUERY.last & S_KEY.last & S_VALUE.last;
      end
    end
  end
endmodule
