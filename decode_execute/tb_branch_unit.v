`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : tb_branch_unit.v
Testbench   : tb_branch_unit
Purpose     : Self-checking testbench for branch_unit.v

What this TB verifies:
1. BEQ taken when rs1_data == rs2_data
2. BEQ not taken when rs1_data != rs2_data
3. BNE taken when rs1_data != rs2_data
4. BNE not taken when rs1_data == rs2_data
5. JAL always taken
6. target_addr = pc_in + imm_in
7. eq_flag reflects equality compare result

DUT inputs driven by TB:
- rs1_data      : Source register 1 data
- rs2_data      : Source register 2 data
- pc_in         : Current PC
- imm_in        : Branch/jump immediate
- branch        : Branch control
- branch_ne     : BEQ/BNE select
- jal           : Jump control

DUT outputs checked by TB:
- branch_taken  : Indicates whether control flow should change
- target_addr   : Computed target address
- eq_flag       : Equality compare result

Pass/Fail method:
- TB applies directed compare and control cases
- TB checks branch_taken, target_addr, and eq_flag
- Prints PASS/FAIL messages using $display
- Dumps waveform file for GTKWave debug

Run command (Icarus Verilog):
- Compile : iverilog -o branch_tb branch_unit.v tb_branch_unit.v
- Run     : vvp branch_tb
- Waveform: gtkwave tb_branch_unit.vcd

Notes:
- Pure Verilog testbench, no SystemVerilog features used
- This TB checks branch decision logic only, not instruction decode
------------------------------------------------------------------------------
*/

module tb_branch_unit;

    reg  [`XLEN-1:0] rs1_data;
    reg  [`XLEN-1:0] rs2_data;
    reg  [`XLEN-1:0] pc_in;
    reg  [`XLEN-1:0] imm_in;
    reg              branch;
    reg              branch_ne;
    reg              jal;

    wire             branch_taken;
    wire [`XLEN-1:0] target_addr;
    wire             eq_flag;

    integer errors;

    branch_unit uut (
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data),
        .pc_in        (pc_in),
        .imm_in       (imm_in),
        .branch       (branch),
        .branch_ne    (branch_ne),
        .jal          (jal),
        .branch_taken (branch_taken),
        .target_addr  (target_addr),
        .eq_flag      (eq_flag)
    );

    task check_branch;
        input        exp_taken;
        input [`XLEN-1:0] exp_target;
        input        exp_eq;
        input [127:0] test_name;
        begin
            #1;
            if ((branch_taken !== exp_taken) ||
                (target_addr  !== exp_target) ||
                (eq_flag      !== exp_eq)) begin

                $display("FAIL : %s", test_name);
                $display("       rs1_data=%h rs2_data=%h", rs1_data, rs2_data);
                $display("       pc_in=%h imm_in=%h", pc_in, imm_in);
                $display("       branch=%b branch_ne=%b jal=%b", branch, branch_ne, jal);
                $display("       expected branch_taken=%b target_addr=%h eq_flag=%b",
                          exp_taken, exp_target, exp_eq);
                $display("       got      branch_taken=%b target_addr=%h eq_flag=%b",
                          branch_taken, target_addr, eq_flag);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_branch_unit.vcd");
        $dumpvars(0, tb_branch_unit);

        errors = 0;

        // ------------------------------------------------------
        // Test 1: BEQ taken
        // ------------------------------------------------------
        rs1_data  = 32'd25;
        rs2_data  = 32'd25;
        pc_in     = 32'h0000_1000;
        imm_in    = 32'h0000_0010;
        branch    = 1'b1;
        branch_ne = 1'b0;
        jal       = 1'b0;
        check_branch(1'b1, 32'h0000_1010, 1'b1, "BEQ_TAKEN");

        // ------------------------------------------------------
        // Test 2: BEQ not taken
        // ------------------------------------------------------
        rs1_data  = 32'd25;
        rs2_data  = 32'd30;
        pc_in     = 32'h0000_1000;
        imm_in    = 32'h0000_0010;
        branch    = 1'b1;
        branch_ne = 1'b0;
        jal       = 1'b0;
        check_branch(1'b0, 32'h0000_1010, 1'b0, "BEQ_NOT_TAKEN");

        // ------------------------------------------------------
        // Test 3: BNE taken
        // ------------------------------------------------------
        rs1_data  = 32'd11;
        rs2_data  = 32'd22;
        pc_in     = 32'h0000_2000;
        imm_in    = 32'h0000_0008;
        branch    = 1'b1;
        branch_ne = 1'b1;
        jal       = 1'b0;
        check_branch(1'b1, 32'h0000_2008, 1'b0, "BNE_TAKEN");

        // ------------------------------------------------------
        // Test 4: BNE not taken
        // ------------------------------------------------------
        rs1_data  = 32'd44;
        rs2_data  = 32'd44;
        pc_in     = 32'h0000_2000;
        imm_in    = 32'h0000_0008;
        branch    = 1'b1;
        branch_ne = 1'b1;
        jal       = 1'b0;
        check_branch(1'b0, 32'h0000_2008, 1'b1, "BNE_NOT_TAKEN");

        // ------------------------------------------------------
        // Test 5: JAL always taken
        // ------------------------------------------------------
        rs1_data  = 32'd0;
        rs2_data  = 32'd123;
        pc_in     = 32'h0000_3000;
        imm_in    = 32'h0000_0040;
        branch    = 1'b0;
        branch_ne = 1'b0;
        jal       = 1'b1;
        check_branch(1'b1, 32'h0000_3040, 1'b0, "JAL_ALWAYS_TAKEN");

        // ------------------------------------------------------
        // Test 6: No branch, no jump
        // ------------------------------------------------------
        rs1_data  = 32'd5;
        rs2_data  = 32'd5;
        pc_in     = 32'h0000_4000;
        imm_in    = 32'h0000_0004;
        branch    = 1'b0;
        branch_ne = 1'b0;
        jal       = 1'b0;
        check_branch(1'b0, 32'h0000_4004, 1'b1, "NO_BRANCH_NO_JUMP");

        // ------------------------------------------------------
        // Test 7: Negative immediate target check
        // ------------------------------------------------------
        rs1_data  = 32'd9;
        rs2_data  = 32'd9;
        pc_in     = 32'h0000_5000;
        imm_in    = 32'hFFFF_FFF8; // -8
        branch    = 1'b1;
        branch_ne = 1'b0;
        jal       = 1'b0;
        check_branch(1'b1, 32'h0000_4FF8, 1'b1, "BEQ_NEGATIVE_OFFSET");

        if (errors == 0)
            $display("\nALL BRANCH_UNIT TESTS PASSED\n");
        else
            $display("\nBRANCH_UNIT TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
