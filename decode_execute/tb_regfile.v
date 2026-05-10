`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
iverilog -o regfile_tb regfile.v tb_regfile.v
vvp regfile_tb
gtkwave tb_regfile.vcd
------------------------------------------------------------------------------
File        : tb_regfile.v
Purpose     : Self-checking testbench for RISC-V integer register file

DUT         : regfile

What it tests:
1. Reset clears all registers to 0
2. Write to a normal register works correctly
3. Read from rs1 and rs2 ports returns correct data
4. Write to x0 is ignored
5. Reading x0 always returns 0
6. Two read ports can access different registers at the same time

Important DUT inputs:
- clk           : Clock input
- rst_n         : Active-low reset
- reg_write_en  : Register write enable
- rs1_addr      : Read address port 1
- rs2_addr      : Read address port 2
- rd_addr       : Write address
- rd_wdata      : Data written into rd_addr

Important DUT outputs:
- rs1_rdata     : Data read from rs1_addr
- rs2_rdata     : Data read from rs2_addr

Notes:
- This TB is written in pure Verilog for Icarus Verilog
- The TB is self-checking and reports PASS/FAIL using $display
------------------------------------------------------------------------------
*/

module tb_regfile;

    reg              clk;
    reg              rst_n;
    reg              reg_write_en;
    reg  [4:0]       rs1_addr;
    reg  [4:0]       rs2_addr;
    reg  [4:0]       rd_addr;
    reg  [`XLEN-1:0] rd_wdata;

    wire [`XLEN-1:0] rs1_rdata;
    wire [`XLEN-1:0] rs2_rdata;

    integer errors;

    regfile uut (
        .clk          (clk),
        .rst_n        (rst_n),
        .reg_write_en (reg_write_en),
        .rs1_addr     (rs1_addr),
        .rs2_addr     (rs2_addr),
        .rd_addr      (rd_addr),
        .rd_wdata     (rd_wdata),
        .rs1_rdata    (rs1_rdata),
        .rs2_rdata    (rs2_rdata)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_read_ports;
        input [`XLEN-1:0] exp_rs1;
        input [`XLEN-1:0] exp_rs2;
        input [127:0]     test_name;
        begin
            #1;
            if ((rs1_rdata !== exp_rs1) || (rs2_rdata !== exp_rs2)) begin
                $display("FAIL : %s", test_name);
                $display("       rs1_addr=%0d expected=%h got=%h", rs1_addr, exp_rs1, rs1_rdata);
                $display("       rs2_addr=%0d expected=%h got=%h", rs2_addr, exp_rs2, rs2_rdata);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    task write_reg;
        input [4:0]       addr;
        input [`XLEN-1:0] data;
        begin
            @(negedge clk);
            reg_write_en = 1'b1;
            rd_addr      = addr;
            rd_wdata     = data;
            @(posedge clk);
            #1;
            reg_write_en = 1'b0;
            rd_addr      = 5'd0;
            rd_wdata     = {`XLEN{1'b0}};
        end
    endtask

    initial begin
        $dumpfile("tb_regfile.vcd");
        $dumpvars(0, tb_regfile);

        errors = 0;

        // Initialize inputs
        rst_n         = 1'b0;
        reg_write_en  = 1'b0;
        rs1_addr      = 5'd0;
        rs2_addr      = 5'd0;
        rd_addr       = 5'd0;
        rd_wdata      = {`XLEN{1'b0}};

        // ------------------------------------------------------
        // Test 1: Reset behavior
        // ------------------------------------------------------
        #12;
        rst_n = 1'b1;

        rs1_addr = 5'd0;
        rs2_addr = 5'd1;
        check_read_ports(32'h0000_0000, 32'h0000_0000, "RESET_CLEARS_REGS");

        // ------------------------------------------------------
        // Test 2: Write and read x1
        // ------------------------------------------------------
        write_reg(5'd1, 32'h1234_5678);
        rs1_addr = 5'd1;
        rs2_addr = 5'd0;
        check_read_ports(32'h1234_5678, 32'h0000_0000, "WRITE_READ_X1");

        // ------------------------------------------------------
        // Test 3: Write and read x2
        // ------------------------------------------------------
        write_reg(5'd2, 32'hA5A5_5A5A);
        rs1_addr = 5'd2;
        rs2_addr = 5'd1;
        check_read_ports(32'hA5A5_5A5A, 32'h1234_5678, "WRITE_READ_X2_AND_X1");

        // ------------------------------------------------------
        // Test 4: Write to x0 should be ignored
        // ------------------------------------------------------
        write_reg(5'd0, 32'hFFFF_FFFF);
        rs1_addr = 5'd0;
        rs2_addr = 5'd1;
        check_read_ports(32'h0000_0000, 32'h1234_5678, "WRITE_TO_X0_IGNORED");

        // ------------------------------------------------------
        // Test 5: Simultaneous two-port reads
        // ------------------------------------------------------
        write_reg(5'd3, 32'hCAFE_BABE);
        write_reg(5'd4, 32'h0BAD_F00D);
        rs1_addr = 5'd3;
        rs2_addr = 5'd4;
        check_read_ports(32'hCAFE_BABE, 32'h0BAD_F00D, "DUAL_READ_PORT_TEST");

        if (errors == 0)
            $display("\nALL REGFILE TESTS PASSED\n");
        else
            $display("\nREGFILE TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
