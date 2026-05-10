`timescale 1ns/1ps

module wb_mux (
    input  wire [31:0] mem_data,
    input  wire [31:0] alu_data,
    input  wire [31:0] pc_plus4,
    input  wire        mem_to_reg,
    input  wire        jump,
    output reg  [31:0] wb_data
);

    always @(*) begin
        if (jump)
            wb_data = pc_plus4;     // JAL writes PC+4 to rd
        else if (mem_to_reg)
            wb_data = mem_data;     // LW writes loaded data
        else
            wb_data = alu_data;     // ALU / FFT result
    end

endmodule
