`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : tb_forward_unit.v
Testbench   : tb_forward_unit
Purpose     : Self-checking testbench for forward_unit.v

What this TB verifies:
1. No forwarding when there is no destination/source match
2. Forward from EX/MEM to operand A
3. Forward from EX/MEM to operand B
4. Forward from MEM/WB to operand A
5. Forward from MEM/WB to operand B
6. EX/MEM has priority over MEM/WB
7. No forwarding from x0
8. Independent forwarding on A and B paths

DUT inputs driven by TB:
- ex_rs1_addr      : Source register 1 in current execute stage
- ex_rs2_addr      : Source register 2 in current execute stage
- exmem_rd_addr    : Destination register in EX/MEM stage
- exmem_reg_write  : EX/MEM write enable
- memwb_rd_addr    : Destination register in MEM/WB stage
- memwb_reg_write  : MEM/WB write enable

DUT outputs checked by TB:
- forward_a_sel    : Forward select for ALU operand A
- forward_b_sel    : Forward select for ALU operand B

Forwarding select encoding:
- 2'b00 : Use register file data
- 2'b01 : Forward from MEM/WB
- 2'b10 : Forward from EX/MEM

Pass/Fail method:
- TB applies directed hazard cases
- TB checks forward_a_sel and forward_b_sel
- Prints PASS/FAIL messages using $display
- Dumps waveform file for GTKWave debug

Run command (Icarus Verilog):
- Compile : iverilog -o fwd_tb forward_unit.v tb_forward_unit.v
- Run     : vvp fwd_tb
- Waveform: gtkwave tb_forward_unit.vcd

Notes:
- Pure Verilog testbench, no SystemVerilog features used
- This TB checks forwarding control only, not actual forwarded data muxes
------------------------------------------------------------------------------
*/

module tb_forward_unit;

    reg  [4:0] ex_rs1_addr;
    reg  [4:0] ex_rs2_addr;
    reg  [4:0] exmem_rd_addr;
    reg        exmem_reg_write;
    reg  [4:0] memwb_rd_addr;
    reg        memwb_reg_write;

    wire [1:0] forward_a_sel;
    wire [1:0] forward_b_sel;

    integer errors;

    forward_unit uut (
        .ex_rs1_addr     (ex_rs1_addr),
        .ex_rs2_addr     (ex_rs2_addr),
        .exmem_rd_addr   (exmem_rd_addr),
        .exmem_reg_write (exmem_reg_write),
        .memwb_rd_addr   (memwb_rd_addr),
        .memwb_reg_write (memwb_reg_write),
        .forward_a_sel   (forward_a_sel),
        .forward_b_sel   (forward_b_sel)
    );

    task check_forward;
        input [1:0] exp_a;
        input [1:0] exp_b;
        input [127:0] test_name;
        begin
            #1;
            if ((forward_a_sel !== exp_a) || (forward_b_sel !== exp_b)) begin
                $display("FAIL : %s", test_name);
                $display("       ex_rs1_addr=%0d ex_rs2_addr=%0d", ex_rs1_addr, ex_rs2_addr);
                $display("       exmem_rd_addr=%0d exmem_reg_write=%b", exmem_rd_addr, exmem_reg_write);
                $display("       memwb_rd_addr=%0d memwb_reg_write=%b", memwb_rd_addr, memwb_reg_write);
                $display("       expected forward_a_sel=%b forward_b_sel=%b", exp_a, exp_b);
                $display("       got      forward_a_sel=%b forward_b_sel=%b", forward_a_sel, forward_b_sel);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_forward_unit.vcd");
        $dumpvars(0, tb_forward_unit);

        errors = 0;

        // ------------------------------------------------------
        // Test 1: No forwarding
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd1;
        ex_rs2_addr      = 5'd2;
        exmem_rd_addr    = 5'd3;
        exmem_reg_write  = 1'b1;
        memwb_rd_addr    = 5'd4;
        memwb_reg_write  = 1'b1;
        check_forward(2'b00, 2'b00, "NO_FORWARD");

        // ------------------------------------------------------
        // Test 2: EX/MEM forwards to A
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd5;
        ex_rs2_addr      = 5'd2;
        exmem_rd_addr    = 5'd5;
        exmem_reg_write  = 1'b1;
        memwb_rd_addr    = 5'd7;
        memwb_reg_write  = 1'b1;
        check_forward(2'b10, 2'b00, "EXMEM_TO_A");

        // ------------------------------------------------------
        // Test 3: EX/MEM forwards to B
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd1;
        ex_rs2_addr      = 5'd6;
        exmem_rd_addr    = 5'd6;
        exmem_reg_write  = 1'b1;
        memwb_rd_addr    = 5'd8;
        memwb_reg_write  = 1'b1;
        check_forward(2'b00, 2'b10, "EXMEM_TO_B");

        // ------------------------------------------------------
        // Test 4: MEM/WB forwards to A
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd9;
        ex_rs2_addr      = 5'd2;
        exmem_rd_addr    = 5'd3;
        exmem_reg_write  = 1'b1;
        memwb_rd_addr    = 5'd9;
        memwb_reg_write  = 1'b1;
        check_forward(2'b01, 2'b00, "MEMWB_TO_A");

        // ------------------------------------------------------
        // Test 5: MEM/WB forwards to B
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd1;
        ex_rs2_addr      = 5'd10;
        exmem_rd_addr    = 5'd3;
        exmem_reg_write  = 1'b1;
        memwb_rd_addr    = 5'd10;
        memwb_reg_write  = 1'b1;
        check_forward(2'b00, 2'b01, "MEMWB_TO_B");

        // ------------------------------------------------------
        // Test 6: EX/MEM priority over MEM/WB for A
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd11;
        ex_rs2_addr      = 5'd2;
        exmem_rd_addr    = 5'd11;
        exmem_reg_write  = 1'b1;
        memwb_rd_addr    = 5'd11;
        memwb_reg_write  = 1'b1;
        check_forward(2'b10, 2'b00, "EXMEM_PRIORITY_A");

        // ------------------------------------------------------
        // Test 7: EX/MEM priority over MEM/WB for B
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd1;
        ex_rs2_addr      = 5'd12;
        exmem_rd_addr    = 5'd12;
        exmem_reg_write  = 1'b1;
        memwb_rd_addr    = 5'd12;
        memwb_reg_write  = 1'b1;
        check_forward(2'b00, 2'b10, "EXMEM_PRIORITY_B");

        // ------------------------------------------------------
        // Test 8: No forwarding from x0 in EX/MEM
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd0;
        ex_rs2_addr      = 5'd0;
        exmem_rd_addr    = 5'd0;
        exmem_reg_write  = 1'b1;
        memwb_rd_addr    = 5'd0;
        memwb_reg_write  = 1'b1;
        check_forward(2'b00, 2'b00, "NO_FORWARD_X0");

        // ------------------------------------------------------
        // Test 9: Independent A/B forwarding paths
        // A from EX/MEM, B from MEM/WB
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd13;
        ex_rs2_addr      = 5'd14;
        exmem_rd_addr    = 5'd13;
        exmem_reg_write  = 1'b1;
        memwb_rd_addr    = 5'd14;
        memwb_reg_write  = 1'b1;
        check_forward(2'b10, 2'b01, "INDEPENDENT_A_B");

        // ------------------------------------------------------
        // Test 10: No forwarding if RegWrite is 0
        // ------------------------------------------------------
        ex_rs1_addr      = 5'd15;
        ex_rs2_addr      = 5'd16;
        exmem_rd_addr    = 5'd15;
        exmem_reg_write  = 1'b0;
        memwb_rd_addr    = 5'd16;
        memwb_reg_write  = 1'b0;
        check_forward(2'b00, 2'b00, "NO_FORWARD_REGWRITE_0");

        if (errors == 0)
            $display("\nALL FORWARD_UNIT TESTS PASSED\n");
        else
            $display("\nFORWARD_UNIT TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
