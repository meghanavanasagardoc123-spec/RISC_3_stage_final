`include "riscv_defines.vh"

`timescale 1ns/1ps

/*
------------------------------------------------------------------------------
File        : imm_gen.v
Module      : imm_gen
Purpose     : Immediate generator for the selected RV32I subset

Functionality:
- Decodes the instruction opcode internally
- Extracts and sign-extends the immediate field based on instruction format
- Supports only the immediate formats needed by this project subset:
    1. I-type  : for LW
    2. S-type  : for SW
    3. B-type  : for BEQ, BNE
    4. J-type  : for JAL
- For instructions that do not use an immediate (such as R-type ALU ops
  and custom FFT instruction), output defaults to 32'b0

Supported opcodes:
- 7'b0000011 : LW   -> I-type immediate
- 7'b0100011 : SW   -> S-type immediate
- 7'b1100011 : BEQ/BNE -> B-type immediate
- 7'b1101111 : JAL  -> J-type immediate

Inputs:
- instr   : 32-bit instruction word from fetch/decode stage

Outputs:
- imm_out : 32-bit sign-extended immediate value corresponding to the
            instruction format; 32'b0 for instructions with no immediate

Notes:
- No external imm_sel control is required
- Immediate format is selected directly using opcode decode
- Pure combinational logic
- Suitable for subset-based RV32I decode/execute stage
------------------------------------------------------------------------------
*/

module imm_gen (
    input  [31:0] instr,
    output reg [31:0] imm_out
);

    wire [6:0] opcode;
    assign opcode = instr[6:0];

    always @(*) begin
        case (opcode)

            // I-type immediate : LW
            7'b0000011: begin
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end

            // S-type immediate : SW
            7'b0100011: begin
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // B-type immediate : BEQ, BNE
            7'b1100011: begin
                imm_out = {{19{instr[31]}},
                           instr[31],
                           instr[7],
                           instr[30:25],
                           instr[11:8],
                           1'b0};
            end

            // J-type immediate : JAL
            7'b1101111: begin
                imm_out = {{11{instr[31]}},
                           instr[31],
                           instr[19:12],
                           instr[20],
                           instr[30:21],
                           1'b0};
            end

            // R-type / custom FFT / unsupported instructions
            default: begin
                imm_out = 32'b0;
            end
        endcase
    end

endmodule
