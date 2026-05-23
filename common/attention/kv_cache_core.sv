module kv_cache_core #(
    parameter int DATA_W = 256,
    parameter int DEPTH = 256
) (
    input logic clk,
    input logic rst_n,
    tensor_stream_if.consumer S_KV_WRITE,
    tensor_stream_if.consumer S_KV_LOOKUP,
    tensor_stream_if.producer M_KV_READ
);
  timeunit 1ns;
  timeprecision 1ps;

  localparam int AddrW = (DEPTH <= 2) ? 1 : $clog2(DEPTH);

  logic [DATA_W-1:0]     data_mem [DEPTH];
  logic [(DATA_W/8)-1:0] keep_mem [DEPTH];
  logic                  last_mem [DEPTH];
  logic [DATA_W-1:0]     read_data_q;
  logic [(DATA_W/8)-1:0] read_keep_q;
  logic [31:0]           read_user_q;
  logic                  read_valid_q;
  logic                  read_last_q;

  wire read_fire = read_valid_q && M_KV_READ.ready;
  wire lookup_ready = !read_valid_q || M_KV_READ.ready;
  wire write_fire = S_KV_WRITE.valid && S_KV_WRITE.ready;
  wire lookup_fire = S_KV_LOOKUP.valid && S_KV_LOOKUP.ready;

  assign S_KV_WRITE.ready = 1'b1;
  assign S_KV_LOOKUP.ready = lookup_ready;

  assign M_KV_READ.data = read_data_q;
  assign M_KV_READ.keep = read_keep_q;
  assign M_KV_READ.user = read_user_q;
  assign M_KV_READ.valid = read_valid_q;
  assign M_KV_READ.last = read_last_q;

  function automatic logic [AddrW-1:0] user_to_addr(input logic [31:0] user);
    user_to_addr = user[AddrW-1:0];
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      read_data_q  <= '0;
      read_keep_q  <= '0;
      read_user_q  <= '0;
      read_valid_q <= 1'b0;
      read_last_q  <= 1'b0;
      for (int index = 0; index < DEPTH; index++) begin
        data_mem[index] <= '0;
        keep_mem[index] <= '0;
        last_mem[index] <= 1'b0;
      end
    end else begin
      if (read_fire) begin
        read_valid_q <= 1'b0;
      end

      if (write_fire) begin
        data_mem[user_to_addr(S_KV_WRITE.user)] <= S_KV_WRITE.data;
        keep_mem[user_to_addr(S_KV_WRITE.user)] <= S_KV_WRITE.keep;
        last_mem[user_to_addr(S_KV_WRITE.user)] <= S_KV_WRITE.last;
      end

      if (lookup_fire) begin
        read_data_q  <= data_mem[user_to_addr(S_KV_LOOKUP.user)];
        read_keep_q  <= keep_mem[user_to_addr(S_KV_LOOKUP.user)];
        read_user_q  <= S_KV_LOOKUP.user;
        read_valid_q <= 1'b1;
        read_last_q  <= last_mem[user_to_addr(S_KV_LOOKUP.user)];
      end
    end
  end
endmodule
