`timescale 1ns/1ps
//iverilog -o memwb_tb mem_wb.v mem_wb_reg.v wb_mux.v tb_mem_wb.v
//vvp memwb_tb
//gtkwave tb_mem_wb.vcd

`timescale 1ns/1ps

module tb_mem_wb;

    reg         clk;
    reg         rst_n;
    reg [31:0]  mem_read_data_in;
    reg [31:0]  alu_result_in;
    reg [31:0]  pc_plus4_in;
    reg [4:0]   rd_addr_in;
    reg         reg_write_in;
    reg         mem_to_reg_in;
    reg         jump_in;

    wire [31:0] wb_data_out;
    wire [4:0]  wb_rd_addr_out;
    wire        wb_reg_write_out;

    integer errors;

    mem_wb dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .mem_read_data_in (mem_read_data_in),
        .alu_result_in    (alu_result_in),
        .pc_plus4_in      (pc_plus4_in),
        .rd_addr_in       (rd_addr_in),
        .reg_write_in     (reg_write_in),
        .mem_to_reg_in    (mem_to_reg_in),
        .jump_in          (jump_in),
        .wb_data_out      (wb_data_out),
        .wb_rd_addr_out   (wb_rd_addr_out),
        .wb_reg_write_out (wb_reg_write_out)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check;
        input [31:0] exp_wb_data;
        input [4:0]  exp_rd;
        input        exp_reg_write;
        input [127:0] name;
        begin
            #1;
            if ((wb_data_out !== exp_wb_data) ||
                (wb_rd_addr_out !== exp_rd) ||
                (wb_reg_write_out !== exp_reg_write)) begin
                $display("FAIL : %s", name);
                $display("  mem_read_data_in=%h alu_result_in=%h pc_plus4_in=%h rd_addr_in=%0d",
                         mem_read_data_in, alu_result_in, pc_plus4_in, rd_addr_in);
                $display("  mem_to_reg_in=%b jump_in=%b reg_write_in=%b",
                         mem_to_reg_in, jump_in, reg_write_in);
                $display("  expected wb_data=%h rd=%0d reg_write=%b",
                         exp_wb_data, exp_rd, exp_reg_write);
                $display("  got      wb_data=%h rd=%0d reg_write=%b",
                         wb_data_out, wb_rd_addr_out, wb_reg_write_out);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s  wb_data=%h", name, wb_data_out);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_mem_wb.vcd");
        $dumpvars(0, tb_mem_wb);

        errors = 0;

        rst_n = 1'b0;
        mem_read_data_in = 32'd0;
        alu_result_in    = 32'd0;
        pc_plus4_in      = 32'd0;
        rd_addr_in       = 5'd0;
        reg_write_in     = 1'b0;
        mem_to_reg_in    = 1'b0;
        jump_in          = 1'b0;

        @(posedge clk);
        @(posedge clk);
        rst_n = 1'b1;

        // ALU path
        mem_read_data_in = 32'hAAAA_AAAA;
        alu_result_in    = 32'h1234_5678;
        pc_plus4_in      = 32'h0000_1004;
        rd_addr_in       = 5'd3;
        reg_write_in     = 1'b1;
        mem_to_reg_in    = 1'b0;
        jump_in          = 1'b0;
        @(posedge clk);
        check(32'h1234_5678, 5'd3, 1'b1, "ALU path");

        // Memory path
        mem_read_data_in = 32'hDEAD_BEEF;
        alu_result_in    = 32'h1111_2222;
        pc_plus4_in      = 32'h0000_1004;
        rd_addr_in       = 5'd5;
        reg_write_in     = 1'b1;
        mem_to_reg_in    = 1'b1;
        jump_in          = 1'b0;
        @(posedge clk);
        check(32'hDEAD_BEEF, 5'd5, 1'b1, "Memory path");

        // Jump path
        mem_read_data_in = 32'h0000_0000;
        alu_result_in    = 32'h3333_4444;
        pc_plus4_in      = 32'h0000_1004;
        rd_addr_in       = 5'd1;
        reg_write_in     = 1'b1;
        mem_to_reg_in    = 1'b0;
        jump_in          = 1'b1;
        @(posedge clk);
        check(32'h0000_1004, 5'd1, 1'b1, "Jump path");

        // reg_write disabled
        mem_read_data_in = 32'hCAFE_BABE;
        alu_result_in    = 32'h5555_6666;
        pc_plus4_in      = 32'h0000_2004;
        rd_addr_in       = 5'd9;
        reg_write_in     = 1'b0;
        mem_to_reg_in    = 1'b0;
        jump_in          = 1'b0;
        @(posedge clk);
        check(32'h5555_6666, 5'd9, 1'b0, "Write disable passthrough");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TOTAL ERRORS = %0d", errors);

        $finish;
    end

endmodule
