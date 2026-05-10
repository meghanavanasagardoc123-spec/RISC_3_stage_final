`timescale 1ns/1ps
//iverilog -o cu_tb control_unit.v tb_control_unit.v
//vvp cu_tb
//gtkwave tb_control_unit.vcd

module tb_control_unit;

    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;

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
    wire       valid_instr;

    integer errors;

    control_unit uut (
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

    task check;
        input exp_reg_write;
        input exp_mem_read;
        input exp_mem_write;
        input exp_mem_to_reg;
        input exp_alu_src;
        input [3:0] exp_alu_ctrl;
        input exp_branch;
        input exp_branch_ne;
        input exp_jump;
        input exp_fft_en;
        input exp_valid;
        input [127:0] name;
        begin
            #1;
            if ((reg_write   !== exp_reg_write) ||
                (mem_read    !== exp_mem_read)  ||
                (mem_write   !== exp_mem_write) ||
                (mem_to_reg  !== exp_mem_to_reg)||
                (alu_src     !== exp_alu_src)   ||
                (alu_ctrl    !== exp_alu_ctrl)  ||
                (branch      !== exp_branch)    ||
                (branch_ne   !== exp_branch_ne) ||
                (jump        !== exp_jump)      ||
                (fft_en      !== exp_fft_en)    ||
                (valid_instr !== exp_valid)) begin
                $display("FAIL : %s", name);
                $display("  opcode=%b funct3=%b funct7=%b", opcode, funct3, funct7);
                $display("  got: rw=%b mr=%b mw=%b m2r=%b as=%b alu=%b br=%b bne=%b j=%b fft=%b val=%b",
                         reg_write, mem_read, mem_write, mem_to_reg, alu_src, alu_ctrl, branch, branch_ne, jump, fft_en, valid_instr);
                errors = errors + 1;
            end else begin
                $display("PASS : %s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_control_unit.vcd");
        $dumpvars(0, tb_control_unit);

        errors = 0;
        opcode = 7'b0000000;
        funct3 = 3'b000;
        funct7 = 7'b0000000;

        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000;
        check(1,0,0,0,0,4'b0000,0,0,0,0,1, "R-type ADD");

        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0100000;
        check(1,0,0,0,0,4'b0001,0,0,0,0,1, "R-type SUB");

        opcode = 7'b0110011; funct3 = 3'b111; funct7 = 7'b0000000;
        check(1,0,0,0,0,4'b0010,0,0,0,0,1, "R-type AND");

        opcode = 7'b0110011; funct3 = 3'b110; funct7 = 7'b0000000;
        check(1,0,0,0,0,4'b0011,0,0,0,0,1, "R-type OR");

        opcode = 7'b0110011; funct3 = 3'b100; funct7 = 7'b0000000;
        check(1,0,0,0,0,4'b0100,0,0,0,0,1, "R-type XOR");

        opcode = 7'b0000011; funct3 = 3'b010; funct7 = 7'b0000000;
        check(1,1,0,1,1,4'b0000,0,0,0,0,1, "LW");

        opcode = 7'b0100011; funct3 = 3'b010; funct7 = 7'b0000000;
        check(0,0,1,0,1,4'b0000,0,0,0,0,1, "SW");

        opcode = 7'b1100011; funct3 = 3'b000; funct7 = 7'b0000000;
        check(0,0,0,0,0,4'b0001,1,0,0,0,1, "BEQ");

        opcode = 7'b1100011; funct3 = 3'b001; funct7 = 7'b0000000;
        check(0,0,0,0,0,4'b0001,1,1,0,0,1, "BNE");

        opcode = 7'b1101111; funct3 = 3'b000; funct7 = 7'b0000000;
        check(1,0,0,0,0,4'b0000,0,0,1,0,1, "JAL");

        opcode = 7'b0111011; funct3 = 3'b000; funct7 = 7'h01;
        check(1,0,0,0,0,4'b0000,0,0,0,1,1, "Custom FFT");

        opcode = 7'b0111011; funct3 = 3'b001; funct7 = 7'h01;
        check(0,0,0,0,0,4'b0000,0,0,0,0,0, "Invalid FFT funct3");

        opcode = 7'b1111111; funct3 = 3'b000; funct7 = 7'b0000000;
        check(0,0,0,0,0,4'b0000,0,0,0,0,0, "Unknown opcode");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TOTAL ERRORS = %0d", errors);

        $finish;
    end

endmodule
