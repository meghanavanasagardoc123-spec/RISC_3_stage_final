`timescale 1ns/1ps
//iverilog -o cu_tb control_unit.v tb_control_unit.v
//vvp cu_tb
//gtkwave tb_control_unit.vcd

module tb_control_unit;

    reg  [31:0] instr;

    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire        alu_src;
    wire [2:0]  alu_ctrl;
    wire        branch;
    wire        branch_ne;
    wire        jump;
    wire        fft_en;
    wire        valid_instr;

    integer errors;

    control_unit dut (
        .instr      (instr),
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
        .valid_instr(valid_instr)
    );

    task check;
        input [127:0] name;
        input exp_reg_write;
        input exp_mem_read;
        input exp_mem_write;
        input exp_mem_to_reg;
        input exp_alu_src;
        input [2:0] exp_alu_ctrl;
        input exp_branch;
        input exp_branch_ne;
        input exp_jump;
        input exp_fft_en;
        input exp_valid_instr;
        begin
            #1;
            if ((reg_write   !== exp_reg_write)  ||
                (mem_read    !== exp_mem_read)   ||
                (mem_write   !== exp_mem_write)  ||
                (mem_to_reg  !== exp_mem_to_reg) ||
                (alu_src     !== exp_alu_src)    ||
                (alu_ctrl    !== exp_alu_ctrl)   ||
                (branch      !== exp_branch)     ||
                (branch_ne   !== exp_branch_ne)  ||
                (jump        !== exp_jump)       ||
                (fft_en      !== exp_fft_en)     ||
                (valid_instr !== exp_valid_instr)) begin
                $display("FAIL : %s", name);
                $display("  instr=%h", instr);
                $display("  rw=%b mr=%b mw=%b m2r=%b alu_src=%b alu_ctrl=%b branch=%b branch_ne=%b jump=%b fft_en=%b valid=%b",
                         reg_write, mem_read, mem_write, mem_to_reg, alu_src,
                         alu_ctrl, branch, branch_ne, jump, fft_en, valid_instr);
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

        // R-type ADD
        instr = 32'h002081B3;
        check("ADD", 1,0,0,0,0,3'b010,0,0,0,0,1);

        // R-type SUB
        instr = 32'h402081B3;
        check("SUB", 1,0,0,0,0,3'b110,0,0,0,0,1);

        // R-type AND
        instr = 32'h0020F1B3;
        check("AND", 1,0,0,0,0,3'b000,0,0,0,0,1);

        // R-type OR
        instr = 32'h0020E1B3;
        check("OR", 1,0,0,0,0,3'b001,0,0,0,0,1);

        // R-type XOR
        instr = 32'h0020C1B3;
        check("XOR", 1,0,0,0,0,3'b011,0,0,0,0,1);

        // LW
        instr = 32'h00A00083;
        check("LW", 1,1,0,1,1,3'b010,0,0,0,0,1);

        // SW
        instr = 32'h00302023;
        check("SW", 0,0,1,0,1,3'b010,0,0,0,0,1);

        // BEQ
        instr = 32'h00208463;
        check("BEQ", 0,0,0,0,0,3'b110,1,0,0,0,1);

        // BNE
        instr = 32'h00209463;
        check("BNE", 0,0,0,0,0,3'b110,1,1,0,0,1);

        // JAL
        instr = 32'h0000006F;
        check("JAL", 1,0,0,0,0,3'b000,0,0,1,0,1);

        // FFT custom instruction
        instr = 32'h000000BB;
        check("FFT", 1,0,0,0,0,3'b000,0,0,0,1,1);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TOTAL ERRORS = %0d", errors);

        $finish;
    end

endmodule
