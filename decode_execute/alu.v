`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : alu.v
Module      : alu
Purpose     : Arithmetic Logic Unit for baseline RV32I datapath

Functionality:
- Performs basic arithmetic and logical operations
- Used by processor execute stage for ALU instructions, address generation,
  and simple datapath pass-through operations

Supported operations:
- ALU_ADD  : a + b
- ALU_SUB  : a - b
- ALU_AND  : a & b
- ALU_OR   : a | b
- ALU_XOR  : a ^ b
- ALU_PASS : result = b

Major inputs:
- a        : Operand A (`XLEN bits)
- b        : Operand B (`XLEN bits)
- alu_op   : ALU operation select

Major outputs:
- result   : ALU result (`XLEN bits)
- zero     : Asserted when result is all zeros

Notes:
- Pure combinational logic
- zero flag can be used by branch/equality logic
- Written in Verilog-only style for Icarus compatibility
------------------------------------------------------------------------------
*/

module alu (
    input  [`XLEN-1:0] a,
    input  [`XLEN-1:0] b,
    input  [3:0]       alu_op,
    output reg [`XLEN-1:0] result,
    output             zero
);

always @(*) begin
    case (alu_op)
        `ALU_ADD:  result = a + b;
        `ALU_SUB:  result = a - b;
        `ALU_AND:  result = a & b;
        `ALU_OR:   result = a | b;
        `ALU_XOR:  result = a ^ b;
        `ALU_PASS: result = b;
        default:   result = {`XLEN{1'b0}};
    endcase
end

assign zero = (result == {`XLEN{1'b0}});

endmodule
