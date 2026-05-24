module gemma4_e2b_bf16_decode_tb;
  timeunit 1ns;
  timeprecision 1ps;

  localparam int DataW = 64;

  logic clk;
  logic rst_n;

  tensor_stream_if #(.DATA_W(DataW)) embedding_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) rms_weight_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) rotation_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) kv_write_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) kv_lookup_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) value_if (.clk(clk), .rst_n(rst_n));
  tensor_stream_if #(.DATA_W(DataW)) mlp_weight_if (.clk(clk), .rst_n(rst_n));
  token_out_if token_if (.clk(clk), .rst_n(rst_n));

  gemma4_e2b_bf16_decode_slice #(.DATA_W(DataW)) u_decode_slice (
      .clk(clk),
      .rst_n(rst_n),
      .S_EMBEDDING(embedding_if),
      .S_RMS_WEIGHT(rms_weight_if),
      .S_ROPE_ROTATION(rotation_if),
      .S_KV_WRITE(kv_write_if),
      .S_KV_LOOKUP(kv_lookup_if),
      .S_VALUE(value_if),
      .S_MLP_WEIGHT(mlp_weight_if),
      .M_TOKEN(token_if)
  );

  always #5 clk = !clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    token_if.ready = 1'b1;

    embedding_if.data = '0;
    embedding_if.keep = '0;
    embedding_if.user = '0;
    embedding_if.valid = 1'b0;
    embedding_if.last = 1'b0;
    rms_weight_if.data = '0;
    rms_weight_if.keep = '0;
    rms_weight_if.user = '0;
    rms_weight_if.valid = 1'b0;
    rms_weight_if.last = 1'b0;
    rotation_if.data = '0;
    rotation_if.keep = '0;
    rotation_if.user = '0;
    rotation_if.valid = 1'b0;
    rotation_if.last = 1'b0;
    kv_write_if.data = '0;
    kv_write_if.keep = '0;
    kv_write_if.user = '0;
    kv_write_if.valid = 1'b0;
    kv_write_if.last = 1'b0;
    kv_lookup_if.data = '0;
    kv_lookup_if.keep = '0;
    kv_lookup_if.user = '0;
    kv_lookup_if.valid = 1'b0;
    kv_lookup_if.last = 1'b0;
    value_if.data = '0;
    value_if.keep = '0;
    value_if.user = '0;
    value_if.valid = 1'b0;
    value_if.last = 1'b0;
    mlp_weight_if.data = '0;
    mlp_weight_if.keep = '0;
    mlp_weight_if.user = '0;
    mlp_weight_if.valid = 1'b0;
    mlp_weight_if.last = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    kv_write_if.data = {4{16'h3f80}};
    kv_write_if.keep = '1;
    kv_write_if.user = 32'h00000003;
    kv_write_if.last = 1'b1;
    kv_write_if.valid = 1'b1;
    @(posedge clk);
    kv_write_if.valid = 1'b0;

    embedding_if.data = {4{16'h3f80}};
    embedding_if.keep = '1;
    embedding_if.user = 32'h0000002a;
    embedding_if.last = 1'b1;
    embedding_if.valid = 1'b1;
    rms_weight_if.data = {4{16'h3f80}};
    rms_weight_if.keep = '1;
    rms_weight_if.user = 32'h0000002a;
    rms_weight_if.last = 1'b1;
    rms_weight_if.valid = 1'b1;
    rotation_if.data = {16'h0000, 16'h3f80, 16'h0000, 16'h3f80};
    rotation_if.keep = '1;
    rotation_if.user = 32'h0000002a;
    rotation_if.last = 1'b1;
    rotation_if.valid = 1'b1;
    kv_lookup_if.data = '0;
    kv_lookup_if.keep = '0;
    kv_lookup_if.user = 32'h00000003;
    kv_lookup_if.last = 1'b1;
    kv_lookup_if.valid = 1'b1;
    value_if.data = {4{16'h3f80}};
    value_if.keep = '1;
    value_if.user = 32'h0000002a;
    value_if.last = 1'b1;
    value_if.valid = 1'b1;
    mlp_weight_if.data = {4{16'h3f80}};
    mlp_weight_if.keep = '1;
    mlp_weight_if.user = 32'h0000002a;
    mlp_weight_if.last = 1'b1;
    mlp_weight_if.valid = 1'b1;

    repeat (12) begin
      @(posedge clk);
      if (token_if.valid) begin
        if (token_if.sequence_id != 32'h0000002a) begin
          $fatal(1, "unexpected sequence id 0x%08x", token_if.sequence_id);
        end
        if (!token_if.last) begin
          $fatal(1, "decode slice token must be marked last");
        end
        $display("Gemma 4 E2B BF16 decode slice smoke PASS");
        $finish;
      end
    end

    $fatal(1, "Gemma 4 E2B BF16 decode slice did not emit a token");
  end
endmodule
