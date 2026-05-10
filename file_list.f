#######################  iverilog -I . -o core_top_tb -c file_list.f
##iverilog -I . -y fetch_stage/ -y decode_execute/ -y mem_wb_stage/ -o core_top_tb -c file_list.f

#vvp core_top_tb
#gtkwave tb_core_top.vcd

core_top.v




-y fetch_stage/
fetch_stage/fetch_stage.v
fetch_stage/pc_reg.v
fetch_stage/instr_mem.v
decode_execute/decode_execute.v
decode_execute/control_unit.v
decode_execute/regfile.v
decode_execute/imm_gen.v
decode_execute/alu.v
decode_execute/fft_butterfly.v
decode_execute/forward_unit.v
decode_execute/hazard_unit.v
#decode_execute/id_ex_reg.v
mem_wb_stage/mem_wb.v
mem_wb_stage/mem_wb_reg.v
mem_wb_stage/wb_mux.v
data_mem.v
if_id_reg.v
id_ex_reg.v
