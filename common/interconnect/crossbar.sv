module crossbar #(
    parameter int DATA_W = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_PORT0,
    tensor_stream_if.consumer S_PORT1,
    tensor_stream_if.producer M_PORT0,
    tensor_stream_if.producer M_PORT1
);
  timeunit 1ns;
  timeprecision 1ps;

  logic [DATA_W-1:0]     port0_data_q;
  logic [(DATA_W/8)-1:0] port0_keep_q;
  logic [31:0]           port0_user_q;
  logic                  port0_valid_q;
  logic                  port0_last_q;
  logic [DATA_W-1:0]     port1_data_q;
  logic [(DATA_W/8)-1:0] port1_keep_q;
  logic [31:0]           port1_user_q;
  logic                  port1_valid_q;
  logic                  port1_last_q;

  wire port0_fire = port0_valid_q && M_PORT0.ready;
  wire port1_fire = port1_valid_q && M_PORT1.ready;
  wire port0_ready = !port0_valid_q || M_PORT0.ready;
  wire port1_ready = !port1_valid_q || M_PORT1.ready;
  wire s0_to_port1 = S_PORT0.user[0];
  wire s1_to_port1 = S_PORT1.user[0];
  wire s0_target_ready = s0_to_port1 ? port1_ready : port0_ready;
  wire s1_target_ready = s1_to_port1 ? port1_ready : port0_ready;
  wire s0_fire = S_PORT0.valid && s0_target_ready;
  wire s1_conflict = S_PORT0.valid && S_PORT1.valid && (s0_to_port1 == s1_to_port1);
  wire s1_fire = S_PORT1.valid && s1_target_ready && !s1_conflict;

  assign S_PORT0.ready = s0_target_ready;
  assign S_PORT1.ready = s1_target_ready && !s1_conflict;

  assign M_PORT0.data = port0_data_q;
  assign M_PORT0.keep = port0_keep_q;
  assign M_PORT0.user = port0_user_q;
  assign M_PORT0.valid = port0_valid_q;
  assign M_PORT0.last = port0_last_q;

  assign M_PORT1.data = port1_data_q;
  assign M_PORT1.keep = port1_keep_q;
  assign M_PORT1.user = port1_user_q;
  assign M_PORT1.valid = port1_valid_q;
  assign M_PORT1.last = port1_last_q;

  task automatic write_port0(
      input logic [DATA_W-1:0]     data,
      input logic [(DATA_W/8)-1:0] keep,
      input logic [31:0]           user,
      input logic                  last
  );
    port0_data_q  <= data;
    port0_keep_q  <= keep;
    port0_user_q  <= user;
    port0_valid_q <= 1'b1;
    port0_last_q  <= last;
  endtask

  task automatic write_port1(
      input logic [DATA_W-1:0]     data,
      input logic [(DATA_W/8)-1:0] keep,
      input logic [31:0]           user,
      input logic                  last
  );
    port1_data_q  <= data;
    port1_keep_q  <= keep;
    port1_user_q  <= user;
    port1_valid_q <= 1'b1;
    port1_last_q  <= last;
  endtask

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      port0_data_q  <= '0;
      port0_keep_q  <= '0;
      port0_user_q  <= '0;
      port0_valid_q <= 1'b0;
      port0_last_q  <= 1'b0;
      port1_data_q  <= '0;
      port1_keep_q  <= '0;
      port1_user_q  <= '0;
      port1_valid_q <= 1'b0;
      port1_last_q  <= 1'b0;
    end else begin
      if (port0_fire) begin
        port0_valid_q <= 1'b0;
      end
      if (port1_fire) begin
        port1_valid_q <= 1'b0;
      end

      if (s0_fire) begin
        if (s0_to_port1) begin
          write_port1(S_PORT0.data, S_PORT0.keep, S_PORT0.user, S_PORT0.last);
        end else begin
          write_port0(S_PORT0.data, S_PORT0.keep, S_PORT0.user, S_PORT0.last);
        end
      end

      if (s1_fire) begin
        if (s1_to_port1) begin
          write_port1(S_PORT1.data, S_PORT1.keep, S_PORT1.user, S_PORT1.last);
        end else begin
          write_port0(S_PORT1.data, S_PORT1.keep, S_PORT1.user, S_PORT1.last);
        end
      end
    end
  end
endmodule
