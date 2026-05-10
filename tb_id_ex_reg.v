`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : tb_id_ex_reg.v
Testbench   : tb_id_ex_reg
Purpose     : Self-checking testbench for id_ex_reg.v

What this TB verifies:
1. Reset clears all outputs
2. Normal capture loads inputs on posedge clk
3. Stall holds previous values
4. Flush clears outputs to bubble values
5. Subsequent capture works again after flush

DUT inputs driven by TB:
- clk
- rst_n
- stall
- flush
- pc_in
- rs1_data_in
- rs2_data_in
- imm_in
- rs1_addr_in
- rs2_addr_in
- rd_addr_in
- reg_write_in
- mem_read_in
- mem_write_in
- mem_to_reg_in
- alu_src_in
- branch_in
- alu_ctrl_in

DUT outputs checked by TB:
- pc_out
- rs1_data_out
- rs2_data_out
- imm_out
- rs1_addr_out
- rs2_addr_out
- rd_addr_out
- reg_write_out
- mem_read_out
- mem_write_out
- mem_to_reg_out
- alu_src_out
- branch_out
- alu_ctrl_out

Run command:
- Compile : iverilog -o idex_tb id_ex_reg.v tb_id_ex_reg.v
- Run     : vvp idex_tb
- Waveform: gtkwave tb_id_ex_reg.vcd
------------------------------------------------------------------------------
*/

module tb_id_ex_reg;

    reg                  clk;
    reg                  rst_n;
    reg                  stall;
    reg                  flush;

    reg  [`XLEN-1:0]     pc_in;
    reg  [`XLEN-1:0]     rs1_data_in;
    reg  [`XLEN-1:0]     rs2_data_in;
    reg  [`XLEN-1:0]     imm_in;
    reg  [4:0]           rs1_addr_in;
    reg  [4:0]           rs2_addr_in;
    reg  [4:0]           rd_addr_in;

    reg                  reg_write_in;
    reg                  mem_read_in;
    reg                  mem_write_in;
    reg                  mem_to_reg_in;
    reg                  alu_src_in;
    reg                  branch_in;
    reg  [3:0]           alu_ctrl_in;

    wire [`XLEN-1:0]     pc_out;
    wire [`XLEN-1:0]     rs1_data_out;
    wire [`XLEN-1:0]     rs2_data_out;
    wire [`XLEN-1:0]     imm_out;
    wire [4:0]           rs1_addr_out;
    wire [4:0]           rs2_addr_out;
    wire [4:0]           rd_addr_out;

    wire                 reg_write_out;
    wire                 mem_read_out;
    wire                 mem_write_out;
    wire                 mem_to_reg_out;
    wire                 alu_src_out;
    wire                 branch_out;
    wire [3:0]           alu_ctrl_out;

    integer errors;

    id_ex_reg uut (
        .clk           (clk),
        .rst_n         (rst_n),
        .stall         (stall),
        .flush         (flush),
        .pc_in         (pc_in),
        .rs1_data_in   (rs1_data_in),
        .rs2_data_in   (rs2_data_in),
        .imm_in        (imm_in),
        .rs1_addr_in   (rs1_addr_in),
        .rs2_addr_in   (rs2_addr_in),
        .rd_addr_in    (rd_addr_in),
        .reg_write_in  (reg_write_in),
        .mem_read_in   (mem_read_in),
        .mem_write_in  (mem_write_in),
        .mem_to_reg_in (mem_to_reg_in),
        .alu_src_in    (alu_src_in),
        .branch_in     (branch_in),
        .alu_ctrl_in   (alu_ctrl_in),
        .pc_out        (pc_out),
        .rs1_data_out  (rs1_data_out),
        .rs2_data_out  (rs2_data_out),
        .imm_out       (imm_out),
        .rs1_addr_out  (rs1_addr_out),
        .rs2_addr_out  (rs2_addr_out),
        .rd_addr_out   (rd_addr_out),
        .reg_write_out (reg_write_out),
        .mem_read_out  (mem_read_out),
        .mem_write_out (mem_write_out),
        .mem_to_reg_out(mem_to_reg_out),
        .alu_src_out   (alu_src_out),
        .branch_out    (branch_out),
        .alu_ctrl_out  (alu_ctrl_out)
    );

    always #5 clk = ~clk;

    task check_outputs;
        input [`XLEN-1:0] exp_pc;
        input [`XLEN-1:0] exp_rs1;
        input [`XLEN-1:0] exp_rs2;
        input [`XLEN-1:0] exp_imm;
        input [4:0]       exp_rs1_addr;
        input [4:0]       exp_rs2_addr;
        input [4:0]       exp_rd_addr;
        input             exp_reg_write;
        input             exp_mem_read;
        input             exp_mem_write;
        input             exp_mem_to_reg;
        input             exp_alu_src;
        input             exp_branch;
        input [3:0]       exp_alu_ctrl;
        input [127:0]     test_name;
        begin
            #1;
            if ((pc_out         !== exp_pc)        ||
                (rs1_data_out   !== exp_rs1)       ||
                (rs2_data_out   !== exp_rs2)       ||
                (imm_out        !== exp_imm)       ||
                (rs1_addr_out   !== exp_rs1_addr)  ||
                (rs2_addr_out   !== exp_rs2_addr)  ||
                (rd_addr_out    !== exp_rd_addr)   ||
                (reg_write_out  !== exp_reg_write) ||
                (mem_read_out   !== exp_mem_read)  ||
                (mem_write_out  !== exp_mem_write) ||
                (mem_to_reg_out !== exp_mem_to_reg)||
                (alu_src_out    !== exp_alu_src)   ||
                (branch_out     !== exp_branch)    ||
                (alu_ctrl_out   !== exp_alu_ctrl)) begin
                $display("FAIL : %s", test_name);
                $display("       pc_out=%h rs1_data_out=%h rs2_data_out=%h imm_out=%h",
                         pc_out, rs1_data_out, rs2_data_out, imm_out);
                $display("       rs1=%0d rs2=%0d rd=%0d", rs1_addr_out, rs2_addr_out, rd_addr_out);
                $display("       reg_write=%b mem_read=%b mem_write=%b mem_to_reg=%b alu_src=%b branch=%b alu_ctrl=%b",
                         reg_write_out, mem_read_out, mem_write_out, mem_to_reg_out, alu_src_out, branch_out, alu_ctrl_out);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    task drive_inputs;
        input [`XLEN-1:0] tpc;
        input [`XLEN-1:0] tr1;
        input [`XLEN-1:0] tr2;
        input [`XLEN-1:0] timm;
        input [4:0]       tr1a;
        input [4:0]       tr2a;
        input [4:0]       trd;
        input             tregw;
        input             tmemr;
        input             tmemw;
        input             tm2r;
        input             talus;
        input             tbr;
        input [3:0]       taluc;
        begin
            pc_in         = tpc;
            rs1_data_in   = tr1;
            rs2_data_in   = tr2;
            imm_in        = timm;
            rs1_addr_in   = tr1a;
            rs2_addr_in   = tr2a;
            rd_addr_in    = trd;
            reg_write_in  = tregw;
            mem_read_in   = tmemr;
            mem_write_in  = tmemw;
            mem_to_reg_in = tm2r;
            alu_src_in    = talus;
            branch_in     = tbr;
            alu_ctrl_in   = taluc;
        end
    endtask

    initial begin
        $dumpfile("tb_id_ex_reg.vcd");
        $dumpvars(0, tb_id_ex_reg);

        errors = 0;
        clk = 0;
        rst_n = 0;
        stall = 0;
        flush = 0;

        drive_inputs(32'h0,32'h0,32'h0,32'h0,5'd0,5'd0,5'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'd0);

        #12;
        check_outputs(32'h0,32'h0,32'h0,32'h0,5'd0,5'd0,5'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'd0,"RESET_CLEAR");

        rst_n = 1'b1;

        drive_inputs(32'h0000_1000,32'h1111_1111,32'h2222_2222,32'h0000_0040,5'd1,5'd2,5'd3,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,4'd2);
        @(posedge clk);
        #1;
        check_outputs(32'h0000_1000,32'h1111_1111,32'h2222_2222,32'h0000_0040,5'd1,5'd2,5'd3,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,4'd2,"NORMAL_CAPTURE");

        drive_inputs(32'h0000_2000,32'hAAAA_AAAA,32'hBBBB_BBBB,32'h0000_0080,5'd4,5'd5,5'd6,1'b0,1'b1,1'b1,1'b1,1'b0,1'b1,4'd7);
        stall = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(32'h0000_1000,32'h1111_1111,32'h2222_2222,32'h0000_0040,5'd1,5'd2,5'd3,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,4'd2,"STALL_HOLD");
        stall = 1'b0;

        flush = 1'b1;
        @(posedge clk);
        #1;
        check_outputs(32'h0,32'h0,32'h0,32'h0,5'd0,5'd0,5'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'd0,"FLUSH_CLEAR");
        flush = 1'b0;

        drive_inputs(32'h0000_3000,32'h3333_3333,32'h4444_4444,32'h0000_00C0,5'd7,5'd8,5'd9,1'b1,1'b1,1'b0,1'b1,1'b1,1'b0,4'd9);
        @(posedge clk);
        #1;
        check_outputs(32'h0000_3000,32'h3333_3333,32'h4444_4444,32'h0000_00C0,5'd7,5'd8,5'd9,1'b1,1'b1,1'b0,1'b1,1'b1,1'b0,4'd9,"CAPTURE_AFTER_FLUSH");

        if (errors == 0)
            $display("\nALL ID_EX_REG TESTS PASSED\n");
        else
            $display("\nID_EX_REG TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
