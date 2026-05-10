//iverilog -o de_tb control_unit.v imm_gen.v regfile.v alu.v fft_butterfly.v decode_execute.v tb_decode_execute.v
//vvp de_tb
//gtkwave tb_decode_execute.vcd

`timescale 1ns/1ps

`timescale 1ns/1ps

module tb_decode_execute;

    reg         clk;
    reg         rst_n;
    reg [31:0]  pc_in;
    reg [31:0]  instr_in;

    reg         wb_reg_write;
    reg [4:0]   wb_rd_addr;
    reg [31:0]  wb_rd_data;

    reg [31:0]  fwd_ex_data;
    reg [31:0]  fwd_mem_data;
    reg [1:0]   fwd_a_sel;
    reg [1:0]   fwd_b_sel;

    wire [31:0] exec_result_out;
    wire [31:0] rs2_store_data_out;
    wire [4:0]  rd_addr_out;
    wire        reg_write_out;
    wire        mem_read_out;
    wire        mem_write_out;
    wire        mem_to_reg_out;
    wire        branch_taken_out;
    wire [31:0] branch_target_out;
    wire [31:0] pc_plus4_out;

    integer errors;

    decode_execute dut (
        .clk               (clk),
        .rst_n             (rst_n),
        .pc_in             (pc_in),
        .instr_in          (instr_in),
        .wb_reg_write      (wb_reg_write),
        .wb_rd_addr        (wb_rd_addr),
        .wb_rd_data        (wb_rd_data),
        .fwd_ex_data       (fwd_ex_data),
        .fwd_mem_data      (fwd_mem_data),
        .fwd_a_sel         (fwd_a_sel),
        .fwd_b_sel         (fwd_b_sel),
        .exec_result_out   (exec_result_out),
        .rs2_store_data_out(rs2_store_data_out),
        .rd_addr_out       (rd_addr_out),
        .reg_write_out     (reg_write_out),
        .mem_read_out      (mem_read_out),
        .mem_write_out     (mem_write_out),
        .mem_to_reg_out    (mem_to_reg_out),
        .branch_taken_out  (branch_taken_out),
        .branch_target_out (branch_target_out),
        .pc_plus4_out      (pc_plus4_out)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task apply_defaults;
        begin
            wb_reg_write = 1'b0;
            wb_rd_addr   = 5'd0;
            wb_rd_data   = 32'd0;
            fwd_ex_data  = 32'd0;
            fwd_mem_data = 32'd0;
            fwd_a_sel    = 2'b00;
            fwd_b_sel    = 2'b00;
        end
    endtask

    task check_ctrl;
        input        exp_regw, exp_mr, exp_mw, exp_m2r, exp_bt;
        input [4:0]  exp_rd;
        input [31:0] exp_pc4, exp_btgt;
        input [127:0] name;
        begin
            @(posedge clk);
            #1;
            if ((reg_write_out    !== exp_regw) ||
                (mem_read_out     !== exp_mr)   ||
                (mem_write_out    !== exp_mw)   ||
                (mem_to_reg_out   !== exp_m2r)  ||
                (branch_taken_out !== exp_bt)   ||
                (rd_addr_out      !== exp_rd)   ||
                (pc_plus4_out     !== exp_pc4)  ||
                (branch_target_out!== exp_btgt)) begin

                $display("FAIL : %s", name);
                $display("  instr=%h pc=%h", instr_in, pc_in);
                $display("  opcode=%b funct3=%b funct7=%b rd=%0d",
                         instr_in[6:0], instr_in[14:12], instr_in[31:25], instr_in[11:7]);
                $display("  got: rw=%b mr=%b mw=%b m2r=%b bt=%b rd=%0d pc4=%h btgt=%h",
                         reg_write_out, mem_read_out, mem_write_out, mem_to_reg_out,
                         branch_taken_out, rd_addr_out, pc_plus4_out, branch_target_out);
                $display("  exp: rw=%b mr=%b mw=%b m2r=%b bt=%b rd=%0d pc4=%h btgt=%h",
                         exp_regw, exp_mr, exp_mw, exp_m2r,
                         exp_bt, exp_rd, exp_pc4, exp_btgt);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_decode_execute.vcd");
        $dumpvars(0, tb_decode_execute);

        $monitor("time=%0t pc=%h instr=%h opcode=%b funct3=%b funct7=%b rd=%0d rw=%b mr=%b mw=%b m2r=%b bt=%b",
                 $time, pc_in, instr_in, instr_in[6:0], instr_in[14:12], instr_in[31:25], instr_in[11:7],
                 reg_write_out, mem_read_out, mem_write_out, mem_to_reg_out, branch_taken_out);

        errors = 0;
        apply_defaults();

        pc_in   = 32'h0000_1000;
        instr_in = 32'h0000_0013;
        rst_n   = 1'b0;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // ADD
        instr_in = 32'h002081B3;
        check_ctrl(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 5'd3, pc_in + 32'd4, pc_in + 32'd0, "ADD");

        // SUB
        instr_in = 32'h402081B3;
        check_ctrl(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 5'd3, pc_in + 32'd4, pc_in + 32'd0, "SUB");

        // AND
        instr_in = 32'h0020F1B3;
        check_ctrl(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 5'd3, pc_in + 32'd4, pc_in + 32'd0, "AND");

        // OR
        instr_in = 32'h0020E1B3;
        check_ctrl(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 5'd3, pc_in + 32'd4, pc_in + 32'd0, "OR");

        // XOR
        instr_in = 32'h0020C1B3;
        check_ctrl(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 5'd3, pc_in + 32'd4, pc_in + 32'd0, "XOR");

        // LW : lw x1, 10(x0)
        instr_in = 32'h00A02083;
        check_ctrl(1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 5'd1, pc_in + 32'd4, 32'h0000_100A, "LW");

        // SW : sw x3, 0(x0)
        instr_in = 32'h00302023;
        check_ctrl(1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 5'd0, pc_in + 32'd4, 32'h0000_1000, "SW");

        // BEQ : branch target expected = pc + 8, branch decision may depend on register compare data
        instr_in = 32'h00208463;
        check_ctrl(1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 5'd0, pc_in + 32'd4, 32'h0000_1008, "BEQ");

        // BNE : branch target expected = pc + 8, branch decision may depend on register compare data
        instr_in = 32'h00209463;
        check_ctrl(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 5'd0, pc_in + 32'd4, 32'h0000_1008, "BNE");

        // JAL : jal x0, 0
        instr_in = 32'h0000006F;
        check_ctrl(1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 5'd0, pc_in + 32'd4, 32'h0000_1000, "JAL");

        // FFT custom instruction
        //instr_in = 32'h000000BB;
	instr_in = 32'h020000BB;
        check_ctrl(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 5'd1, pc_in + 32'd4, 32'h0000_1000, "FFT");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TOTAL ERRORS = %0d", errors);

        #20;
        $finish;
    end

endmodule
