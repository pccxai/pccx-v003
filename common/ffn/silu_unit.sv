module silu_unit #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_INPUT,
    tensor_stream_if.producer M_OUTPUT
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int ByteCount = DATA_W / 8;

  logic [DATA_W-1:0]     output_data_q;
  logic [(DATA_W/8)-1:0] output_keep_q;
  logic [31:0]           output_user_q;
  logic                  output_valid_q;
  logic                  output_last_q;

  wire output_fire = output_valid_q && M_OUTPUT.ready;
  wire core_ready = !output_valid_q || M_OUTPUT.ready;
  wire input_fire = core_ready && S_INPUT.valid;

  assign S_INPUT.ready = core_ready;

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

  function automatic int unsigned sigmoid_gate(input int signed value);
    int signed gate;

    gate = value + 128;
    if (gate < 0) begin
      sigmoid_gate = 0;
    end else if (gate > 255) begin
      sigmoid_gate = 255;
    end else begin
      sigmoid_gate = gate[7:0];
    end
  endfunction

  function automatic logic [DATA_W-1:0] apply_silu(
      input logic [DATA_W-1:0]     input_data,
      input logic [(DATA_W/8)-1:0] input_keep
  );
    logic [DATA_W-1:0] result;
    int signed input_lane;
    int signed output_lane;

    result = '0;
    for (int lane = 0; lane < ByteCount; lane++) begin
      if (input_keep[lane]) begin
        input_lane = $signed(input_data[(lane * 8) +: 8]);
        output_lane = (input_lane * int'(sigmoid_gate(input_lane))) >>> 8;
        result[(lane * 8) +: 8] = sat_i8(output_lane);
      end
    end

    apply_silu = result;
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
        output_data_q  <= apply_silu(S_INPUT.data, S_INPUT.keep);
        output_keep_q  <= S_INPUT.keep;
        output_user_q  <= S_INPUT.user;
        output_valid_q <= 1'b1;
        output_last_q  <= S_INPUT.last;
      end
    end
  end
endmodule
