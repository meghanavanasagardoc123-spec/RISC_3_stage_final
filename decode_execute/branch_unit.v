`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : branch_unit.v
Module      : branch_unit
Purpose     : Branch and jump decision logic for baseline RV32I datapath

Functionality:
- Compares rs1 and rs2 for BEQ / BNE decisions
- Generates branch/jump target address using pc + imm
- Produces branch_taken signal used by PC selection logic

Supported control cases:
- branch = 1, branch_ne = 0  --> BEQ
- branch = 1, branch_ne = 1  --> BNE
- jal    = 1                 --> unconditional jump

Major inputs:
- rs1_data      : Register source 1 data
- rs2_data      : Register source 2 data
- pc_in         : Current PC value
- imm_in        : Decoded branch/jump immediate
- branch        : Branch instruction flag
- branch_ne     : Selects BNE instead of BEQ
- jal           : Jump-and-link flag

Major outputs:
- branch_taken  : Asserted when branch or jump should change PC
- target_addr   : Next PC target address for taken branch/jump
- eq_flag       : rs1_data == rs2_data compare result

Notes:
- Pure combinational logic
- JAL is always taken
- For no-branch case, target_addr is still computed as pc_in + imm_in
  but should be used only when branch_taken = 1
- Written in Verilog-only style for Icarus compatibility
------------------------------------------------------------------------------
*/

module branch_unit (
    input  [`XLEN-1:0] rs1_data,
    input  [`XLEN-1:0] rs2_data,
    input  [`XLEN-1:0] pc_in,
    input  [`XLEN-1:0] imm_in,
    input              branch,
    input              branch_ne,
    input              jal,

    output reg         branch_taken,
    output [`XLEN-1:0] target_addr,
    output             eq_flag
);

    assign eq_flag    = (rs1_data == rs2_data);
    assign target_addr = pc_in + imm_in;

    always @(*) begin
        branch_taken = 1'b0;

        if (jal) begin
            branch_taken = 1'b1;
        end
        else if (branch) begin
            if (!branch_ne && eq_flag)
                branch_taken = 1'b1;   // BEQ
            else if (branch_ne && !eq_flag)
                branch_taken = 1'b1;   // BNE
            else
                branch_taken = 1'b0;
        end
        else begin
            branch_taken = 1'b0;
        end
    end

endmodule
