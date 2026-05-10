`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
Checked
------------------------------------------------------------------------------
File        : tb_pc_reg.v
Testbench   : tb_pc_reg
Purpose     : Self-checking testbench for pc_reg.v

What this TB verifies:
1. PC resets to RESET_PC
2. PC updates to next_pc on clock edge
3. PC holds value when stall is asserted
4. PC resumes updating after stall is deasserted

DUT inputs driven by TB:
- clk        : Clock input
- rst_n      : Active-low reset
- stall      : Hold current PC when asserted
- next_pc    : Next PC value to load

DUT outputs checked by TB:
- pc_out     : Current Program Counter value

Pass/Fail method:
- TB drives reset, next_pc, and stall
- TB checks pc_out after relevant clock edges
- Prints PASS/FAIL messages using $display
- Dumps waveform file for GTKWave debug

Run command (Icarus Verilog):
- Compile : iverilog -o pc_tb pc_reg.v tb_pc_reg.v
- Run     : vvp pc_tb
- Waveform: gtkwave tb_pc_reg.vcd

Notes:
- Pure Verilog testbench, no SystemVerilog features used
- This TB checks only the PC register, not next-PC selection logic
------------------------------------------------------------------------------
*/

module tb_pc_reg;

    reg              clk;
    reg              rst_n;
    reg              stall;
    reg  [`XLEN-1:0] next_pc;

    wire [`XLEN-1:0] pc_out;

    integer errors;

    pc_reg uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .stall   (stall),
        .next_pc (next_pc),
        .pc_out  (pc_out)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_pc;
        input [`XLEN-1:0] expected_pc;
        input [127:0]     test_name;
        begin
            #1;
            if (pc_out !== expected_pc) begin
                $display("FAIL : %s", test_name);
                $display("       rst_n=%b stall=%b next_pc=%h", rst_n, stall, next_pc);
                $display("       expected pc_out=%h", expected_pc);
                $display("       got      pc_out=%h", pc_out);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s  pc_out=%h", test_name, pc_out);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_pc_reg.vcd");
        $dumpvars(0, tb_pc_reg);

        errors = 0;

        // Initialize
        rst_n   = 1'b0;
        stall   = 1'b0;
        next_pc = 32'h0000_0000;

        // ------------------------------------------------------
        // Test 1: Reset should force PC to RESET_PC
        // ------------------------------------------------------
        #2;
        check_pc(`RESET_PC, "ASYNC_RESET_VALUE");

        // Release reset
        #8;
        rst_n = 1'b1;

        // ------------------------------------------------------
        // Test 2: Normal PC update
        // ------------------------------------------------------
        next_pc = 32'h0000_0004;
        @(posedge clk);
        check_pc(32'h0000_0004, "NORMAL_UPDATE_1");

        next_pc = 32'h0000_0008;
        @(posedge clk);
        check_pc(32'h0000_0008, "NORMAL_UPDATE_2");

        // ------------------------------------------------------
        // Test 3: Stall should hold PC
        // ------------------------------------------------------
        stall   = 1'b1;
        next_pc = 32'h0000_0010;
        @(posedge clk);
        check_pc(32'h0000_0008, "STALL_HOLDS_PC");

        // ------------------------------------------------------
        // Test 4: Remove stall, PC should update again
        // ------------------------------------------------------
        stall   = 1'b0;
        next_pc = 32'h0000_0010;
        @(posedge clk);
        check_pc(32'h0000_0010, "UPDATE_AFTER_STALL");

        // ------------------------------------------------------
        // Test 5: Another normal update
        // ------------------------------------------------------
        next_pc = 32'h0000_0020;
        @(posedge clk);
        check_pc(32'h0000_0020, "NORMAL_UPDATE_3");

        // ------------------------------------------------------
        // Test 6: Assert reset again during operation
        // ------------------------------------------------------
        #2;
        rst_n = 1'b0;
        check_pc(`RESET_PC, "RESET_DURING_OPERATION");

        if (errors == 0)
            $display("\nALL PC_REG TESTS PASSED\n");
        else
            $display("\nPC_REG TESTS FAILED : total errors = %0d\n", errors);
       #1000;
        $finish;
    end

endmodule
