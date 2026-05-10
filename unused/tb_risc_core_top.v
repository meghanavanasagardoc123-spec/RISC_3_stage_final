`timescale 1ns/1ps

module tb_risc_core_top;

    reg clk;
    reg rst_n;

    integer errors;

    // DUT
    risc_core_top uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // helper task
    task check_val;
        input [255:0] testname;
        input [31:0]  got;
        input [31:0]  exp;
        begin
            if (got !== exp) begin
                $display("FAIL: %0s | got = %h | exp = %h | time = %0t", testname, got, exp, $time);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | value = %h | time = %0t", testname, got, $time);
            end
        end
    endtask

    task check_bit;
        input [255:0] testname;
        input         got;
        input         exp;
        begin
            if (got !== exp) begin
                $display("FAIL: %0s | got = %b | exp = %b | time = %0t", testname, got, exp, $time);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | value = %b | time = %0t", testname, got, $time);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_risc_core_top.vcd");
        $dumpvars(0, tb_risc_core_top);

        errors = 0;
        rst_n  = 1'b0;

        // reset
        #20;
        rst_n = 1'b1;

        // wait some cycles
        repeat (8) @(posedge clk);

        // -----------------------------
        // Basic sanity checks
        // -----------------------------
        check_bit("RESET released", rst_n, 1'b1);

        // PC should not remain zero forever after reset, if fetch is working
        check_bit("PC changed from reset value", (uut.pc_if != 32'b0), 1'b1);

        // pc_plus4 check
        check_val("pc_plus4_if = pc_if + 4", uut.pc_plus4_if, uut.pc_if + 32'd4);

        // IF/ID register capture check when not stalled
        if (uut.stall_if_id == 1'b0) begin
            check_val("IF/ID pc capture", uut.pc_id, uut.pc_if);
            check_val("IF/ID pc+4 capture", uut.pc_plus4_id, uut.pc_plus4_if);
            check_val("IF/ID instr capture", uut.instr_id, uut.instr_if);
        end

        // Hazard outputs should never be X
        check_bit("stall_pc known",     (uut.stall_pc    !== 1'bx), 1'b1);
        check_bit("stall_if_id known",  (uut.stall_if_id !== 1'bx), 1'b1);
        check_bit("flush_id_ex known",  (uut.flush_id_ex !== 1'bx), 1'b1);

        // Writeback outputs should be known eventually
        repeat (5) @(posedge clk);
        check_bit("wb_reg_write known", (uut.wb_reg_write !== 1'bx), 1'b1);
        check_bit("branch_taken_ex known", (uut.branch_taken_ex !== 1'bx), 1'b1);

        // -----------------------------
        // Final result
        // -----------------------------
        if (errors == 0)
            $display("\n=========== ALL TESTS PASSED ===========");
        else
            $display("\n=========== TEST FAILED : %0d ERRORS ===========", errors);

        #20;
        $finish;
    end

    // timeout protection
    initial begin
        #500;
        $display("FAIL: TIMEOUT");
        $finish;
    end

endmodule
