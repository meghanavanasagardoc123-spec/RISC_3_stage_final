`timescale 1ns/1ps

module decode_execute (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,

    input  wire        wb_reg_write,
    input  wire [4:0]  wb_rd_addr,
    input  wire [31:0] wb_rd_data,

    input  wire [31:0] fwd_ex_data,
    input  wire [31:0] fwd_mem_data,
    input  wire [1:0]  fwd_a_sel,
    input  wire [1:0]  fwd_b_sel,

    output wire [31:0] exec_result_out,
    output wire [31:0] rs2_store_data_out,
    output wire [4:0]  rd_addr_out,

    output wire        reg_write_out,
    output wire        mem_read_out,
    output wire        mem_write_out,
    output wire        mem_to_reg_out,

    output wire        branch_taken_out,
    output wire [31:0] branch_target_out,
    output wire        jump_out,

    output wire        alu_src_out,
    output wire        branch_out,
    output wire [3:0]  alu_ctrl_out,
    output wire [31:0] rs1_data_out,
    output wire [31:0] rs2_data_out,
    output wire [31:0] pc_plus4_out
);
wire valid_instr;
    wire [6:0] opcode = instr_in[6:0];
    wire [4:0] rd     = instr_in[11:7];
    wire [2:0] funct3 = instr_in[14:12];
    wire [4:0] rs1    = instr_in[19:15];
    wire [4:0] rs2    = instr_in[24:20];
    wire [6:0] funct7 = instr_in[31:25];

    assign pc_plus4_out = pc_in + 32'd4;

    wire [31:0] imm_ext;
    imm_gen u_imm_gen (
        .instr   (instr_in),
        .imm_out (imm_ext)
    );

    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire       mem_to_reg;
    wire       alu_src;
    wire [3:0] alu_ctrl;
    wire       branch;
    wire       branch_ne;
    wire       jump;
    wire       fft_en;
    wire       branch_eq;

    control_unit u_control_unit (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .reg_write  (reg_write),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .alu_src    (alu_src),
        .alu_ctrl   (alu_ctrl),
        .branch     (branch),
        .branch_ne  (branch_ne),
        .jump       (jump),
        .fft_en     (fft_en),
        .valid_instr (valid_instr)
    );

    assign jump_out     = jump;
    assign alu_src_out  = alu_src;
    assign branch_out   = branch;
    assign alu_ctrl_out = alu_ctrl;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    regfile u_regfile (
        .clk          (clk),
        .rst_n        (rst_n),
        .reg_write_en (wb_reg_write),
        .rs1_addr     (rs1),
        .rs2_addr     (rs2),
        .rd_addr      (wb_rd_addr),
        .rd_wdata     (wb_rd_data),
        .rs1_rdata    (rs1_data),
        .rs2_rdata    (rs2_data)
    );

    assign rs1_data_out = rs1_data;
    assign rs2_data_out = rs2_data;

    reg [31:0] op_a;
    reg [31:0] op_b_raw;

    always @(*) begin
        case (fwd_a_sel)
            2'b00: op_a = rs1_data;
            2'b01: op_a = fwd_ex_data;
            2'b10: op_a = fwd_mem_data;
            default: op_a = rs1_data;
        endcase
    end

    always @(*) begin
        case (fwd_b_sel)
            2'b00: op_b_raw = rs2_data;
            2'b01: op_b_raw = fwd_ex_data;
            2'b10: op_b_raw = fwd_mem_data;
            default: op_b_raw = rs2_data;
        endcase
    end

    wire [31:0] op_b = alu_src ? imm_ext : op_b_raw;

    wire [31:0] alu_result;
    wire        zero_flag;

    alu u_alu (
        .a      (op_a),
        .b      (op_b),
        .alu_op (alu_ctrl),
        .result (alu_result),
        .zero   (zero_flag)
    );

    wire [31:0] fft_y0;
    wire [31:0] fft_y1;

    fft_butterfly u_fft_butterfly (
        .a_in   (op_a),
        .b_in   (op_b_raw),
        .w_in   ({16'sd23170, -16'sd23170}),
        .y0_out (fft_y0),
        .y1_out (fft_y1)
    );

    assign branch_target_out = pc_in + imm_ext;

    assign branch_taken_out =
        jump |
        (branch & ~branch_ne &  zero_flag) |
        (branch &  branch_ne & ~zero_flag);

    assign exec_result_out    = fft_en ? fft_y0 : alu_result;
    assign rs2_store_data_out = op_b_raw;
    assign rd_addr_out        = reg_write ? rd : 5'd0;

    assign reg_write_out = reg_write;
    assign mem_read_out  = mem_read;
    assign mem_write_out = mem_write;
    assign mem_to_reg_out = mem_to_reg;

endmodule
