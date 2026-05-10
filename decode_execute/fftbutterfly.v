`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : fft_butterfly.v
Module      : fft_butterfly
Purpose     : Custom single-cycle fixed-point FFT butterfly datapath
Style       : Pure RTL without functions

Packing:
- a_in = {a_real[15:0], a_imag[15:0]}
- b_in = {b_real[15:0], b_imag[15:0]}
- y_out = {y_real[15:0], y_imag[15:0]}

Current operation:
- Complex add butterfly output
- y_real = saturate(a_real + b_real)
- y_imag = saturate(a_imag + b_imag)

Notes:
- Signed 16-bit fixed-point per component
- Internal sum width is 17 bits
- Saturation is implemented with explicit compare logic
------------------------------------------------------------------------------
*/

module fft_butterfly (
    input  [`XLEN-1:0] a_in,
    input  [`XLEN-1:0] b_in,
    output [`XLEN-1:0] y_out
);

    // ------------------------------------------------------------------------
    // Split packed complex inputs
    // ------------------------------------------------------------------------
    wire signed [15:0] a_real;
    wire signed [15:0] a_imag;
    wire signed [15:0] b_real;
    wire signed [15:0] b_imag;

    assign a_real = a_in[31:16];
    assign a_imag = a_in[15:0];
    assign b_real = b_in[31:16];
    assign b_imag = b_in[15:0];

    // ------------------------------------------------------------------------
    // Extended signed sums
    // ------------------------------------------------------------------------
    wire signed [16:0] sum_real_ext;
    wire signed [16:0] sum_imag_ext;

    assign sum_real_ext = a_real + b_real;
    assign sum_imag_ext = a_imag + b_imag;

    // ------------------------------------------------------------------------
    // Saturation limits
    // ------------------------------------------------------------------------
    wire signed [16:0] sat_max;
    wire signed [16:0] sat_min;

    assign sat_max = 17'sd32767;
    assign sat_min = -17'sd32768;

    // ------------------------------------------------------------------------
    // Saturated outputs
    // ------------------------------------------------------------------------
    wire [15:0] y_real;
    wire [15:0] y_imag;

    assign y_real = (sum_real_ext > sat_max) ? 16'h7FFF :
                    (sum_real_ext < sat_min) ? 16'h8000 :
                                               sum_real_ext[15:0];

    assign y_imag = (sum_imag_ext > sat_max) ? 16'h7FFF :
                    (sum_imag_ext < sat_min) ? 16'h8000 :
                                               sum_imag_ext[15:0];

    // ------------------------------------------------------------------------
    // Pack output
    // ------------------------------------------------------------------------
    assign y_out = {y_real, y_imag};

endmodule
