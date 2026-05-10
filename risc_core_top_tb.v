`timescale 1ns/1ps

module risc_core_top_tb;

    reg clk;
    reg rst_n;
    integer errors;

    risc_core_top uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_bit;
        input [255:0] name;
        input         got;
        input         exp;
        begin
            if (got !== exp) begin
                $display("FAIL: %0s | got=%b exp=%b time=%0t", name, got, exp, $time);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | val=%b time=%0t", name, got, $time);
            end
        end
    endtask

    task check_val;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  exp;
        begin
            if (got !== exp) begin
                $display("FAIL: %0s | got=%h exp=%h time=%0t", name, got, exp, $time);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %0s | val=%h time=%0t", name, got, $time);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_core_top.vcd");
        $dumpvars(0, tb_core_top);

        errors = 0;
        rst_n  = 1'b0;

        #20;
        rst_n = 1'b1;

        repeat (6) @(posedge clk);

        check_bit("reset released", rst_n, 1'b1);
        check_bit("pc moved from zero", (uut.pc_if != 32'b0), 1'b1);
        check_val("pc_plus4 check", uut.pc_plus4_if, uut.pc_if + 32'd4);

        if (uut.stall_if_id == 1'b0) begin
            check_val("if_id pc capture", uut.pc_id, uut.pc_if);
            check_val("if_id pc_plus4 capture", uut.pc_plus4_id, uut.pc_plus4_if);
        end

        check_bit("stall_pc known", (uut.stall_pc !== 1'bx), 1'b1);
        check_bit("stall_if_id known", (uut.stall_if_id !== 1'bx), 1'b1);
        check_bit("mem_read_ex known", (uut.mem_read_ex !== 1'bx), 1'b1);
        check_bit("branch_taken_ex known", (uut.branch_taken_ex !== 1'bx), 1'b1);

        repeat (4) @(posedge clk);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED WITH %0d ERRORS", errors);

        #20;
        $finish;
    end

    initial begin
        #500;
        $display("FAIL: timeout");
        $finish;
    end

endmodule
