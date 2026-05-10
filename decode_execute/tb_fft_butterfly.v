`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
iverilog -o fft_tb fft_butterfly.v tb_fft_butterfly.v
vvp fft_tb
gtkwave tb_fft_butterfly.vcd
File        : tb_fft_butterfly.v
Testbench   : tb_fft_butterfly
Purpose     : Self-checking testbench for true fft_butterfly.v

DUT packing:
- a_in   = {a_real[15:0], a_imag[15:0]}
- b_in   = {b_real[15:0], b_imag[15:0]}
- y0_out = {sum_real[15:0],  sum_imag[15:0]}
- y1_out = {diff_real[15:0], diff_imag[15:0]}

Test coverage:
1. Positive-value butterfly
2. Mixed signed-value butterfly
3. Positive saturation
4. Negative saturation
5. Zero-result difference case
------------------------------------------------------------------------------
*/

module tb_fft_butterfly;

    reg  [`XLEN-1:0] a_in;
    reg  [`XLEN-1:0] b_in;

    wire [`XLEN-1:0] y0_out;
    wire [`XLEN-1:0] y1_out;

    integer errors;

    fft_butterfly uut (
        .a_in  (a_in),
        .b_in  (b_in),
        .y0_out(y0_out),
        .y1_out(y1_out)
    );

    task apply_inputs;
        input [15:0] a_real;
        input [15:0] a_imag;
        input [15:0] b_real;
        input [15:0] b_imag;
        begin
            a_in = {a_real, a_imag};
            b_in = {b_real, b_imag};
            #1;
        end
    endtask

    task check_outputs;
        input [15:0] exp_y0_real;
        input [15:0] exp_y0_imag;
        input [15:0] exp_y1_real;
        input [15:0] exp_y1_imag;
        input [191:0] test_name;
        reg   [31:0] exp_y0;
        reg   [31:0] exp_y1;
        begin
            exp_y0 = {exp_y0_real, exp_y0_imag};
            exp_y1 = {exp_y1_real, exp_y1_imag};

            if ((y0_out !== exp_y0) || (y1_out !== exp_y1)) begin
                $display("FAIL : %s", test_name);
                $display("       got  y0=%h y1=%h", y0_out, y1_out);
                $display("       exp  y0=%h y1=%h", exp_y0, exp_y1);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_fft_butterfly.vcd");
        $dumpvars(0, tb_fft_butterfly);

        errors = 0;

        // ------------------------------------------------------
        // Test 1: Simple positive values
        // a = (10 + j20), b = (3 + j4)
        // y0 = (13 + j24), y1 = (7 + j16)
        // ------------------------------------------------------
        apply_inputs(16'd10, 16'd20, 16'd3, 16'd4);
        check_outputs(16'd13, 16'd24, 16'd7, 16'd16, "POSITIVE_VALUES");

        // ------------------------------------------------------
        // Test 2: Mixed signed values
        // a = (-10 + j5), b = (3 + j-2)
        // y0 = (-7 + j3), y1 = (-13 + j7)
        // ------------------------------------------------------
        apply_inputs(16'hFFF6, 16'd5, 16'd3, 16'hFFFE);
        check_outputs(16'hFFF9, 16'd3, 16'hFFF3, 16'd7, "MIXED_SIGNED_VALUES");

        // ------------------------------------------------------
        // Test 3: Positive saturation on sum
        // a_real = 32760, b_real = 10  => saturate to 32767
        // a_imag = 32760, b_imag = 20  => saturate to 32767
        // diff remains finite
        // ------------------------------------------------------
        apply_inputs(16'h7FF8, 16'h7FF8, 16'd10, 16'd20);
        check_outputs(16'h7FFF, 16'h7FFF, 16'h7FEE, 16'h7FE4, "POSITIVE_SATURATION");

        // ------------------------------------------------------
        // Test 4: Negative saturation on sum
        // a_real = -32760, b_real = -20 => saturate to -32768
        // a_imag = -32760, b_imag = -15 => saturate to -32768
        // diff remains finite
        // ------------------------------------------------------
        apply_inputs(16'h8008, 16'h8008, 16'hFFEC, 16'hFFF1);
        check_outputs(16'h8000, 16'h8000, 16'd12, 16'd7, "NEGATIVE_SATURATION");

        // ------------------------------------------------------
        // Test 5: Equal inputs => difference zero
        // a = b = (100 + j200)
        // y0 = (200 + j400), y1 = (0 + j0)
        // ------------------------------------------------------
        apply_inputs(16'd100, 16'd200, 16'd100, 16'd200);
        check_outputs(16'd200, 16'd400, 16'd0, 16'd0, "ZERO_DIFFERENCE");

        if (errors == 0)
            $display("\nALL FFT_BUTTERFLY TESTS PASSED\n");
        else
            $display("\nFFT_BUTTERFLY TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
