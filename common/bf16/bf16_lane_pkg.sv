package bf16_lane_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  localparam int Bf16ExpBias = 127;

  function automatic logic bf16_is_zero(input logic [15:0] value);
    bf16_is_zero = (value[14:0] == 15'd0);
  endfunction

  function automatic logic [15:0] bf16_neg(input logic [15:0] value);
    if (bf16_is_zero(value)) begin
      bf16_neg = 16'h0000;
    end else begin
      bf16_neg = {~value[15], value[14:0]};
    end
  endfunction

  function automatic logic [15:0] bf16_pack(
      input logic sign,
      input int signed exponent,
      input logic [7:0] mantissa_with_hidden
  );
    logic [7:0] exponent_clamped;

    if (exponent <= 0) begin
      bf16_pack = 16'h0000;
    end else begin
      if (exponent >= 255) begin
        exponent_clamped = 8'hfe;
      end else begin
        exponent_clamped = exponent[7:0];
      end
      bf16_pack = {sign, exponent_clamped, mantissa_with_hidden[6:0]};
    end
  endfunction

  function automatic logic [15:0] bf16_mul(
      input logic [15:0] lhs,
      input logic [15:0] rhs
  );
    logic sign;
    logic [7:0] lhs_mantissa;
    logic [7:0] rhs_mantissa;
    logic [15:0] product;
    logic [7:0] normalized_mantissa;
    int signed exponent;

    if (bf16_is_zero(lhs) || bf16_is_zero(rhs)) begin
      bf16_mul = 16'h0000;
    end else begin
      sign = lhs[15] ^ rhs[15];
      lhs_mantissa = {1'b1, lhs[6:0]};
      rhs_mantissa = {1'b1, rhs[6:0]};
      product = lhs_mantissa * rhs_mantissa;
      exponent = int'({1'b0, lhs[14:7]}) + int'({1'b0, rhs[14:7]}) - Bf16ExpBias;

      if (product[15]) begin
        normalized_mantissa = product[14:7];
        exponent++;
      end else begin
        normalized_mantissa = product[13:6];
      end

      bf16_mul = bf16_pack(sign, exponent, normalized_mantissa);
    end
  endfunction

  function automatic logic [15:0] bf16_add(
      input logic [15:0] lhs,
      input logic [15:0] rhs
  );
    int signed lhs_exp;
    int signed rhs_exp;
    int signed result_exp;
    int signed lhs_mantissa;
    int signed rhs_mantissa;
    int signed mantissa_sum;
    int unsigned mantissa_abs;
    logic result_sign;

    if (bf16_is_zero(lhs)) begin
      bf16_add = rhs;
    end else if (bf16_is_zero(rhs)) begin
      bf16_add = lhs;
    end else begin
      lhs_exp = int'({1'b0, lhs[14:7]});
      rhs_exp = int'({1'b0, rhs[14:7]});
      lhs_mantissa = lhs[15] ? -int'({1'b1, lhs[6:0]}) : int'({1'b1, lhs[6:0]});
      rhs_mantissa = rhs[15] ? -int'({1'b1, rhs[6:0]}) : int'({1'b1, rhs[6:0]});

      if (lhs_exp > rhs_exp) begin
        result_exp = lhs_exp;
        if ((lhs_exp - rhs_exp) >= 8) begin
          rhs_mantissa = 0;
        end else begin
          rhs_mantissa = rhs_mantissa >>> (lhs_exp - rhs_exp);
        end
      end else begin
        result_exp = rhs_exp;
        if ((rhs_exp - lhs_exp) >= 8) begin
          lhs_mantissa = 0;
        end else begin
          lhs_mantissa = lhs_mantissa >>> (rhs_exp - lhs_exp);
        end
      end

      mantissa_sum = lhs_mantissa + rhs_mantissa;
      if (mantissa_sum == 0) begin
        bf16_add = 16'h0000;
      end else begin
        result_sign = mantissa_sum < 0;
        mantissa_abs = result_sign ? int unsigned'(-mantissa_sum) :
                                     int unsigned'(mantissa_sum);

        if (mantissa_abs[8]) begin
          mantissa_abs = mantissa_abs >> 1;
          result_exp++;
        end

        for (int shift_index = 0; shift_index < 8; shift_index++) begin
          if (!mantissa_abs[7] && result_exp > 0) begin
            mantissa_abs = mantissa_abs << 1;
            result_exp--;
          end
        end

        bf16_add = bf16_pack(result_sign, result_exp, mantissa_abs[7:0]);
      end
    end
  endfunction

  function automatic logic [15:0] bf16_sub(
      input logic [15:0] lhs,
      input logic [15:0] rhs
  );
    bf16_sub = bf16_add(lhs, bf16_neg(rhs));
  endfunction

  function automatic logic [15:0] bf16_relu(input logic [15:0] value);
    if (value[15]) begin
      bf16_relu = 16'h0000;
    end else begin
      bf16_relu = value;
    end
  endfunction
endpackage
