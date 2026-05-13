`include "riscv_defines.vh"
//`include "../riscv_defines.vh"



/*
------------------------------------------------------------------------------
File        : instr_mem.v
Module      : instr_mem
Purpose     : Synthesizable instruction ROM for baseline RV32I fetch stage

Functionality:
- Stores 32-bit instructions as fixed ROM contents
- Provides combinational instruction fetch using current PC
- Uses word-aligned addressing with pc_in[31:2]

Major inputs:
- pc_in         : Current Program Counter from fetch stage

Major outputs:
- instr_out     : 32-bit fetched instruction


*/

module instr_mem (
    input  [`XLEN-1:0] pc_in,
    output reg [31:0]  instr_out
);

    wire [`XLEN-1:0] word_addr;
    assign word_addr = pc_in >> 2;

//    always @(*) begin
//        case (word_addr)
//            32'd0: instr_out = 32'h00A00093; // addi x1, x0, 10
//            32'd1: instr_out = 32'h01400113; // addi x2, x0, 20
//            32'd2: instr_out = 32'h002081B3; // add  x3, x1, x2
//            32'd3: instr_out = 32'h40310233; // sub  x4, x2, x3
//            32'd4: instr_out = 32'h00302023; // sw   x3, 0(x0)
//            32'd5: instr_out = 32'h00002283; // lw   x5, 0(x0)
//            32'd6: instr_out = 32'h00328463; // beq  x5, x3, +8
//            32'd7: instr_out = 32'h00100313; // addi x6, x0, 1
//            32'd8: instr_out = 32'h0000006F; // jal  x0, 0
//            default: instr_out = 32'h00000000;
//        endcase
//    end
always @(*) begin
    case (word_addr)
        32'd0: instr_out = 32'h002081B3; // ADD  x3, x1, x2  (002081B3)
        32'd1: instr_out = 32'h402081B3; // SUB  x3, x1, x2  (402081B3)
        32'd2: instr_out = 32'h0020F1B3; // AND  x3, x1, x2  (0020F1B3)
        32'd3: instr_out = 32'h0020E1B3; // OR   x3, x1, x2  (0020E1B3)
        32'd4: instr_out = 32'h0020C1B3; // XOR  x3, x1, x2  (0020C1B3)
        32'd5: instr_out = 32'h00A02083; // LW   x1, 0(x0)  (00A02083)
        32'd6: instr_out = 32'h00302023; // SW   x3, 0(x0)  (00302023)
        32'd7: instr_out = 32'h00208463; // BEQ  x1, x2, +8 (00208463)
        32'd8: instr_out = 32'h00209463; // BNE  x1, x2, +8 (00209463)
        32'd9: instr_out = 32'h0000006F; // JAL  x0, 0      (0000006F)
        32'd10: instr_out = 32'h020000BB; // FFT  x0, x4, x4 (020000BB)
        default: instr_out = 32'h0000006F; 
    endcase
end


endmodule
