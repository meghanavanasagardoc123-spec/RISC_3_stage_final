

core_top.v:109: warning: Port 14 (rd_addr_out) of decode_execute expects 5 bits, got 1.
core_top.v:109:        : Padding 4 high bits of the port.
core_top.v:139: warning: Port 6 (rd_addr_in) of id_ex_reg expects 5 bits, got 1.
core_top.v:139:        : Padding 4 high bits of the port.
core_top.v:139: warning: Port 13 (alu_ctrl_in) of id_ex_reg expects 4 bits, got 1.
core_top.v:139:        : Padding 3 high bits of the port.
core_top.v:139: warning: Port 17 (pc_out) of id_ex_reg expects 32 bits, got 1.
core_top.v:139:        : Padding 31 high bits of the port.
core_top.v:139: warning: Port 25 (alu_ctrl_out) of id_ex_reg expects 4 bits, got 1.
core_top.v:139:        : Padding 3 high bits of the port.
   
wire [4:0] rd_addr_dec;
wire [3:0] alu_ctrl_dec;
wire [3:0] alu_ctrl_ex;
wire [31:0] pc_ex;
