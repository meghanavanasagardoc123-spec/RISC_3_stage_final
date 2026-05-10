`timescale 1ns/1ps

module mem_wb (
    input  wire        clk,
    input  wire        rst_n,

    // Inputs from MEM stage
    input  wire [31:0] mem_read_data_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [4:0]  rd_addr_in,

    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,
    input  wire        jump_in,

    // Outputs to register file
    output wire [31:0] wb_data_out,
    output wire [4:0]  wb_rd_addr_out,
    output wire        wb_reg_write_out
);

    wire [31:0] mem_read_data_w;
    wire [31:0] alu_result_w;
    wire [31:0] pc_plus4_w;
    wire [4:0]  rd_addr_w;

    wire        reg_write_w;
    wire        mem_to_reg_w;
    wire        jump_w;

    mem_wb_reg u_mem_wb_reg (
        .clk              (clk),
        .rst_n            (rst_n),
        .mem_read_data_in (mem_read_data_in),
        .alu_result_in    (alu_result_in),
        .pc_plus4_in      (pc_plus4_in),
        .rd_addr_in       (rd_addr_in),
        .reg_write_in     (reg_write_in),
        .mem_to_reg_in    (mem_to_reg_in),
        .jump_in          (jump_in),
        .mem_read_data_out(mem_read_data_w),
        .alu_result_out   (alu_result_w),
        .pc_plus4_out     (pc_plus4_w),
        .rd_addr_out      (rd_addr_w),
        .reg_write_out    (reg_write_w),
        .mem_to_reg_out   (mem_to_reg_w),
        .jump_out         (jump_w)
    );

    wb_mux u_wb_mux (
        .mem_data   (mem_read_data_w),
        .alu_data   (alu_result_w),
        .pc_plus4   (pc_plus4_w),
        .mem_to_reg (mem_to_reg_w),
        .jump       (jump_w),
        .wb_data    (wb_data_out)
    );

    assign wb_rd_addr_out   = rd_addr_w;
    assign wb_reg_write_out = reg_write_w;

endmodule
