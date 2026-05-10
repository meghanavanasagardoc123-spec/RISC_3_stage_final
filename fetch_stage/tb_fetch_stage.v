//iverilog -o fetch_tb fetch_stage.v tb_fetch_stage.v
//vvp fetch_tb
//gtkwave tb_fetch_stage.vcd
//iverilog -o fetch_tb fetch_stage.v pc_reg.v instr_mem.v tb_fetch_stage.v
//vvp fetch_tb
`timescale 1ns/1ps
//`include fetch_stage.v
module tb_fetch_stage;

    reg clk;
    reg rst_n;
    reg stall;
    reg branch_taken;
    reg [31:0] branch_target;

    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] pc_plus4_out;

    integer errors;

    fetch_stage uut (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .pc_plus4_out(pc_plus4_out)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] exp_pc;
        input [31:0] exp_pc_plus4;
        input [127:0] test_name;
        begin
            #1;
            if (pc_out !== exp_pc || pc_plus4_out !== exp_pc_plus4) begin
                $display("FAIL : %s", test_name);
                $display("       pc_out       = %h  expected = %h", pc_out, exp_pc);
                $display("       pc_plus4_out = %h  expected = %h", pc_plus4_out, exp_pc_plus4);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_fetch_stage.vcd");
        $dumpvars(0, tb_fetch_stage);

        clk = 0;
        rst_n = 0;
        stall = 0;
        branch_taken = 0;
        branch_target = 32'h0000_0000;
        errors = 0;

        // Reset check
        #12;
        check(32'h0000_0000, 32'h0000_0004, "RESET_CHECK");

        rst_n = 1;

        // PC should increment by 4 each cycle
        @(posedge clk);
        check(32'h0000_0004, 32'h0000_0008, "PC_PLUS4_1");

        @(posedge clk);
        check(32'h0000_0008, 32'h0000_000C, "PC_PLUS4_2");

        @(posedge clk);
        check(32'h0000_000C, 32'h0000_0010, "PC_PLUS4_3");

        // Stall should hold PC
        stall = 1;
        @(posedge clk);
        check(32'h0000_000C, 32'h0000_0010, "STALL_HOLD_1");

        @(posedge clk);
        check(32'h0000_000C, 32'h0000_0010, "STALL_HOLD_2");

        stall = 0;

        // Branch should redirect PC
        branch_taken = 1;
        branch_target = 32'h0000_0040;
        @(posedge clk);
        check(32'h0000_0040, 32'h0000_0044, "BRANCH_REDIRECT");

        branch_taken = 0;
        @(posedge clk);
        check(32'h0000_0044, 32'h0000_0048, "POST_BRANCH_INCREMENT");

        if (errors == 0)
            $display("\nALL FETCH_STAGE TESTS PASSED\n");
        else
            $display("\nFETCH_STAGE TESTS FAILED : total errors = %0d\n", errors);

         #1000; $finish;
    end

endmodule
