`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : tb_if_id_reg.v
Testbench   : tb_if_id_reg
Purpose     : Self-checking testbench for if_id_reg.v

What this TB verifies:
1. Reset clears all registered outputs
2. Normal clocked transfer from IF stage to ID stage
3. Stall holds previous values
4. Flush clears outputs and inserts bubble
5. Flush has priority over stall
6. Register updates resume after flush/stall are removed

DUT inputs driven by TB:
- clk           : Clock input
- rst_n         : Active-low reset
- stall         : Holds current IF/ID values when asserted
- flush         : Clears IF/ID values when asserted
- pc_in         : Input PC from fetch stage
- pc_plus4_in   : Input PC+4 from fetch stage
- instr_in      : Input fetched instruction

DUT outputs checked by TB:
- pc_out        : Registered PC to decode stage
- pc_plus4_out  : Registered PC+4 to decode stage
- instr_out     : Registered instruction to decode stage

Pass/Fail method:
- TB drives directed input/control combinations
- TB checks outputs after relevant clock edges
- Prints PASS/FAIL messages using $display
- Dumps waveform file for GTKWave debug

Run command (Icarus Verilog):
- Compile : iverilog -o if_id_tb if_id_reg.v tb_if_id_reg.v
- Run     : vvp if_id_tb
- Waveform: gtkwave tb_if_id_reg.vcd

Notes:
- Pure Verilog testbench, no SystemVerilog features used
- This TB checks IF/ID register behavior only, not hazard detection logic
------------------------------------------------------------------------------
*/

module tb_if_id_reg;

    reg              clk;
    reg              rst_n;
    reg              stall;
    reg              flush;
    reg  [`XLEN-1:0] pc_in;
    reg  [`XLEN-1:0] pc_plus4_in;
    reg  [31:0]      instr_in;

    wire [`XLEN-1:0] pc_out;
    wire [`XLEN-1:0] pc_plus4_out;
    wire [31:0]      instr_out;

    integer errors;

    if_id_reg uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .stall       (stall),
        .flush       (flush),
        .pc_in       (pc_in),
        .pc_plus4_in (pc_plus4_in),
        .instr_in    (instr_in),
        .pc_out      (pc_out),
        .pc_plus4_out(pc_plus4_out),
        .instr_out   (instr_out)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_if_id;
        input [`XLEN-1:0] exp_pc;
        input [`XLEN-1:0] exp_pc4;
        input [31:0]      exp_instr;
        input [127:0]     test_name;
        begin
            #1;
            if ((pc_out       !== exp_pc)   ||
                (pc_plus4_out !== exp_pc4)  ||
                (instr_out    !== exp_instr)) begin
                $display("FAIL : %s", test_name);
                $display("       stall=%b flush=%b rst_n=%b", stall, flush, rst_n);
                $display("       expected pc_out=%h pc_plus4_out=%h instr_out=%h",
                         exp_pc, exp_pc4, exp_instr);
                $display("       got      pc_out=%h pc_plus4_out=%h instr_out=%h",
                         pc_out, pc_plus4_out, instr_out);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_if_id_reg.vcd");
        $dumpvars(0, tb_if_id_reg);

        errors = 0;

        // Initialize
        rst_n       = 1'b0;
        stall       = 1'b0;
        flush       = 1'b0;
        pc_in       = 32'h0000_0000;
        pc_plus4_in = 32'h0000_0000;
        instr_in    = 32'h0000_0000;

        // ------------------------------------------------------
        // Test 1: Reset clears outputs
        // ------------------------------------------------------
        #2;
        check_if_id(32'h0000_0000, 32'h0000_0000, 32'h0000_0000, "RESET_CLEAR");

        // Release reset
        #8;
        rst_n = 1'b1;

        // ------------------------------------------------------
        // Test 2: Normal update
        // ------------------------------------------------------
        pc_in       = 32'h0000_1000;
        pc_plus4_in = 32'h0000_1004;
        instr_in    = 32'h00A0_8093;
        @(posedge clk);
        check_if_id(32'h0000_1000, 32'h0000_1004, 32'h00A0_8093, "NORMAL_UPDATE_1");

        // ------------------------------------------------------
        // Test 3: Another normal update
        // ------------------------------------------------------
        pc_in       = 32'h0000_1004;
        pc_plus4_in = 32'h0000_1008;
        instr_in    = 32'h0020_81B3;
        @(posedge clk);
        check_if_id(32'h0000_1004, 32'h0000_1008, 32'h0020_81B3, "NORMAL_UPDATE_2");

        // ------------------------------------------------------
        // Test 4: Stall holds previous contents
        // ------------------------------------------------------
        stall       = 1'b1;
        flush       = 1'b0;
        pc_in       = 32'h0000_2000;
        pc_plus4_in = 32'h0000_2004;
        instr_in    = 32'h1234_5678;
        @(posedge clk);
        check_if_id(32'h0000_1004, 32'h0000_1008, 32'h0020_81B3, "STALL_HOLD");

        // ------------------------------------------------------
        // Test 5: Remove stall, update resumes
        // ------------------------------------------------------
        stall       = 1'b0;
        pc_in       = 32'h0000_2000;
        pc_plus4_in = 32'h0000_2004;
        instr_in    = 32'h1234_5678;
        @(posedge clk);
        check_if_id(32'h0000_2000, 32'h0000_2004, 32'h1234_5678, "UPDATE_AFTER_STALL");

        // ------------------------------------------------------
        // Test 6: Flush clears outputs
        // ------------------------------------------------------
        flush       = 1'b1;
        stall       = 1'b0;
        pc_in       = 32'h0000_3000;
        pc_plus4_in = 32'h0000_3004;
        instr_in    = 32'hFFFF_FFFF;
        @(posedge clk);
        check_if_id(32'h0000_0000, 32'h0000_0000, 32'h0000_0000, "FLUSH_CLEAR");

        // ------------------------------------------------------
        // Test 7: Normal update after flush
        // ------------------------------------------------------
        flush       = 1'b0;
        pc_in       = 32'h0000_4000;
        pc_plus4_in = 32'h0000_4004;
        instr_in    = 32'hABCDEF01;
        @(posedge clk);
        check_if_id(32'h0000_4000, 32'h0000_4004, 32'hABCDEF01, "UPDATE_AFTER_FLUSH");

        // ------------------------------------------------------
        // Test 8: Flush priority over stall
        // ------------------------------------------------------
        stall       = 1'b1;
        flush       = 1'b1;
        pc_in       = 32'h0000_5000;
        pc_plus4_in = 32'h0000_5004;
        instr_in    = 32'hDEAD_BEEF;
        @(posedge clk);
        check_if_id(32'h0000_0000, 32'h0000_0000, 32'h0000_0000, "FLUSH_PRIORITY_OVER_STALL");

        // ------------------------------------------------------
        // Test 9: Resume after both controls removed
        // ------------------------------------------------------
        stall       = 1'b0;
        flush       = 1'b0;
        pc_in       = 32'h0000_6000;
        pc_plus4_in = 32'h0000_6004;
        instr_in    = 32'h00C5_8533;
        @(posedge clk);
        check_if_id(32'h0000_6000, 32'h0000_6004, 32'h00C5_8533, "FINAL_NORMAL_UPDATE");

        if (errors == 0)
            $display("\nALL IF_ID_REG TESTS PASSED\n");
        else
            $display("\nIF_ID_REG TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
