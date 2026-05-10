//iverilog -o core_top_tb  core_top.v fetch_stage.v decode_execute.v mem_wb.v mem_wb_reg.v wb_mux.v  pc_reg.v instr_mem.v regfile.v imm_gen.v control_unit.v alu.v fft_butterfly.v data_mem.v tb_core_top.v

//vvp core_top_tb
//gtkwave tb_core_top.vcd
`timescale 1ns/1ps

module tb_core_top;

    reg clk;
    reg rst_n;

    wire [31:0] debug_pc;
    wire [31:0] debug_instr;
    wire [31:0] debug_wb_data;
    wire        debug_wb_reg_write;

    core_top uut (
        .clk                (clk),
        .rst_n              (rst_n),
        .debug_pc           (debug_pc),
        .debug_instr        (debug_instr),
        .debug_wb_data      (debug_wb_data),
        .debug_wb_reg_write (debug_wb_reg_write)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer errors;
    integer wb_seen;
    reg [31:0] pc_prev;

    task pass;
        input [1023:0] msg;
        begin
            $display("PASS: %0s @ t=%0t", msg, $time);
        end
    endtask

    task fail;
        input [1023:0] msg;
        begin
            $display("FAIL: %0s @ t=%0t", msg, $time);
            errors = errors + 1;
            $fatal;
        end
    endtask

    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    task do_reset;
        begin
            rst_n = 1'b0;
            wait_cycles(4);
            rst_n = 1'b1;
            wait_cycles(4);
            pass("reset release");
        end
    endtask

    always @(posedge clk) begin
        if (!rst_n) begin
            pc_prev <= 32'h0;
        end else begin
            if (debug_pc != pc_prev)
                $display("INFO: PC advanced to %h at t=%0t", debug_pc, $time);
            pc_prev <= debug_pc;

            if (debug_wb_reg_write)
                wb_seen <= wb_seen + 1;
        end
    end

    initial begin
        errors = 0;
        wb_seen = 0;
        rst_n = 1'b0;

        $display("TB_START");

        wait_cycles(5);
        do_reset();

        if (debug_pc === 32'hxxxx_xxxx) fail("PC is X after reset release");
        else pass("PC is valid after reset release");

        if (debug_instr === 32'hxxxx_xxxx) fail("Instruction is X after reset release");
        else pass("Instruction is valid after reset release");

        wait_cycles(10);

        if (debug_pc == pc_prev) fail("PC did not advance");
        else pass("PC advanced");

        if (wb_seen == 0) fail("No writeback observed");
        else pass("Writeback observed");

        wait_cycles(20);

        if (debug_wb_data === 32'hxxxx_xxxx) fail("WB data is X");
        else pass("WB data valid");

        do_reset();
        wait_cycles(4);

        if (!(debug_pc == 32'h0000_1000 || debug_pc == 32'h0000_0000))
            fail("PC did not restart correctly");
        else
            pass("PC restart correct");

        wait_cycles(20);

        $display("ALL TESTS PASSED");
        $finish;
    end
always @(posedge clk) begin
    if (rst_n) begin
        if (debug_pc != pc_prev)
            $display("PASS: PC changed %h -> %h at t=%0t", pc_prev, debug_pc, $time);

        if (debug_wb_reg_write)
            $display("PASS: WB data=%h at t=%0t", debug_wb_data, $time);
    end
    pc_prev <= debug_pc;
end
initial begin
    #2000;
    $display("FAIL: timeout, PC stuck at %h instr=%h", debug_pc, debug_instr);
    $fatal;
end

endmodule
