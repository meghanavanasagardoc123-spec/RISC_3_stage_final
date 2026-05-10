`timescale 1ns/1ps

module tb_wb_mux;

    reg  [31:0] mem_data;
    reg  [31:0] alu_data;
    reg  [31:0] pc_plus4;
    reg         mem_to_reg;
    reg         jump;

    wire [31:0] wb_data;

    integer errors;

    wb_mux uut (
        .mem_data  (mem_data),
        .alu_data  (alu_data),
        .pc_plus4  (pc_plus4),
        .mem_to_reg(mem_to_reg),
        .jump      (jump),
        .wb_data   (wb_data)
    );

    task check_output;
        input [31:0] expected;
        input [127:0] test_name;
        begin
            #1;
            if (wb_data !== expected) begin
                $display("FAIL : %s", test_name);
                $display("       wb_data   = %h", wb_data);
                $display("       expected  = %h", expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_wb_mux.vcd");
        $dumpvars(0, tb_wb_mux);

        errors = 0;

        mem_data   = 32'hDEAD_BEEF;
        alu_data   = 32'h1111_2222;
        pc_plus4   = 32'h0000_0040;
        mem_to_reg = 1'b0;
        jump       = 1'b0;
        #5;
        check_output(32'h1111_2222, "ALU_SELECTED");

        mem_to_reg = 1'b1;
        jump       = 1'b0;
        #5;
        check_output(32'hDEAD_BEEF, "MEM_SELECTED");

        mem_to_reg = 1'b0;
        jump       = 1'b1;
        #5;
        check_output(32'h0000_0040, "PCPLUS4_SELECTED");

        mem_to_reg = 1'b1;
        jump       = 1'b1;
        #5;
        check_output(32'h0000_0040, "JUMP_PRIORITY_OVER_MEM");

        if (errors == 0)
            $display("\nALL WB_MUX TESTS PASSED\n");
        else
            $display("\nWB_MUX TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
