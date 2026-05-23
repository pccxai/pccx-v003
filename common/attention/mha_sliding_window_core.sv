module mha_sliding_window_core #(
    parameter int DATA_W = 256,
    parameter int HEADS = 8,
    parameter int KV_HEADS = 2,
    parameter int WINDOW_TOKENS = 4096,
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

  function automatic int unsigned stream_head(input logic [31:0] user);
    stream_head = user[23:16];
  endfunction

  function automatic int unsigned stream_pos(input logic [31:0] user);
    stream_pos = user[15:0];
  endfunction

  function automatic int unsigned mapped_kv_head(input int unsigned query_head);
    if (KV_HEADS <= 1) begin
      mapped_kv_head = 0;
    end else begin
      mapped_kv_head = query_head % KV_HEADS;
    end
  endfunction

  function automatic logic position_in_window(
      input logic [31:0] query_user,
      input logic [31:0] key_user
  );
    int unsigned query_pos;
    int unsigned key_pos;

    query_pos = stream_pos(query_user);
    key_pos = stream_pos(key_user);
    if (key_pos > query_pos) begin
      position_in_window = 1'b0;
    end else if (WINDOW_TOKENS == 0) begin
      position_in_window = 1'b1;
    end else begin
      position_in_window = ((query_pos - key_pos) < WINDOW_TOKENS);
    end
  endfunction

  function automatic logic head_matches(
      input logic [31:0] query_user,
      input logic [31:0] key_user,
      input logic [31:0] value_user
  );
    int unsigned query_head;
    int unsigned key_head;
    int unsigned value_head;
    int unsigned expected_kv_head;

    query_head = stream_head(query_user);
    key_head = stream_head(key_user);
    value_head = stream_head(value_user);
    expected_kv_head = mapped_kv_head(query_head);
    if (query_head >= HEADS) begin
      head_matches = 1'b0;
    end else begin
      head_matches = (key_head == expected_kv_head) &&
                     (value_head == expected_kv_head);
    end
  endfunction

  function automatic logic attention_allowed(
      input logic [31:0] query_user,
      input logic [31:0] key_user,
      input logic [31:0] value_user
  );
    attention_allowed = position_in_window(query_user, key_user) &&
                        head_matches(query_user, key_user, value_user);
  endfunction

  function automatic int signed dot_i8(
      input logic [DATA_W-1:0] query_data,
      input logic [DATA_W-1:0] key_data,
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
      input logic [DATA_W-1:0] query_data,
      input logic [DATA_W-1:0] key_data,
      input logic [DATA_W-1:0] value_data,
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
        if (attention_allowed(S_QUERY.user, S_KEY.user, S_VALUE.user)) begin
          context_data_q <= apply_attention(
              S_QUERY.data,
              S_KEY.data,
              S_VALUE.data,
              S_QUERY.keep,
              S_KEY.keep,
              S_VALUE.keep
          );
          context_keep_q <= S_QUERY.keep & S_KEY.keep & S_VALUE.keep;
        end else begin
          context_data_q <= '0;
          context_keep_q <= '0;
        end
        context_user_q  <= S_QUERY.user;
        context_valid_q <= 1'b1;
        context_last_q  <= S_QUERY.last & S_KEY.last & S_VALUE.last;
      end
    end
  end
endmodule
