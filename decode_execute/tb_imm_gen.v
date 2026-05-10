`timescale 1ns/1ps
//iverilog -o imm_tb imm_gen.v tb_imm_gen.v
//vvp imm_tb
//gtkwave tb_imm_gen.vcd

module tb_imm_gen;

    reg  [31:0] instr;
    wire [31:0] imm_out;

    integer errors;

    imm_gen uut (
        .instr   (instr),
        .imm_out (imm_out)
    );

    task check;
        input [31:0] exp;
        input [127:0] name;
        begin
            #1;
            if (imm_out !== exp) begin
                $display("FAIL : %s", name);
                $display("       instr   = %h", instr);
                $display("       expected= %h", exp);
                $display("       got     = %h", imm_out);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s  imm_out=%h", name, imm_out);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_imm_gen.vcd");
        $dumpvars(0, tb_imm_gen);

        errors = 0;

        // LW: I-type immediate
        instr = 32'h00A00083; // lw x1, 10(x0)
        check(32'd10, "I-type LW");

        // SW: S-type immediate
        instr = 32'h00502223; // sw x5, 4(x0)-style example
        check({{20{instr[31]}}, instr[31:25], instr[11:7]}, "S-type SW");

        // BEQ: B-type immediate
        instr = 32'h00208463; // beq x1, x2, example offset
        check({{19{instr[31]}},
               instr[31],
               instr[7],
               instr[30:25],
               instr[11:8],
               1'b0}, "B-type BEQ");

        // BNE: same format, different opcode
        instr = 32'h00209463; // bne x1, x2, example offset
        check({{19{instr[31]}},
               instr[31],
               instr[7],
               instr[30:25],
               instr[11:8],
               1'b0}, "B-type BNE");

        // JAL: J-type immediate
        instr = 32'h0000006F; // jal x0, 0
        check(32'd0, "J-type JAL zero offset");

        // Unsupported / R-type / FFT -> zero
        instr = 32'h002081B3; // add x3, x1, x2
        check(32'd0, "Default for R-type");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TOTAL ERRORS = %0d", errors);

        $finish;
    end

endmodule
