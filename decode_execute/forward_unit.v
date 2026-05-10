`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : forward_unit.v
Module      : forward_unit
Purpose     : Data forwarding control unit for pipelined RV32I processor

Functionality:
- Detects RAW data hazards for ALU source operands
- Selects forwarded data from later pipeline stages instead of stale register
  file outputs
- Gives priority to the nearest/latest pipeline stage result

Forwarding select encoding:
- 2'b00 : Use normal register file data
- 2'b01 : Forward from MEM/WB stage
- 2'b10 : Forward from EX/MEM stage
- 2'b11 : Reserved / unused

Major inputs:
- ex_rs1_addr      : Source register 1 address in current execute stage
- ex_rs2_addr      : Source register 2 address in current execute stage
- exmem_rd_addr    : Destination register in EX/MEM stage
- exmem_reg_write  : EX/MEM writeback enable
- memwb_rd_addr    : Destination register in MEM/WB stage
- memwb_reg_write  : MEM/WB writeback enable

Major outputs:
- forward_a_sel    : Forwarding select for ALU operand A
- forward_b_sel    : Forwarding select for ALU operand B

Notes:
- x0 is never forwarded because writes to x0 are ignored in RISC-V
- EX/MEM has priority over MEM/WB
- Pure combinational logic
- Written in Verilog-only style for Icarus compatibility
------------------------------------------------------------------------------
*/

module forward_unit (
    input  [4:0] ex_rs1_addr,
    input  [4:0] ex_rs2_addr,

    input  [4:0] exmem_rd_addr,
    input        exmem_reg_write,

    input  [4:0] memwb_rd_addr,
    input        memwb_reg_write,

    output reg [1:0] forward_a_sel,
    output reg [1:0] forward_b_sel
);

    always @(*) begin
        // Default: no forwarding
        forward_a_sel = 2'b00;
        forward_b_sel = 2'b00;

        // ------------------------------------------------------
        // Forward for source A
        // EX/MEM gets highest priority
        // ------------------------------------------------------
        if (exmem_reg_write &&
            (exmem_rd_addr != 5'd0) &&
            (exmem_rd_addr == ex_rs1_addr)) begin
            forward_a_sel = 2'b10;
        end
        else if (memwb_reg_write &&
                 (memwb_rd_addr != 5'd0) &&
                 (memwb_rd_addr == ex_rs1_addr)) begin
            forward_a_sel = 2'b01;
        end

        // ------------------------------------------------------
        // Forward for source B
        // EX/MEM gets highest priority
        // ------------------------------------------------------
        if (exmem_reg_write &&
            (exmem_rd_addr != 5'd0) &&
            (exmem_rd_addr == ex_rs2_addr)) begin
            forward_b_sel = 2'b10;
        end
        else if (memwb_reg_write &&
                 (memwb_rd_addr != 5'd0) &&
                 (memwb_rd_addr == ex_rs2_addr)) begin
            forward_b_sel = 2'b01;
        end
    end

endmodule
