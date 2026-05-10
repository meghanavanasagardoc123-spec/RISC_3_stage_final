`timescale 1ns/1ps

`timescale 1ns/1ps

module core_top (
    input wire clk,
    input wire rst_n,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instr,
    output wire [31:0] debug_wb_data,
    output wire        debug_wb_reg_write
);
assign debug_pc         = pc_if;
assign debug_instr      = instr_if;
assign debug_wb_data    = wb_data;
assign debug_wb_reg_write = wb_reg_write;
    wire stall_pc;
    wire stall_if_id;
    wire flush_if_id;
    wire flush_id_ex;

    wire [31:0] pc_if;
    wire [31:0] instr_if;
    wire [31:0] pc_plus4_if;

    wire [31:0] pc_id;
    wire [31:0] pc_plus4_id;
    wire [31:0] instr_id;

    wire [4:0]  id_rs1_addr;
    wire [4:0]  id_rs2_addr;

    wire [31:0] rs1_data_dec;
    wire [31:0] rs2_data_dec;
    wire [31:0] exec_result_dec;
    wire [31:0] rs2_store_data_dec;
    wire [4:0]  rd_addr_dec;
    wire [31:0] pc_plus4_dec;

    wire        reg_write_dec;
    wire        mem_read_dec;
    wire        mem_write_dec;
    wire        mem_to_reg_dec;
    wire        alu_src_dec;
    wire        branch_dec;
    wire [3:0]  alu_ctrl_dec;

    wire [31:0] pc_ex;
    wire [31:0] rs1_data_ex;
    wire [31:0] rs2_data_ex;
    wire [4:0]  rs1_addr_ex;
    wire [4:0]  rs2_addr_ex;
    wire [4:0]  rd_addr_ex;

    wire        reg_write_ex;
    wire        mem_read_ex;
    wire        mem_write_ex;
    wire        mem_to_reg_ex;
    wire        alu_src_ex;
    wire        branch_ex;
    wire [3:0]  alu_ctrl_ex;

    wire [31:0] branch_target_ex;
    wire        branch_taken_ex;
    wire        jump_out;

    wire [31:0] fwd_ex_data;
    wire [31:0] fwd_mem_data;
    wire [1:0]  fwd_a_sel;
    wire [1:0]  fwd_b_sel;

    wire [31:0] mem_read_data_mem;
    wire [31:0] wb_data;
    wire [4:0]  wb_rd_addr;
    wire        wb_reg_write;

    assign fwd_ex_data  = exec_result_dec;
    assign fwd_mem_data = wb_data;

    assign flush_if_id = branch_taken_ex | jump_out;

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

    if_id_reg u_if_id_reg (
        .clk          (clk),
        .rst_n        (rst_n),
        .stall        (stall_if_id),
        .flush        (flush_if_id),
        .pc_in        (pc_if),
        .pc_plus4_in  (pc_plus4_if),
        .instr_in     (instr_if),
        .pc_out       (pc_id),
        .pc_plus4_out (pc_plus4_id),
        .instr_out    (instr_id)
    );

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
        .exec_result_out   (exec_result_dec),
        .rs2_store_data_out(rs2_store_data_dec),
        .rd_addr_out       (rd_addr_dec),
        .reg_write_out     (reg_write_dec),
        .mem_read_out      (mem_read_dec),
        .mem_write_out     (mem_write_dec),
        .mem_to_reg_out    (mem_to_reg_dec),
        .branch_taken_out  (branch_taken_ex),
        .branch_target_out (branch_target_ex),
        .jump_out          (jump_out),
        .alu_src_out       (alu_src_dec),
        .branch_out        (branch_dec),
        .alu_ctrl_out      (alu_ctrl_dec),
        .rs1_data_out      (rs1_data_dec),
        .rs2_data_out      (rs2_data_dec),
        .pc_plus4_out      (pc_plus4_dec)
    );

    id_ex_reg u_id_ex_reg (
        .clk           (clk),
        .rst_n         (rst_n),
        .stall         (stall_if_id),
        .flush         (flush_id_ex),
        .pc_in         (pc_id),
        .rs1_data_in   (rs1_data_dec),
        .rs2_data_in   (rs2_data_dec),
        .rs1_addr_in   (id_rs1_addr),
        .rs2_addr_in   (id_rs2_addr),
        .rd_addr_in    (rd_addr_dec),
        .reg_write_in  (reg_write_dec),
        .mem_read_in   (mem_read_dec),
        .mem_write_in  (mem_write_dec),
        .mem_to_reg_in (mem_to_reg_dec),
        .alu_src_in    (alu_src_dec),
        .branch_in     (branch_dec),
        .alu_ctrl_in   (alu_ctrl_dec),
        .pc_out        (pc_ex),
        .rs1_data_out  (rs1_data_ex),
        .rs2_data_out  (rs2_data_ex),
        .rs1_addr_out  (rs1_addr_ex),
        .rs2_addr_out  (rs2_addr_ex),
        .rd_addr_out   (rd_addr_ex),
        .reg_write_out  (reg_write_ex),
        .mem_read_out   (mem_read_ex),
        .mem_write_out  (mem_write_ex),
        .mem_to_reg_out (mem_to_reg_ex),
        .alu_src_out    (alu_src_ex),
        .branch_out     (branch_ex),
        .alu_ctrl_out   (alu_ctrl_ex)
    );

    hazard_unit u_hazard_unit (
        .id_rs1_addr (id_rs1_addr),
        .id_rs2_addr (id_rs2_addr),
        .ex_rd_addr  (rd_addr_ex),
        .ex_mem_read (mem_read_ex),
        .stall_pc    (stall_pc),
        .stall_if_id (stall_if_id),
        .flush_id_ex (flush_id_ex)
    );

    forward_unit u_forward_unit (
        .ex_rs1_addr     (rs1_addr_ex),
        .ex_rs2_addr     (rs2_addr_ex),
        .exmem_rd_addr   (rd_addr_ex),
        .exmem_reg_write (reg_write_ex),
        .memwb_rd_addr   (wb_rd_addr),
        .memwb_reg_write (wb_reg_write),
        .forward_a_sel   (fwd_a_sel),
        .forward_b_sel   (fwd_b_sel)
    );

    data_mem u_data_mem (
        .clk        (clk),
        .mem_read   (mem_read_ex),
        .mem_write  (mem_write_ex),
        .addr_in    (exec_result_dec),
        .write_data (rs2_data_ex),
        .read_data  (mem_read_data_mem)
    );

    mem_wb u_mem_wb (
        .clk              (clk),
        .rst_n            (rst_n),
        .mem_read_data_in (mem_read_data_mem),
        .alu_result_in    (exec_result_dec),
        .pc_plus4_in      (pc_plus4_dec),
        .rd_addr_in       (rd_addr_ex),
        .reg_write_in     (reg_write_ex),
        .mem_to_reg_in    (mem_to_reg_ex),
        .jump_in          (jump_out),
        .wb_data_out      (wb_data),
        .wb_rd_addr_out   (wb_rd_addr),
        .wb_reg_write_out (wb_reg_write)
    );

    assign id_rs1_addr = instr_if[19:15];
    assign id_rs2_addr = instr_if[24:20];

endmodule
