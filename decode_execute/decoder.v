`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : decoder.v
Module      : decoder
Purpose     : Instruction decoder and main control generator for baseline RV32I

Functionality:
- Decodes opcode, funct3, and funct7 from the instruction
- Generates control signals for ALU, immediate generator, memory, writeback,
  branch logic, and FFT custom instruction path

Supported instructions:
- R-type  : ADD, SUB, AND, OR, XOR
- I-type  : ADDI
- LOAD    : LW
- STORE   : SW
- BRANCH  : BEQ, BNE
- JUMP    : JAL
- CUSTOM  : FFT_BLY

Major inputs:
- instr        : 32-bit instruction word

Major outputs:
- rs1_addr     : Source register 1 address
- rs2_addr     : Source register 2 address
- rd_addr      : Destination register address
- reg_write    : Register write enable
- mem_read     : Data memory read enable
- mem_write    : Data memory write enable
- branch       : Branch instruction flag
- jal          : Jump and link flag
- fft_en       : Custom FFT instruction enable
- alu_src      : Selects register/immediate as ALU operand B
- alu_op       : ALU operation control
- wb_sel       : Writeback source select
- imm_sel      : Immediate format select
- branch_ne    : Distinguishes BNE from BEQ
- illegal_instr: Asserted for unsupported instruction

Notes:
- Pure combinational logic
- Only supports current project instruction subset
- Branch decision itself is not made here, only branch type/control decode
------------------------------------------------------------------------------
*/

module decoder (
    input  [31:0] instr,

    output [4:0]  rs1_addr,
    output [4:0]  rs2_addr,
    output [4:0]  rd_addr,

    output reg    reg_write,
    output reg    mem_read,
    output reg    mem_write,
    output reg    branch,
    output reg    branch_ne,
    output reg    jal,
    output reg    fft_en,
    output reg    alu_src,
    output reg [3:0] alu_op,
    output reg [1:0] wb_sel,
    output reg [2:0] imm_sel,
    output reg    illegal_instr
);

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode   = instr[6:0];
    assign rd_addr  = instr[11:7];
    assign funct3   = instr[14:12];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign funct7   = instr[31:25];

    always @(*) begin
        // Default values
        reg_write     = 1'b0;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        branch        = 1'b0;
        branch_ne     = 1'b0;
        jal           = 1'b0;
        fft_en        = 1'b0;
        alu_src       = 1'b0;
        alu_op        = `ALU_ADD;
        wb_sel        = `WB_ALU;
        imm_sel       = `IMM_NONE;
        illegal_instr = 1'b0;

        case (opcode)

            // --------------------------------------------------
            // R-type: ADD, SUB, AND, OR, XOR
            // --------------------------------------------------
            `OPCODE_OP: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                wb_sel    = `WB_ALU;
                imm_sel   = `IMM_NONE;

                case (funct3)
                    `FUNCT3_ADD_SUB: begin
                        if (funct7 == `FUNCT7_ADD)
                            alu_op = `ALU_ADD;
                        else if (funct7 == `FUNCT7_SUB)
                            alu_op = `ALU_SUB;
                        else
                            illegal_instr = 1'b1;
                    end

                    `FUNCT3_AND: begin
                        if (funct7 == `FUNCT7_LOGIC)
                            alu_op = `ALU_AND;
                        else
                            illegal_instr = 1'b1;
                    end

                    `FUNCT3_OR: begin
                        if (funct7 == `FUNCT7_LOGIC)
                            alu_op = `ALU_OR;
                        else
                            illegal_instr = 1'b1;
                    end

                    `FUNCT3_XOR: begin
                        if (funct7 == `FUNCT7_LOGIC)
                            alu_op = `ALU_XOR;
                        else
                            illegal_instr = 1'b1;
                    end

                    default: begin
                        illegal_instr = 1'b1;
                    end
                endcase
            end

            // --------------------------------------------------
            // I-type: ADDI
            // --------------------------------------------------
            `OPCODE_OP_IMM: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                wb_sel    = `WB_ALU;
                imm_sel   = `IMM_I;

                case (funct3)
                    `FUNCT3_ADDI: alu_op = `ALU_ADD;
                    default:      illegal_instr = 1'b1;
                endcase
            end

            // --------------------------------------------------
            // LOAD: LW
            // --------------------------------------------------
            `OPCODE_LOAD: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src   = 1'b1;
                wb_sel    = `WB_MEM;
                imm_sel   = `IMM_I;
                alu_op    = `ALU_ADD;

                if (funct3 != `FUNCT3_LW)
                    illegal_instr = 1'b1;
            end

            // --------------------------------------------------
            // STORE: SW
            // --------------------------------------------------
            `OPCODE_STORE: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = `IMM_S;
                alu_op    = `ALU_ADD;

                if (funct3 != `FUNCT3_SW)
                    illegal_instr = 1'b1;
            end

            // --------------------------------------------------
            // BRANCH: BEQ, BNE
            // --------------------------------------------------
            `OPCODE_BRANCH: begin
                branch  = 1'b1;
                alu_src = 1'b0;
                imm_sel = `IMM_B;
                alu_op  = `ALU_SUB;

                case (funct3)
                    `FUNCT3_BEQ: branch_ne = 1'b0;
                    `FUNCT3_BNE: branch_ne = 1'b1;
                    default:     illegal_instr = 1'b1;
                endcase
            end

            // --------------------------------------------------
            // JAL
            // --------------------------------------------------
            `OPCODE_JAL: begin
                reg_write = 1'b1;
                jal       = 1'b1;
                wb_sel    = `WB_PC4;
                imm_sel   = `IMM_J;
            end

            // --------------------------------------------------
            // Custom FFT instruction
            // --------------------------------------------------
            `OPCODE_FFT: begin
                reg_write = 1'b1;
                fft_en    = 1'b1;
                wb_sel    = `WB_FFT;
                alu_src   = 1'b0;
                imm_sel   = `IMM_NONE;

                if ((funct3 == `FUNCT3_FFT_BLY) && (funct7 == `FUNCT7_FFT_BLY))
                    alu_op = `ALU_PASS;
                else
                    illegal_instr = 1'b1;
            end

            // --------------------------------------------------
            // Unsupported instruction
            // --------------------------------------------------
            default: begin
                illegal_instr = 1'b1;
            end
        endcase
    end

endmodule
