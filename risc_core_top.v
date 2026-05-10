`timescale 1ns/1ps
`include "riscv_defines.vh"

module risc_core_top (
    input  wire clk,
    input  wire rst_n
);

    // ============================================================
    // Fetch stage signals
    // ============================================================
    wire [31:0] pc_if;
    wire [31:0] instr_if;
    wire [31:0] pc_plus4_if;

    // ============================================================
    // IF/ID pipeline register signals
    // ============================================================
    wire [31:0] pc_id;
    wire [31:0] instr_id;
    wire [31:0] pc_plus4_id;

    // ============================================================
    // Hazard control signals
    // ============================================================
    wire        stall_pc;
    wire        stall_if_id;
    wire        flush_if_id;
    wire        flush_id_ex;

    // ============================================================
    // Branch signals from decode/execute
    // ============================================================
    wire        branch_taken_ex;
    wire [31:0] branch_target_ex;

    // ============================================================
    // Hazard unit address signals
    // ============================================================
    wire [4:0]  id_rs1_addr;
    wire [4:0]  id_rs2_addr;

    // ============================================================
    // Decode/Execute output signals
    // ============================================================
    wire [31:0] exec_result_ex;
    wire [31:0] rs2_store_data_ex;
    wire [4:0]  rd_addr_ex;

    wire        reg_write_ex;
    wire        mem_read_ex;
    wire        mem_write_ex;
    wire        mem_to_reg_ex;
    wire [31:0] pc_plus4_ex;

    // ============================================================
    // Forwarding hooks
    // ============================================================
    wire [31:0] fwd_ex_data;
    wire [31:0] fwd_mem_data;
    wire [1:0]  fwd_a_sel;
    wire [1:0]  fwd_b_sel;

    // ============================================================
    // Memory stage signals
    // ============================================================
    wire [31:0] mem_read_data_mem;

    // ============================================================
    // Writeback stage signals
    // ============================================================
    wire [31:0] wb_data;
    wire [4:0]  wb_rd_addr;
    wire        wb_reg_write;

    // ============================================================
    // Default forwarding assignments
    // ============================================================
    assign fwd_ex_data  = 32'b0;
    assign fwd_mem_data = wb_data;
    assign fwd_a_sel    = 2'b00;
    assign fwd_b_sel    = 2'b00;

    // ============================================================
    // Hazard address extraction from IF/ID instruction
    // ============================================================
    assign id_rs1_addr = instr_id[19:15];
    assign id_rs2_addr = instr_id[24:20];

    // ============================================================
    // Flush logic
    // Branch taken should flush wrong-path instruction in IF/ID
    // ============================================================
    assign flush_if_id = branch_taken_ex;

    // ============================================================
    // Fetch Stage
    // ============================================================
    fetch_stage u_fetch_stage (
        .clk           (clk),
        .rst_n         (rst_n),
        .stall         (stall_pc),
        .branch_taken  (branch_taken_ex),
        .branch_target (branch_target_ex),
        .pc_out        (pc_if),
        .instr_out     (instr_if),
        .pc_plus4_out  (pc_plus4_if)
    );

    // ============================================================
    // IF/ID Pipeline Register
    // ============================================================
    if_id_reg u_if_id_reg (
        .clk         (clk),
        .rst_n       (rst_n),
        .stall       (stall_if_id),
        .flush       (flush_if_id),
        .pc_in       (pc_if),
        .pc_plus4_in (pc_plus4_if),
        .instr_in    (instr_if),
        .pc_out      (pc_id),
        .pc_plus4_out(pc_plus4_id),
        .instr_out   (instr_id)
    );

    // ============================================================
    // Decode + Execute Stage
    // Note: This module is assumed to internally include decode,
    // control, register file, immediate generation, execute logic,
    // and ID/EX pipeline behavior if needed.
    // ============================================================
    decode_execute u_decode_execute (
        .clk               (clk),
        .rst_n             (rst_n),
        .pc_in             (pc_id),
        .instr_in          (instr_id),

        .wb_reg_write      (wb_reg_write),
        .wb_rd_addr        (wb_rd_addr),
        .wb_rd_data        (wb_data),

        .fwd_ex_data       (fwd_ex_data),
        .fwd_mem_data      (fwd_mem_data),
        .fwd_a_sel         (fwd_a_sel),
        .fwd_b_sel         (fwd_b_sel),

        .exec_result_out   (exec_result_ex),
        .rs2_store_data_out(rs2_store_data_ex),
        .rd_addr_out       (rd_addr_ex),

        .reg_write_out     (reg_write_ex),
        .mem_read_out      (mem_read_ex),
        .mem_write_out     (mem_write_ex),
        .mem_to_reg_out    (mem_to_reg_ex),

        .branch_taken_out  (branch_taken_ex),
        .branch_target_out (branch_target_ex),

        .pc_plus4_out      (pc_plus4_ex)
    );

    // ============================================================
    // Hazard Unit
    // Detect load-use hazard using current decode instruction
    // and destination register from execute stage
    // ============================================================
    hazard_unit u_hazard_unit (
        .id_rs1_addr (id_rs1_addr),
        .id_rs2_addr (id_rs2_addr),
        .ex_rd_addr  (rd_addr_ex),
        .ex_mem_read (mem_read_ex),
        .stall_pc    (stall_pc),
        .stall_if_id (stall_if_id),
        .flush_id_ex (flush_id_ex)
    );

    // ============================================================
    // Data Memory
    // ============================================================
    data_mem u_data_mem (
        .clk        (clk),
        .mem_read   (mem_read_ex),
        .mem_write  (mem_write_ex),
        .addr_in    (exec_result_ex),
        .write_data (rs2_store_data_ex),
        .read_data  (mem_read_data_mem)
    );

    // ============================================================
    // MEM/WB Stage
    // jump_in tied to 0 for now
    // ============================================================
    mem_wb u_mem_wb (
        .clk              (clk),
        .rst_n            (rst_n),
        .mem_read_data_in (mem_read_data_mem),
        .alu_result_in    (exec_result_ex),
        .pc_plus4_in      (pc_plus4_ex),
        .rd_addr_in       (rd_addr_ex),
        .reg_write_in     (reg_write_ex),
        .mem_to_reg_in    (mem_to_reg_ex),
        .jump_in          (1'b0),
        .wb_data_out      (wb_data),
        .wb_rd_addr_out   (wb_rd_addr),
        .wb_reg_write_out (wb_reg_write)
    );

endmodule
