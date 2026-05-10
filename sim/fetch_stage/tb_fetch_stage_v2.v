//    iverilog -I ../../ -o fetch_tb ../../fetch_stage/fetch_stage.v ../../fetch_stage/pc_reg.v ../../fetch_stage/instr_mem.v tb_fetch_stage_v2.v
//vvp fetch_tb
`timescale 1ns/1ps
`include "riscv_defines.vh"

`timescale 1ns/1ps
`include "riscv_defines.vh"

module tb_fetch_stage_v2;

    reg         clk;
    reg         rst_n;
    reg         stall;
    reg         branch_taken;
    reg [31:0]  branch_target;

    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] pc_plus4_out;

    integer pass_count;
    integer fail_count;

    fetch_stage uut (
        .clk           (clk),
        .rst_n         (rst_n),
        .stall         (stall),
        .branch_taken  (branch_taken),
        .branch_target (branch_target),
        .pc_out        (pc_out),
        .instr_out     (instr_out),
        .pc_plus4_out  (pc_plus4_out)
    );

    always #5 clk = ~clk;

    task check_equal_32;
        input [255:0] test_name;
        input [31:0]  actual;
        input [31:0]  expected;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s | expected=%h actual=%h time=%0t",
                         test_name, expected, actual, $time);
                fail_count = fail_count + 1;
            end
            else begin
                $display("PASS: %0s | value=%h time=%0t",
                         test_name, actual, $time);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task sample_and_check_pc;
        input [255:0] test_name;
        input [31:0]  expected_pc;
        input [31:0]  expected_pc_plus4;
        begin
            @(negedge clk);
            #1;
            check_equal_32({test_name, " PC"}, pc_out, expected_pc);
            check_equal_32({test_name, " PC_PLUS4"}, pc_plus4_out, expected_pc_plus4);
        end
    endtask

    initial begin
        $dumpfile("tb_fetch_stage_v2.vcd");
        $dumpvars(0, tb_fetch_stage_v2);

        clk           = 1'b0;
        rst_n         = 1'b0;
        stall         = 1'b0;
        branch_taken  = 1'b0;
        branch_target = 32'h0000_0000;
        pass_count    = 0;
        fail_count    = 0;

        $display("========================================");
        $display("Starting FETCH STAGE self-checking TB");
        $display("========================================");

        // Hold reset for two cycles

        // Test 1: reset release value
        sample_and_check_pc("RESET_VALUE", 32'h0000_1000, 32'h0000_1004);
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // Test 2: sequential increment
        sample_and_check_pc("PC_INC_1", 32'h0000_1004, 32'h0000_1008);
        sample_and_check_pc("PC_INC_2", 32'h0000_1008, 32'h0000_100C);

        // Test 3: stall should hold PC
        stall = 1'b1;
        sample_and_check_pc("STALL_HOLD", 32'h0000_1008, 32'h0000_100C);
        stall = 1'b0;

        // Test 4: after stall release, increment resumes
        sample_and_check_pc("STALL_RELEASE", 32'h0000_100C, 32'h0000_1010);

        // Test 5: branch
        branch_target = 32'h0000_2000;
        branch_taken  = 1'b1;
        sample_and_check_pc("BRANCH_TAKEN", 32'h0000_2000, 32'h0000_2004);
        branch_taken  = 1'b0;

        // Test 6: continue sequentially after branch
        sample_and_check_pc("POST_BRANCH_INC", 32'h0000_2004, 32'h0000_2008);

        $display("========================================");
        $display("Simulation done: PASS=%0d FAIL=%0d", pass_count, fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("FINAL RESULT: TEST PASSED");
        else
            $display("FINAL RESULT: TEST FAILED");

        #10;
        $finish;
    end

    initial begin
        $monitor("T=%0t clk=%b rst_n=%b stall=%b branch_taken=%b branch_target=%h pc_out=%h pc_plus4_out=%h instr_out=%h",
                 $time, clk, rst_n, stall, branch_taken, branch_target, pc_out, pc_plus4_out, instr_out);
    end

endmodule
