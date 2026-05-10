`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : tb_instr_mem.v
Testbench   : tb_instr_mem
Purpose     : Self-checking testbench for instr_mem.v

What this TB verifies:
1. Correct instruction fetch at PC = 0
2. Correct instruction fetch at PC = 4
3. Correct instruction fetch at later word addresses
4. Word-aligned addressing using pc_in[31:2]
5. Unmapped/default addresses return 32'h0000_0000

DUT inputs driven by TB:
- pc_in         : Current Program Counter / fetch address

DUT outputs checked by TB:
- instr_out     : 32-bit fetched instruction

Pass/Fail method:
- TB applies directed PC values
- TB checks fetched instruction against expected ROM contents
- Prints PASS/FAIL messages using $display
- Dumps waveform file for GTKWave debug

Run command (Icarus Verilog):
- Compile : iverilog -o imem_tb instr_mem.v tb_instr_mem.v
- Run     : vvp imem_tb
- Waveform: gtkwave tb_instr_mem.vcd

Notes:
- Pure Verilog testbench, no SystemVerilog features used
- This TB assumes instr_mem.v is implemented as case-based ROM
- If ROM contents are changed in instr_mem.v, expected values here must match
------------------------------------------------------------------------------
*/

module tb_instr_mem;

    reg  [`XLEN-1:0] pc_in;
    wire [31:0]      instr_out;

    integer errors;

    instr_mem uut (
        .pc_in    (pc_in),
        .instr_out(instr_out)
    );

    task check_instr;
        input [31:0] expected_instr;
        input [127:0] test_name;
        begin
            #1;
            if (instr_out !== expected_instr) begin
                $display("FAIL : %s", test_name);
                $display("       pc_in=%h", pc_in);
                $display("       expected instr_out=%h", expected_instr);
                $display("       got      instr_out=%h", instr_out);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s  instr_out=%h", test_name, instr_out);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_instr_mem.vcd");
        $dumpvars(0, tb_instr_mem);

        errors = 0;

        // ------------------------------------------------------
        // Test 1: Fetch instruction at word address 0
        // ------------------------------------------------------
        pc_in = 32'h0000_0000;
        check_instr(32'h00A00093, "FETCH_ADDR_0");

        // ------------------------------------------------------
        // Test 2: Fetch instruction at word address 1
        // ------------------------------------------------------
        pc_in = 32'h0000_0004;
        check_instr(32'h01400113, "FETCH_ADDR_1");

        // ------------------------------------------------------
        // Test 3: Fetch instruction at word address 2
        // ------------------------------------------------------
        pc_in = 32'h0000_0008;
        check_instr(32'h002081B3, "FETCH_ADDR_2");

        // ------------------------------------------------------
        // Test 4: Fetch instruction at word address 3
        // ------------------------------------------------------
        pc_in = 32'h0000_000C;
        check_instr(32'h40310233, "FETCH_ADDR_3");

        // ------------------------------------------------------
        // Test 5: Fetch instruction at word address 4
        // ------------------------------------------------------
        pc_in = 32'h0000_0010;
        check_instr(32'h00302023, "FETCH_ADDR_4");

        // ------------------------------------------------------
        // Test 6: Fetch instruction at word address 5
        // ------------------------------------------------------
        pc_in = 32'h0000_0014;
        check_instr(32'h00002283, "FETCH_ADDR_5");

        // ------------------------------------------------------
        // Test 7: Fetch instruction at word address 6
        // ------------------------------------------------------
        pc_in = 32'h0000_0018;
        check_instr(32'h00328463, "FETCH_ADDR_6");

        // ------------------------------------------------------
        // Test 8: Fetch instruction at word address 7
        // ------------------------------------------------------
        pc_in = 32'h0000_001C;
        check_instr(32'h00100313, "FETCH_ADDR_7");

        // ------------------------------------------------------
        // Test 9: Fetch instruction at word address 8
        // ------------------------------------------------------
        pc_in = 32'h0000_0020;
        check_instr(32'h0000006F, "FETCH_ADDR_8");

        // ------------------------------------------------------
        // Test 10: Unmapped address should return zero
        // ------------------------------------------------------
        pc_in = 32'h0000_0024;
        check_instr(32'h00000000, "FETCH_DEFAULT_ZERO");

        // ------------------------------------------------------
        // Test 11: Word alignment check
        // pc_in[31:2] is used, so 0x00000002 still maps to word 0
        // ------------------------------------------------------
        pc_in = 32'h0000_0002;
        check_instr(32'h00A00093, "WORD_ALIGN_ADDR_0");

        // ------------------------------------------------------
        // Test 12: Word alignment check
        // 0x00000006 maps to word 1
        // ------------------------------------------------------
        pc_in = 32'h0000_0006;
        check_instr(32'h01400113, "WORD_ALIGN_ADDR_1");

        if (errors == 0)
            $display("\nALL INSTR_MEM TESTS PASSED\n");
        else
            $display("\nINSTR_MEM TESTS FAILED : total errors = %0d\n", errors);

        #1000;$finish;
    end

endmodule
