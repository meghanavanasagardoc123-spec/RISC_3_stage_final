//`include "pc_reg.v"
//`include "instr_mem.v"
`timescale 1ns/1ps

module fetch_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        branch_taken,
    input  wire [31:0] branch_target,
    output wire [31:0] pc_out,
    output wire [31:0] instr_out,
    output wire [31:0] pc_plus4_out
);

    wire [31:0] pc_current;
    wire [31:0] pc_next;

    assign pc_next     = branch_taken ? branch_target : (pc_current + 32'd4);
    assign pc_plus4_out = pc_current + 32'd4;

    pc_reg u_pc_reg (
        .clk     (clk),
        .rst_n   (rst_n),
        .stall   (stall),
        .next_pc (pc_next),
        .pc_out  (pc_current)
    );

    instr_mem u_instr_mem (
        .pc_in     (pc_current),
        .instr_out (instr_out)
    );

    assign pc_out = pc_current;

endmodule
