module rope_unit #(
    parameter int DATA_W = 256,
    parameter int SCALE_SHIFT = 7
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_INPUT,
    tensor_stream_if.consumer S_ROTATION,
    tensor_stream_if.producer M_OUTPUT
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int ByteCount = DATA_W / 8;
  localparam int PairCount = ByteCount / 2;

  logic [DATA_W-1:0]     output_data_q;
  logic [(DATA_W/8)-1:0] output_keep_q;
  logic [31:0]           output_user_q;
  logic                  output_valid_q;
  logic                  output_last_q;

  wire output_fire = output_valid_q && M_OUTPUT.ready;
  wire core_ready = !output_valid_q || M_OUTPUT.ready;
  wire input_fire = core_ready && S_INPUT.valid && S_ROTATION.valid;

  assign S_INPUT.ready = core_ready && S_ROTATION.valid;
  assign S_ROTATION.ready = core_ready && S_INPUT.valid;

  assign M_OUTPUT.data = output_data_q;
  assign M_OUTPUT.keep = output_keep_q;
  assign M_OUTPUT.user = output_user_q;
  assign M_OUTPUT.valid = output_valid_q;
  assign M_OUTPUT.last = output_last_q;

  function automatic logic [7:0] sat_i8(input int signed value);
    if (value > 127) begin
      sat_i8 = 8'h7f;
    end else if (value < -128) begin
      sat_i8 = 8'h80;
    end else begin
      sat_i8 = value[7:0];
    end
  endfunction

  function automatic logic [DATA_W-1:0] rotate_pairs(
      input logic [DATA_W-1:0] input_data,
      input logic [DATA_W-1:0] rotation_data,
      input logic [(DATA_W/8)-1:0] input_keep,
      input logic [(DATA_W/8)-1:0] rotation_keep
  );
    logic [DATA_W-1:0] result;
    int signed x_even;
    int signed x_odd;
    int signed cos_lane;
    int signed sin_lane;
    int signed rot_even;
    int signed rot_odd;

    result = '0;
    for (int pair = 0; pair < PairCount; pair++) begin
      int even_lane;
      int odd_lane;

      even_lane = pair * 2;
      odd_lane = even_lane + 1;
      if (input_keep[even_lane] && input_keep[odd_lane] &&
          rotation_keep[even_lane] && rotation_keep[odd_lane]) begin
        x_even = $signed(input_data[(even_lane * 8) +: 8]);
        x_odd = $signed(input_data[(odd_lane * 8) +: 8]);
        cos_lane = $signed(rotation_data[(even_lane * 8) +: 8]);
        sin_lane = $signed(rotation_data[(odd_lane * 8) +: 8]);
        rot_even = ((x_even * cos_lane) - (x_odd * sin_lane)) >>> SCALE_SHIFT;
        rot_odd = ((x_even * sin_lane) + (x_odd * cos_lane)) >>> SCALE_SHIFT;
        result[(even_lane * 8) +: 8] = sat_i8(rot_even);
        result[(odd_lane * 8) +: 8] = sat_i8(rot_odd);
      end
    end

    rotate_pairs = result;
  endfunction

  function automatic logic [(DATA_W/8)-1:0] rotate_keep(
      input logic [(DATA_W/8)-1:0] input_keep,
      input logic [(DATA_W/8)-1:0] rotation_keep
  );
    logic [(DATA_W/8)-1:0] result;

    result = '0;
    for (int pair = 0; pair < PairCount; pair++) begin
      int even_lane;
      int odd_lane;

      even_lane = pair * 2;
      odd_lane = even_lane + 1;
      if (input_keep[even_lane] && input_keep[odd_lane] &&
          rotation_keep[even_lane] && rotation_keep[odd_lane]) begin
        result[even_lane] = 1'b1;
        result[odd_lane] = 1'b1;
      end
    end

    rotate_keep = result;
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
        output_data_q <= rotate_pairs(
            S_INPUT.data,
            S_ROTATION.data,
            S_INPUT.keep,
            S_ROTATION.keep
        );
        output_keep_q  <= rotate_keep(S_INPUT.keep, S_ROTATION.keep);
        output_user_q  <= S_INPUT.user;
        output_valid_q <= 1'b1;
        output_last_q  <= S_INPUT.last & S_ROTATION.last;
      end
    end
  end
endmodule
