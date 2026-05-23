module arbiter #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_REQ0,
    tensor_stream_if.consumer S_REQ1,
    tensor_stream_if.producer M_GRANT
);
  timeunit 1ns;
  timeprecision 1ps;

  logic [DATA_W-1:0]     grant_data_q;
  logic [(DATA_W/8)-1:0] grant_keep_q;
  logic [31:0]           grant_user_q;
  logic                  grant_valid_q;
  logic                  grant_last_q;
  logic                  prefer_req1_q;

  wire output_fire = grant_valid_q && M_GRANT.ready;
  wire core_ready = !grant_valid_q || M_GRANT.ready;
  wire take_req1 = core_ready && S_REQ1.valid && (!S_REQ0.valid || prefer_req1_q);
  wire take_req0 = core_ready && S_REQ0.valid && !take_req1;

  assign S_REQ0.ready = take_req0;
  assign S_REQ1.ready = take_req1;

  assign M_GRANT.data = grant_data_q;
  assign M_GRANT.keep = grant_keep_q;
  assign M_GRANT.user = grant_user_q;
  assign M_GRANT.valid = grant_valid_q;
  assign M_GRANT.last = grant_last_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant_data_q   <= '0;
      grant_keep_q   <= '0;
      grant_user_q   <= '0;
      grant_valid_q  <= 1'b0;
      grant_last_q   <= 1'b0;
      prefer_req1_q  <= 1'b0;
    end else begin
      if (output_fire) begin
        grant_valid_q <= 1'b0;
      end

      if (take_req0) begin
        grant_data_q  <= S_REQ0.data;
        grant_keep_q  <= S_REQ0.keep;
        grant_user_q  <= S_REQ0.user;
        grant_valid_q <= 1'b1;
        grant_last_q  <= S_REQ0.last;
        prefer_req1_q <= 1'b1;
      end else if (take_req1) begin
        grant_data_q  <= S_REQ1.data;
        grant_keep_q  <= S_REQ1.keep;
        grant_user_q  <= S_REQ1.user;
        grant_valid_q <= 1'b1;
        grant_last_q  <= S_REQ1.last;
        prefer_req1_q <= 1'b0;
      end
    end
  end
endmodule
