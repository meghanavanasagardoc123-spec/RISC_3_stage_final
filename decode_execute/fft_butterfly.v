

/*
------------------------------------------------------------------------------
// FFT Butterfly Unit
// This module performs one radix-2 FFT butterfly operation.
// It takes two complex inputs:
//   a_in = first sample
//   b_in = second sample
// The second input is first multiplied by the twiddle factor W,
// then the butterfly outputs are formed as:
//   y0 = a + (b * W)
//   y1 = a - (b * W)
// The twiddle factor is provided by the FFT controller / ROM lookup
// according to the current FFT stage and butterfly index.------------------------------------------------------------------------------
*/

module fft_butterfly (
    input  [`XLEN-1:0] a_in,
    input  [`XLEN-1:0] b_in,
    input  [`XLEN-1:0] w_in,      // Twiddle factor = {w_real, w_imag}
    output [`XLEN-1:0] y0_out,
    output [`XLEN-1:0] y1_out
);

    wire signed [15:0] a_real, a_imag;
    wire signed [15:0] b_real, b_imag;
    wire signed [15:0] w_real, w_imag;

    wire signed [31:0] mult_rr, mult_ii, mult_ri, mult_ir;
    wire signed [31:0] bw_real_full, bw_imag_full;

    wire signed [16:0] bw_real;
    wire signed [16:0] bw_imag;

    wire signed [16:0] sum_real_ext, sum_imag_ext;
    wire signed [16:0] diff_real_ext, diff_imag_ext;

    wire signed [16:0] sat_max;
    wire signed [16:0] sat_min;

    wire [15:0] sum_real_sat, sum_imag_sat;
    wire [15:0] diff_real_sat, diff_imag_sat;

    assign a_real = a_in[31:16];
    assign a_imag = a_in[15:0];
    assign b_real = b_in[31:16];
    assign b_imag = b_in[15:0];
    assign w_real = w_in[31:16];
    assign w_imag = w_in[15:0];

    // Complex multiply: b * w
    // (b_real + j*b_imag)(w_real + j*w_imag)
    // = (b_real*w_real - b_imag*w_imag) + j(b_real*w_imag + b_imag*w_real)

    assign mult_rr = b_real * w_real;
    assign mult_ii = b_imag * w_imag;
    assign mult_ri = b_real * w_imag;
    assign mult_ir = b_imag * w_real;

    assign bw_real_full = mult_rr - mult_ii;
    assign bw_imag_full = mult_ri + mult_ir;

    // Q1.15 scaling back to 16-bit range
    assign bw_real = bw_real_full >>> 15;
    assign bw_imag = bw_imag_full >>> 15;

    // Butterfly add/subtract
    assign sum_real_ext  = a_real + bw_real;
    assign sum_imag_ext  = a_imag + bw_imag;
    assign diff_real_ext = a_real - bw_real;
    assign diff_imag_ext = a_imag - bw_imag;

    assign sat_max = 17'sd32767;
    assign sat_min = -17'sd32768;

    assign sum_real_sat  = (sum_real_ext  > sat_max) ? 16'h7FFF :
                           (sum_real_ext  < sat_min) ? 16'h8000 :
                                                       sum_real_ext[15:0];

    assign sum_imag_sat  = (sum_imag_ext  > sat_max) ? 16'h7FFF :
                           (sum_imag_ext  < sat_min) ? 16'h8000 :
                                                       sum_imag_ext[15:0];

    assign diff_real_sat = (diff_real_ext > sat_max) ? 16'h7FFF :
                           (diff_real_ext < sat_min) ? 16'h8000 :
                                                       diff_real_ext[15:0];

    assign diff_imag_sat = (diff_imag_ext > sat_max) ? 16'h7FFF :
                           (diff_imag_ext < sat_min) ? 16'h8000 :
                                                       diff_imag_ext[15:0];

    assign y0_out = {sum_real_sat,  sum_imag_sat};
    assign y1_out = {diff_real_sat, diff_imag_sat};

endmodule
