`timescale 1ns/1ps

module core_top (
    input  wire clk,
    input  wire rst_n
);

    // ============================================================
    // Fetch stage signals
    // ============================================================
    wire [31:0] pc_if;
    wire [31:0] instr_if;
    wire [31:0] pc_plus4_if;

   // wire        stall_if;
   wire        stall_pc;
    wire        stall_if_id;
    wire        flush_id_ex;


    wire        branch_taken_ex;
    wire [31:0] branch_target_ex;

    // ============================================================
    // Decode / Execute stage signals
    // ============================================================
    wire [4:0]  id_rs1_addr;
    wire [4:0]  id_rs2_addr;
    wire [4:0]  rd_addr_ex;


    wire [31:0] exec_result_ex;
    wire [31:0] rs2_store_data_ex;
    wire [4:0]  rd_addr_ex;

    wire        reg_write_ex;
    wire        mem_read_ex;
    wire        mem_write_ex;
    wire        mem_to_reg_ex;
    wire [31:0] pc_plus4_ex;

    // optional forwarding hooks
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
    // Temporary/default connections
    // ============================================================
    //assign stall_if     = 1'b0;      // connect hazard unit later
    assign fwd_ex_data  = 32'b0;     // connect EX forwarding later
    assign fwd_mem_data = wb_data;   // WB forwarding path
    assign fwd_a_sel    = 2'b00;     // no forwarding by default
    assign fwd_b_sel    = 2'b00;     // no forwarding by default

    // ============================================================
    // Fetch Stage
    // ============================================================
    fetch_stage u_fetch_stage (
        .clk           (clk),
        .rst_n         (rst_n),
       // .stall         (stall_if),
    	 .stall         (stall_pc),

        .branch_taken  (branch_taken_ex),
        .branch_target (branch_target_ex),
        .pc_out        (pc_if),
        .instr_out     (instr_if),
        .pc_plus4_out  (pc_plus4_if)
    );
    if_id_reg u_if_id_reg (
        .clk         (clk),
        .rst_n       (rst_n),
        .stall       (stall_if_id),
        .flush       (1'b0),
        .pc_in       (pc_if),
        .pc_plus4_in (pc_plus4_if),
        .instr_in    (instr_if),
        .pc_out      (if_id_pc),
        .pc_plus4_out(if_id_pc_plus4),
        .instr_out   (if_id_instr)
    );

    // ============================================================
    // Decode + Execute Stage
    // ============================================================
    decode_execute u_decode_execute (
        .clk               (clk),
        .rst_n             (rst_n),
        .pc_in             (if_id_pc),
        .instr_in          (instr_if),

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
    // Load-use hazard detection
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
    id_ex_reg u_id_ex_reg (
        .clk           (clk),
        .rst_n         (rst_n),
        .stall         (1'b0),
        .flush         (flush_id_ex),

        .pc_in         (if_id_pc),
        .rs1_data_in   (rs1_data_dec),
        .rs2_data_in   (rs2_data_dec),
        .imm_in        (imm_dec),
        .rs1_addr_in   (rs1_addr_dec),
        .rs2_addr_in   (rs2_addr_dec),
        .rd_addr_in    (id_ex_rd_addr),

        .reg_write_in  (reg_write_dec),
        .mem_read_in   (mem_read_dec),
        .mem_write_in  (mem_write_dec),
        .mem_to_reg_in (mem_to_reg_dec),
        .alu_src_in    (alu_src_dec),
        .branch_in     (branch_dec),
        .alu_ctrl_in   (alu_ctrl_dec),

        .pc_out        (id_ex_pc),
        .rs1_data_out  (),
        .rs2_data_out  (),
        .imm_out       (),
        .rs1_addr_out  (),
        .rs2_addr_out  (),
        .rd_addr_out   (),
        .reg_write_out (),
        .mem_read_out  (),
        .mem_write_out (),
        .mem_to_reg_out(),
        .alu_src_out   (),
        .branch_out    (),
        .alu_ctrl_out  ()
    );
    // ============================================================

    // Data Memory
    // Replace this with your exact data_mem module if ports differ
    // ============================================================
    data_mem u_data_mem (
        .clk       (clk),
        .mem_read  (mem_read_ex),
        .mem_write (mem_write_ex),
        .addr_in      (exec_result_ex),
        .write_data     (rs2_store_data_ex),
        .read_data     (mem_read_data_mem)
    );

    // ============================================================
    // MEM + WB Stage
    // jump_in is tied low for now; connect true JAL/JALR control later
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

    assign id_rs1_addr = instr_if[19:15];
    assign id_rs2_addr = instr_if[24:20];


endmodule
