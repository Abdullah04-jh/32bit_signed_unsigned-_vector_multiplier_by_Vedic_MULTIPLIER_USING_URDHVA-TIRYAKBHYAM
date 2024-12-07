module tc_bit_stream_with_precision #(parameter WIDTH=8)
               (
    input  logic [1:0] precision,
    input  logic [(WIDTH*4)-1:0] operand_a,
                 output logic [(WIDTH*4)-1:0] output_operand
);
   //  mux_in signal for genrating select signal for tc as precsion 
   // carray_out_from_8bit_tc 2 bit signal is propagating perviosus block out to next tc block
    logic [2:0][1:0] carry_out_from_8bit_tc;
    logic [2:0] mux_in;

    tc_first_8bits #(
      .WIDTH(WIDTH)
    ) from_bit0_bit7 (
        .operand_a (operand_a[WIDTH-1:0]),
      .operand_b (output_operand[WIDTH-1:0]),
        .carry_out(carry_out_from_8bit_tc[0])
    );

    tc_remaning_8bits#(
      .WIDTH(WIDTH)
    ) from_bit8_bit15 (
      .operand_a(operand_a[(WIDTH*2)-1:WIDTH]),
      .operand_b(output_operand[(WIDTH*2)-1:WIDTH]),
        .mux(mux_in[0]),
        .carry_in(carry_out_from_8bit_tc[0]),
        .carry_out(carry_out_from_8bit_tc[1])
    );

    tc_remaning_8bits#(
      .WIDTH(WIDTH)
    ) from_bit16_bit23 (
      .operand_a(operand_a[(WIDTH*3)-1:(WIDTH*2)]),
      .operand_b(output_operand[(WIDTH*3)-1:(WIDTH*2)]),
        .mux(mux_in[1]),
        .carry_in(carry_out_from_8bit_tc[1]),
        .carry_out(carry_out_from_8bit_tc[2])
    );

    tc_remaning_8bits #(
      .WIDTH(WIDTH)
    ) from_bit24_bit31 (
      .operand_a(operand_a[(WIDTH*4)-1:(WIDTH*3)]),
      .operand_b(output_operand[(WIDTH*4)-1:(WIDTH*3)]),
        .mux(mux_in[2]),
        .carry_in(carry_out_from_8bit_tc[2])
    );
    // genrating mux select signal for concatenatoin the 8 bit Tow's complemt blocks based on precision
    always_comb begin
        // select signal for  mux 0
        if (precision == 2'b00 | precision == 2'b11) begin
            mux_in[0] = 1'b0;
        end 
        else begin
            mux_in[0] = 1'b1;
        end

        // select signal for mux 1
        if (precision == 2'b10) begin
            mux_in[1] = 1'b1;
        end 
        else begin
            mux_in[1] = 1'b0;
        end
        // select signal for mux 2
        if (precision == 2'b00 | precision == 2'b11) begin
            mux_in[2] = 1'b0;
        end 
        else begin
            mux_in[2] = 1'b1;
        end
    end

endmodule

// this module is responsible for producing tc as precision and input from pervious tc block 

module tc_remaning_8bits #(
     parameter WIDTH = 8
) (
    input logic [WIDTH-1:0] operand_a,
    output logic [WIDTH-1:0] operand_b,
    input logic mux,
    input logic [1:0] carry_in,
    output logic [1:0] carry_out
);
  //loop Varible
    integer i;
    // out wire of or gate 
    logic inter_or_gate;

    logic [WIDTH-2:0] or_gate;
  assign carry_out = {operand_a[WIDTH-1], or_gate[WIDTH-2]};
  assign inter_or_gate = carry_in[0] | carry_in[1];

    always_comb begin
        or_gate[0]  = mux ? (operand_a[0] | inter_or_gate) : operand_a[0];
        operand_b[0] = mux ? (operand_a[0] ^ inter_or_gate) : operand_a[0];
        operand_b[1] = operand_a[1] ^ or_gate[0];

      for (i = 2; i <= WIDTH-1; i = i + 1) begin
            or_gate[i-1] = operand_a[i-1] | or_gate[i-2];
            operand_b[i]  = operand_a[i] ^ or_gate[i-1];
        end
    end
endmodule

// Produce two's complement of first 8 bits of input_stream A
module tc_first_8bits #(
    parameter WIDTH = 8
) (
    input  logic [WIDTH-1:0] operand_a,
    output logic [WIDTH-1:0] operand_b,
    output logic [1:0] carry_out
);
    integer i;
    logic [WIDTH-3:0] or_gate;
    // carry_out signal is used for togling next bit 
    assign carry_out = {operand_a[WIDTH-1], or_gate[WIDTH-3]};

    always_comb begin
        operand_b[0] = operand_a[0];
        operand_b[1] = operand_a[1] ^ operand_a[0];
        or_gate[0]  = operand_a[1] | operand_a[0];

      for (i = 2; i <= WIDTH-1; i = i + 1) begin
        if (i < WIDTH) begin
                or_gate[i-1] = operand_a[i] | or_gate[i-2];
                operand_b[i]  = operand_a[i] ^ or_gate[i-2];
        end 
        else begin
                operand_b[i] = operand_a[i] ^ or_gate[i-2];
        end
      end
    end
endmodule