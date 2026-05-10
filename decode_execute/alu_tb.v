`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : tb_alu.v
Testbench   : tb_alu
Purpose     : Self-checking testbench for alu.v

What this TB verifies:
1. ADD operation
2. SUB operation
3. zero flag generation
4. AND operation
5. OR operation
6. XOR operation
7. PASS operation
8. 32-bit wraparound behavior for addition

DUT inputs driven by TB:
- a        : Operand A
- b        : Operand B
- alu_op   : Operation select

DUT outputs checked by TB:
- result   : ALU output result
- zero     : Zero flag

Pass/Fail method:
- TB compares DUT outputs with expected values
- Prints PASS/FAIL messages using $display
- Dumps waveform file for GTKWave debug

Run command (Icarus Verilog):
- Compile : iverilog -o alu_tb alu.v tb_alu.v
- Run     : vvp alu_tb
- Waveform: gtkwave tb_alu.vcd

Notes:
- Pure Verilog testbench, no SystemVerilog features used
- Suitable for Icarus Verilog flow
------------------------------------------------------------------------------
*/

module tb_alu;

    reg  [`XLEN-1:0] a;
    reg  [`XLEN-1:0] b;
    reg  [3:0]       alu_op;

    wire [`XLEN-1:0] result;
    wire             zero;

    integer errors;

    alu uut (
        .a      (a),
        .b      (b),
        .alu_op (alu_op),
        .result (result),
        .zero   (zero)
    );

    task check_result;
        input [`XLEN-1:0] expected_result;
        input             expected_zero;
        input [127:0]     test_name;
        begin
            #1;
            if ((result !== expected_result) || (zero !== expected_zero)) begin
                $display("FAIL : %s", test_name);
                $display("       a=%h b=%h alu_op=%h", a, b, alu_op);
                $display("       expected result=%h zero=%b", expected_result, expected_zero);
                $display("       got      result=%h zero=%b", result, zero);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s  result=%h zero=%b", test_name, result, zero);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);

        errors = 0;

        // ADD
        a = 32'd10; b = 32'd5; alu_op = `ALU_ADD;
        check_result(32'd15, 1'b0, "ADD_10_5");

        // SUB
        a = 32'd10; b = 32'd5; alu_op = `ALU_SUB;
        check_result(32'd5, 1'b0, "SUB_10_5");

        // SUB gives zero
        a = 32'd25; b = 32'd25; alu_op = `ALU_SUB;
        check_result(32'd0, 1'b1, "SUB_ZERO");

        // AND
        a = 32'hF0F0_F0F0; b = 32'h0FF0_00FF; alu_op = `ALU_AND;
        check_result(32'h00F0_00F0, 1'b0, "AND_TEST");

        // OR
        a = 32'hF0F0_0000; b = 32'h0FF0_00FF; alu_op = `ALU_OR;
        check_result(32'hFFF0_00FF, 1'b0, "OR_TEST");

        // XOR
        a = 32'hAAAA_5555; b = 32'hFFFF_0000; alu_op = `ALU_XOR;
        check_result(32'h5555_5555, 1'b0, "XOR_TEST");

        // PASS
        a = 32'h1234_5678; b = 32'hDEAD_BEEF; alu_op = `ALU_PASS;
        check_result(32'hDEAD_BEEF, 1'b0, "PASS_TEST");

        // ADD wraparound
        a = 32'hFFFF_FFFF; b = 32'h0000_0001; alu_op = `ALU_ADD;
        check_result(32'h0000_0000, 1'b1, "ADD_WRAP");

        if (errors == 0)
            $display("\nALL ALU TESTS PASSED\n");
        else
            $display("\nALU TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
