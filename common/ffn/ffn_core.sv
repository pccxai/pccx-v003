module ffn_core #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_ACTIVATION,
    tensor_stream_if.consumer S_WEIGHT,
    tensor_stream_if.producer M_ACTIVATION
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int ByteCount = DATA_W / 8;

  logic [DATA_W-1:0]     activation_data_q;
  logic [(DATA_W/8)-1:0] activation_keep_q;
  logic [31:0]           activation_user_q;
  logic                  activation_valid_q;
  logic                  activation_last_q;

  wire output_fire = activation_valid_q && M_ACTIVATION.ready;
  wire core_ready = !activation_valid_q || M_ACTIVATION.ready;
  wire input_fire = core_ready && S_ACTIVATION.valid && S_WEIGHT.valid;

  assign S_ACTIVATION.ready = core_ready && S_WEIGHT.valid;
  assign S_WEIGHT.ready = core_ready && S_ACTIVATION.valid;

  assign M_ACTIVATION.data = activation_data_q;
  assign M_ACTIVATION.keep = activation_keep_q;
  assign M_ACTIVATION.user = activation_user_q;
  assign M_ACTIVATION.valid = activation_valid_q;
  assign M_ACTIVATION.last = activation_last_q;

  function automatic logic [7:0] sat_i8(input int signed value);
    if (value > 127) begin
      sat_i8 = 8'h7f;
    end else if (value < -128) begin
      sat_i8 = 8'h80;
    end else begin
      sat_i8 = value[7:0];
    end
  endfunction

  function automatic logic [DATA_W-1:0] apply_ffn(
      input logic [DATA_W-1:0]     input_data,
      input logic [DATA_W-1:0]     weight_data,
      input logic [(DATA_W/8)-1:0] input_keep,
      input logic [(DATA_W/8)-1:0] weight_keep
  );
    logic [DATA_W-1:0] result;
    int signed input_lane;
    int signed weight_lane;
    int signed product;
    int signed relu_lane;

    result = '0;
    for (int lane = 0; lane < ByteCount; lane++) begin
      if (input_keep[lane] && weight_keep[lane]) begin
        input_lane = $signed(input_data[(lane * 8) +: 8]);
        weight_lane = $signed(weight_data[(lane * 8) +: 8]);
        product = input_lane * weight_lane;
        relu_lane = (product < 0) ? 0 : (product >>> 6);
        result[(lane * 8) +: 8] = sat_i8(relu_lane);
      end
    end

    apply_ffn = result;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      activation_data_q  <= '0;
      activation_keep_q  <= '0;
      activation_user_q  <= '0;
      activation_valid_q <= 1'b0;
      activation_last_q  <= 1'b0;
    end else begin
      if (output_fire) begin
        activation_valid_q <= 1'b0;
      end

      if (input_fire) begin
        activation_data_q <= apply_ffn(
            S_ACTIVATION.data,
            S_WEIGHT.data,
            S_ACTIVATION.keep,
            S_WEIGHT.keep
        );
        activation_keep_q  <= S_ACTIVATION.keep & S_WEIGHT.keep;
        activation_user_q  <= S_ACTIVATION.user;
        activation_valid_q <= 1'b1;
        activation_last_q  <= S_ACTIVATION.last & S_WEIGHT.last;
      end
    end
  end
endmodule
