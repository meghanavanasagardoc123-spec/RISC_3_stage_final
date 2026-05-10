
//iverilog -I ../../ -o imm_tb ../../decode_execute/imm_gen.v tb_imm_gen.v
//vvp imm_tb
//gtkwave tb_imm_gen.vcd
`timescale 1ns/1ps
`include "riscv_defines.vh"

`timescale 1ns/1ps

module tb_imm_gen;
    reg [31:0] instr;
    wire [31:0] imm_out;

    imm_gen uut (.instr(instr), .imm_out(imm_out));

    task check_imm;
        input [255:0] name;
        input [31:0]  in_instr;
        input [31:0]  expected;
        begin
            instr = in_instr;
            #1;
            if (imm_out !== expected)
                $display("FAIL: %0s | Exp: %h, Got: %h", name, expected, imm_out);
            else
                $display("PASS: %0s | Imm: %h", name, imm_out);
        end
    endtask

    initial begin
        $dumpfile("tb_imm_gen.vcd");
        $dumpvars(0, tb_imm_gen);

        $display("Starting Imm Gen Verification (Subset)...");
        
        // LW (I-Type): offset 8 (0x00802083)
        check_imm("LW_OFFSET_8", 32'h00802083, 32'h00000008);
        
        // SW (S-Type): offset 4 (0x00412223)
        check_imm("SW_OFFSET_4", 32'h00412223, 32'h00000004);
        
        // BEQ (B-Type): offset 8 (0x00810063)
        check_imm("BEQ_OFFSET_8", 32'h00810063, 32'h00000008);
        
        // JAL (J-Type): offset 20 (0x0140006f)
        check_imm("JAL_OFFSET_20", 32'h0140006f, 32'h00000014);

        $display("Verification finished.");
        $finish;
    end
endmodule
