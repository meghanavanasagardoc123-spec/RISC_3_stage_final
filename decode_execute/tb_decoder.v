`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : tb_decoder.v
Testbench   : tb_decoder
Purpose     : Self-checking testbench for decoder.v

What this TB verifies:
1. R-type decode for ADD, SUB, AND, OR, XOR
2. I-type decode for ADDI
3. Load decode for LW
4. Store decode for SW
5. Branch decode for BEQ and BNE
6. Jump decode for JAL
7. Custom decode for FFT_BLY
8. Illegal instruction detection

DUT inputs driven by TB:
- instr          : 32-bit instruction word

DUT outputs checked by TB:
- rs1_addr       : Source register 1 address
- rs2_addr       : Source register 2 address
- rd_addr        : Destination register address
- reg_write      : Register write enable
- mem_read       : Memory read enable
- mem_write      : Memory write enable
- branch         : Branch flag
- branch_ne      : BNE flag
- jal            : JAL flag
- fft_en         : FFT instruction enable
- alu_src        : ALU source select
- alu_op         : ALU operation control
- wb_sel         : Writeback source select
- imm_sel        : Immediate format select
- illegal_instr  : Unsupported instruction flag

Pass/Fail method:
- TB applies known instruction encodings
- TB checks important output controls and register fields
- Prints PASS/FAIL messages using $display
- Dumps waveform file for GTKWave debug

Run command (Icarus Verilog):
- Compile : iverilog -o decoder_tb decoder.v tb_decoder.v
- Run     : vvp decoder_tb
- Waveform: gtkwave tb_decoder.vcd

Notes:
- Pure Verilog testbench, no SystemVerilog features used
- Uses only current project instruction subset
------------------------------------------------------------------------------
*/

module tb_decoder;

    reg  [31:0] instr;

    wire [4:0] rs1_addr;
    wire [4:0] rs2_addr;
    wire [4:0] rd_addr;

    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire       branch;
    wire       branch_ne;
    wire       jal;
    wire       fft_en;
    wire       alu_src;
    wire [3:0] alu_op;
    wire [1:0] wb_sel;
    wire [2:0] imm_sel;
    wire       illegal_instr;

    integer errors;

    decoder uut (
        .instr         (instr),
        .rs1_addr      (rs1_addr),
        .rs2_addr      (rs2_addr),
        .rd_addr       (rd_addr),
        .reg_write     (reg_write),
        .mem_read      (mem_read),
        .mem_write     (mem_write),
        .branch        (branch),
        .branch_ne     (branch_ne),
        .jal           (jal),
        .fft_en        (fft_en),
        .alu_src       (alu_src),
        .alu_op        (alu_op),
        .wb_sel        (wb_sel),
        .imm_sel       (imm_sel),
        .illegal_instr (illegal_instr)
    );

    task check_decode;
        input [4:0] exp_rs1;
        input [4:0] exp_rs2;
        input [4:0] exp_rd;
        input       exp_reg_write;
        input       exp_mem_read;
        input       exp_mem_write;
        input       exp_branch;
        input       exp_branch_ne;
        input       exp_jal;
        input       exp_fft_en;
        input       exp_alu_src;
        input [3:0] exp_alu_op;
        input [1:0] exp_wb_sel;
        input [2:0] exp_imm_sel;
        input       exp_illegal;
        input [127:0] test_name;
        begin
            #1;
            if ((rs1_addr      !== exp_rs1)      ||
                (rs2_addr      !== exp_rs2)      ||
                (rd_addr       !== exp_rd)       ||
                (reg_write     !== exp_reg_write)||
                (mem_read      !== exp_mem_read) ||
                (mem_write     !== exp_mem_write)||
                (branch        !== exp_branch)   ||
                (branch_ne     !== exp_branch_ne)||
                (jal           !== exp_jal)      ||
                (fft_en        !== exp_fft_en)   ||
                (alu_src       !== exp_alu_src)  ||
                (alu_op        !== exp_alu_op)   ||
                (wb_sel        !== exp_wb_sel)   ||
                (imm_sel       !== exp_imm_sel)  ||
                (illegal_instr !== exp_illegal)) begin

                $display("FAIL : %s", test_name);
                $display("       instr=%h", instr);
                $display("       rs1=%0d rs2=%0d rd=%0d", rs1_addr, rs2_addr, rd_addr);
                $display("       reg_write=%b mem_read=%b mem_write=%b", reg_write, mem_read, mem_write);
                $display("       branch=%b branch_ne=%b jal=%b fft_en=%b", branch, branch_ne, jal, fft_en);
                $display("       alu_src=%b alu_op=%h wb_sel=%h imm_sel=%h illegal=%b",
                          alu_src, alu_op, wb_sel, imm_sel, illegal_instr);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_decoder.vcd");
        $dumpvars(0, tb_decoder);

        errors = 0;

        // ------------------------------------------------------
        // ADD  x5, x1, x2
        // funct7 rs2  rs1  funct3 rd   opcode
        // 0000000 00010 00001 000 00101 0110011
        // ------------------------------------------------------
        instr = 32'b0000000_00010_00001_000_00101_0110011;
        check_decode(5'd1, 5'd2, 5'd5,
                     1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b0, `ALU_ADD, `WB_ALU, `IMM_NONE, 1'b0,
                     "ADD_DECODE");

        // SUB x6, x3, x4
        instr = 32'b0100000_00100_00011_000_00110_0110011;
        check_decode(5'd3, 5'd4, 5'd6,
                     1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b0, `ALU_SUB, `WB_ALU, `IMM_NONE, 1'b0,
                     "SUB_DECODE");

        // AND x7, x8, x9
        instr = 32'b0000000_01001_01000_111_00111_0110011;
        check_decode(5'd8, 5'd9, 5'd7,
                     1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b0, `ALU_AND, `WB_ALU, `IMM_NONE, 1'b0,
                     "AND_DECODE");

        // OR x10, x11, x12
        instr = 32'b0000000_01100_01011_110_01010_0110011;
        check_decode(5'd11, 5'd12, 5'd10,
                     1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b0, `ALU_OR, `WB_ALU, `IMM_NONE, 1'b0,
                     "OR_DECODE");

        // XOR x13, x14, x15
        instr = 32'b0000000_01111_01110_100_01101_0110011;
        check_decode(5'd14, 5'd15, 5'd13,
                     1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b0, `ALU_XOR, `WB_ALU, `IMM_NONE, 1'b0,
                     "XOR_DECODE");

        // ADDI x5, x1, 10
        instr = 32'b000000001010_00001_000_00101_0010011;
        check_decode(5'd1, 5'd10, 5'd5,
                     1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b1, `ALU_ADD, `WB_ALU, `IMM_I, 1'b0,
                     "ADDI_DECODE");

        // LW x4, 8(x2)
        instr = 32'b000000001000_00010_010_00100_0000011;
        check_decode(5'd2, 5'd8, 5'd4,
                     1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b1, `ALU_ADD, `WB_MEM, `IMM_I, 1'b0,
                     "LW_DECODE");

        // SW x4, 12(x2)
        instr = 32'b0000000_00100_00010_010_01100_0100011;
        check_decode(5'd2, 5'd4, 5'd12,
                     1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b1, `ALU_ADD, `WB_ALU, `IMM_S, 1'b0,
                     "SW_DECODE");

        // BEQ x1, x2, offset
        instr = 32'b0000000_00010_00001_000_00000_1100011;
        check_decode(5'd1, 5'd2, 5'd0,
                     1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0,
                     1'b0, `ALU_SUB, `WB_ALU, `IMM_B, 1'b0,
                     "BEQ_DECODE");

        // BNE x3, x4, offset
        instr = 32'b0000000_00100_00011_001_00000_1100011;
        check_decode(5'd3, 5'd4, 5'd0,
                     1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0,
                     1'b0, `ALU_SUB, `WB_ALU, `IMM_B, 1'b0,
                     "BNE_DECODE");

        // JAL x1, offset
        instr = 32'b00000000000000000000_00001_1101111;
        check_decode(5'd0, 5'd0, 5'd1,
                     1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0,
                     1'b0, `ALU_ADD, `WB_PC4, `IMM_J, 1'b0,
                     "JAL_DECODE");

        // FFT_BLY x5, x1, x2
        instr = 32'b0000001_00010_00001_000_00101_0001011;
        check_decode(5'd1, 5'd2, 5'd5,
                     1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1,
                     1'b0, `ALU_PASS, `WB_FFT, `IMM_NONE, 1'b0,
                     "FFT_DECODE");

        // Illegal instruction: unsupported R-type funct3
        instr = 32'b0000000_00010_00001_001_00101_0110011;
        check_decode(5'd1, 5'd2, 5'd5,
                     1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
                     1'b0, `ALU_ADD, `WB_ALU, `IMM_NONE, 1'b1,
                     "ILLEGAL_RTYPE");

        if (errors == 0)
            $display("\nALL DECODER TESTS PASSED\n");
        else
            $display("\nDECODER TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
