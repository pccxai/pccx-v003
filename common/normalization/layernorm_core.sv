module layernorm_core #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_INPUT,
    tensor_stream_if.consumer S_WEIGHT,
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
  wire input_fire = core_ready && S_INPUT.valid && S_WEIGHT.valid;

  assign S_INPUT.ready = core_ready && S_WEIGHT.valid;
  assign S_WEIGHT.ready = core_ready && S_INPUT.valid;

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

  function automatic int signed mean_i8(
      input logic [DATA_W-1:0]     input_data,
      input logic [(DATA_W/8)-1:0] input_keep
  );
    int signed sum;
    int unsigned active_count;

    sum = 0;
    active_count = 0;
    for (int lane = 0; lane < ByteCount; lane++) begin
      if (input_keep[lane]) begin
        sum += $signed(input_data[(lane * 8) +: 8]);
        active_count++;
      end
    end

    mean_i8 = (active_count == 0) ? 0 : (sum / int'(active_count));
  endfunction

  function automatic int unsigned isqrt(input int unsigned value);
    int unsigned candidate;
    int unsigned root;

    root = 0;
    for (int bit_index = 15; bit_index >= 0; bit_index--) begin
      candidate = root | (32'd1 << bit_index);
      if ((candidate * candidate) <= value) begin
        root = candidate;
      end
    end

    isqrt = root;
  endfunction

  function automatic int unsigned stddev_i8(
      input logic [DATA_W-1:0]     input_data,
      input logic [(DATA_W/8)-1:0] input_keep,
      input int signed             mean
  );
    int signed input_lane;
    int signed centered;
    int unsigned square_sum;
    int unsigned active_count;
    int unsigned variance;
    int unsigned root;

    square_sum = 0;
    active_count = 0;
    for (int lane = 0; lane < ByteCount; lane++) begin
      if (input_keep[lane]) begin
        input_lane = $signed(input_data[(lane * 8) +: 8]);
        centered = input_lane - mean;
        square_sum += centered * centered;
        active_count++;
      end
    end

    if (active_count == 0) begin
      stddev_i8 = 1;
    end else begin
      variance = (square_sum / active_count) + 1;
      root = isqrt(variance);
      stddev_i8 = (root == 0) ? 1 : root;
    end
  endfunction

  function automatic logic [DATA_W-1:0] apply_layernorm(
      input logic [DATA_W-1:0]     input_data,
      input logic [DATA_W-1:0]     weight_data,
      input logic [(DATA_W/8)-1:0] input_keep,
      input logic [(DATA_W/8)-1:0] weight_keep
  );
    logic [DATA_W-1:0] result;
    int signed mean;
    int unsigned denominator;
    int signed input_lane;
    int signed weight_lane;
    int signed centered_lane;
    int signed scaled_lane;

    result = '0;
    mean = mean_i8(input_data, input_keep & weight_keep);
    denominator = stddev_i8(input_data, input_keep & weight_keep, mean);
    for (int lane = 0; lane < ByteCount; lane++) begin
      if (input_keep[lane] && weight_keep[lane]) begin
        input_lane = $signed(input_data[(lane * 8) +: 8]);
        weight_lane = $signed(weight_data[(lane * 8) +: 8]);
        centered_lane = input_lane - mean;
        scaled_lane = (centered_lane * weight_lane) / int'(denominator);
        result[(lane * 8) +: 8] = sat_i8(scaled_lane);
      end
    end

    apply_layernorm = result;
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
        output_data_q <= apply_layernorm(
            S_INPUT.data,
            S_WEIGHT.data,
            S_INPUT.keep,
            S_WEIGHT.keep
        );
        output_keep_q  <= S_INPUT.keep & S_WEIGHT.keep;
        output_user_q  <= S_INPUT.user;
        output_valid_q <= 1'b1;
        output_last_q  <= S_INPUT.last & S_WEIGHT.last;
      end
    end
  end
endmodule
