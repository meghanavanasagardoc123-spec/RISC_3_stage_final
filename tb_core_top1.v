//iverilog -o core_top_tb  core_top.v fetch_stage.v decode_execute.v mem_wb.v mem_wb_reg.v wb_mux.v  pc_reg.v instr_mem.v regfile.v imm_gen.v control_unit.v alu.v fft_butterfly.v data_mem.v tb_core_top.v

//vvp core_top_tb
//gtkwave tb_core_top.vcd
`timescale 1ns/1ps
//module tb_core_top;
//
//    reg clk;
//    reg rst_n;
//
//    // Instantiate your core
//    core_top uut (
//        .clk   (clk),
//        .rst_n (rst_n)
//    );
//
//    // Clock: 10ns period
//    always #5 clk = ~clk;
//
//    // Checker Task
//    task verify_output;
//        input [31:0] exp_pc;
//        input [127:0] name;
//        begin
//            @(posedge clk); #1; // Check after clock edge
//            // Example check: monitor the PC from the fetch stage
//            if (uut.u_fetch_stage.pc_out !== exp_pc) begin
//                $display("FAIL: %s | Expected PC=%h, Got=%h", name, exp_pc, uut.u_fetch_stage.pc_out);
//            end else begin
//                $display("PASS: %s | PC=%h", name, uut.u_fetch_stage.pc_out);
//            end
//        end
//    endtask
//
//    initial begin
//        $dumpfile("tb_core_top.vcd");
//        $dumpvars(0, tb_core_top);
//
//        clk   = 1'b0;
//        rst_n = 1'b0;
//        #20 rst_n = 1'b1; // Release reset
//
//        // Test vectors: Verify PC advances
//        verify_output(32'h00001004, "PC_Increment_1");
//        verify_output(32'h00001008, "PC_Increment_2");
//
//        #100 $finish;
//    end
//endmodule
`timescale 1ns/1ps

module tb_core_top();
    reg clk, rst_n;
    core_top uut (.clk(clk), .rst_n(rst_n));

    always #5 clk = ~clk;

    // Simulation control
    initial begin
        clk = 0; rst_n = 0;
        #15 rst_n = 1;
    end

    // Pipeline Monitor
    initial begin
        $display("Time | IF_Instr | ID_Instr | EX_Result  | WB_Write | WB_Data");
        $display("---------------------------------------------------------------");
        $monitor("%0t | %h | %h | %h | %b | %h", 
            $time, uut.instr_if, uut.instr_id, uut.exec_result_ex, uut.wb_reg_write, uut.wb_data);
    end

    // Self-Checking Logic (Scoreboard)
    always @(posedge clk) begin
        if (uut.wb_reg_write) begin
            // Verify FFT Result (Example: if rd=4, data should be expected value)
            if (uut.wb_rd_addr == 5'd4) begin
                if (uut.wb_data === 32'hFEEDCAFE) // Put your expected butterfly result here
                    $display(">>> TEST PASSED: FFT Output Verified!");
                else
                    $display(">>> TEST FAILED: FFT Output mismatch, got %h", uut.wb_data);
            end
            
            // Verify Memory Store operation
            if (uut.u_decode_execute.mem_write_out) begin
                $display(">>> INFO: Store instruction committed at address %h", uut.exec_result_ex);
            end
        end
    end

    initial #1000 $finish;
initial begin
    $monitor("Reset=%b | PC=%h | Instr=%h | RegWrite=%b", rst_n, uut.u_fetch_stage.pc_out, uut.instr_if, uut.wb_reg_write);
end

endmodule

//`timescale 1ns/1ps
//
//module tb_core_top();
//    reg clk, rst_n;
//    
//    // Instantiate Top
//    core_top uut (
//        .clk(clk),
//        .rst_n(rst_n)
//    );
//
//    // Clock Generation
//    always #5 clk = ~clk;
//
//    // Golden Model (Expected values for specific register writes)
//    reg [31:0] golden_data [0:10]; 
//    integer cycle_count = 0;
//
//    initial begin
//        clk = 0; rst_n = 0;
//        #15 rst_n = 1;
//        
//        // Monitor pipeline
//        $display("Time | IF_Instr   | ID_Instr   | EX_Result  | FFT_EN");
//        $monitor("%0t | %h | %h | %h | %b", 
//            $time, uut.instr_if, uut.instr_id, uut.exec_result_ex, uut.u_decode_execute.fft_en);
//    end
//
//    // Self-Checking Logic (Check results at WB stage)
//    always @(posedge clk) begin
//        if (uut.u_mem_wb.wb_reg_write_out) begin
//            $display("--- WB Check: Reg[%d] = %h ---", uut.u_mem_wb.wb_rd_addr_out, uut.u_mem_wb.wb_data_out);
//            
//            // Example Check: Verify FFT result (assuming FFT writes to x4)
//            if (uut.u_mem_wb.wb_rd_addr_out == 5'd4) begin
//                if (uut.u_mem_wb.wb_data_out === 32'hFEEDCAFE) // Put expected FFT result here
//                    $display("FFT TEST PASSED!");
//                else
//                    $display("FFT TEST FAILED! Expected FEEDCAFE, got %h", uut.u_mem_wb.wb_data_out);
//            end
//        end
//        
//        cycle_count = cycle_count + 1;
//        if (cycle_count > 100) begin
//            $display("Simulation Timeout");
//            $finish;
//        end
//    end
//
//    initial #500 $finish;
//endmodule
