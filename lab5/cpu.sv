//------------------------------------------------------------------------------
// Company: 		 UIUC ECE Dept.
// Engineer:		 Stephen Kempf
//
// Create Date:    
// Design Name:    ECE 385 Given Code - SLC-3 core
// Module Name:    SLC3
//
// Comments:
//    Revised 03-22-2007
//    Spring 2007 Distribution
//    Revised 07-26-2013
//    Spring 2015 Distribution
//    Revised 09-22-2015 
//    Revised 06-09-2020
//	  Revised 03-02-2021
//    Xilinx vivado
//    Revised 07-25-2023 
//    Revised 12-29-2023
//------------------------------------------------------------------------------

module cpu (
    input   logic        clk,
    input   logic        reset,

    input   logic        run_i,
    input   logic        continue_i,
    output  logic [15:0] hex_display_debug,
    output  logic [15:0] led_o,
    
    output  logic [15:0] R2,
   
    input   logic [15:0] mem_rdata,
    output  logic [15:0] mem_wdata,
    output  logic [15:0] mem_addr,
    output  logic        mem_mem_ena,
    output  logic        mem_wr_ena
);


// Internal connections
logic ld_mar; 
logic ld_mdr; 
logic ld_ir; 
logic ld_ben; 
logic ld_cc; 
logic ld_reg; 
logic ld_pc; 
logic ld_led;

logic gate_pc;
logic gate_mdr;
logic gate_alu; 
logic gate_marmux;

logic [1:0] pcmux;
logic       drmux;
logic       sr1mux;
logic       sr2mux;
logic       addr1mux;
logic [1:0] addr2mux;
logic [1:0] aluk;
logic       mio_en;

logic [15:0] mar; 
logic [15:0] mdr;
logic [15:0] ir;
logic [15:0] pc;
logic ben;

logic [15:0] bus;
logic [15:0] bus_temp;
logic [15:0] pc_temp;
logic [15:0] pc_now;
logic [15:0] mdr_temp;
logic [2:0] drmux_out;
logic [2:0] sr1mux_out;
logic [15:0] from_sr2out;
logic [15:0] from_sr2mux;
logic [15:0] from_sr1out;
logic [15:0] from_irz8;
logic [15:0] from_irs5;
logic [15:0] from_irs6;
logic [15:0] from_irs9;
logic [15:0] from_irs11;
logic [15:0] from_addr;
logic [15:0] alu_out;
logic [15:0] addr2_out;
logic [15:0] addr1_out;
logic [2:0] nzp_out;
logic [15:0] R0, R1, R3, R4, R5, R6, R7;

assign mem_addr = mar;
assign mem_wdata = mdr;

assign pc_now = pc;
assign bus_temp = bus;

// State machine, you need to fill in the code here as well
// .* auto-infers module input/output connections which have the same name
// This can help visually condense modules with large instantiations, 
// but can also lead to confusing code if used too commonly
control cpu_control (
    .*
);

zext_8 zext_8_0 (
    .data_input (ir[7:0]),
    .data_output (from_irz8)
);

sext_5 sext_5_0 (
    .data_input (ir[4:0]),
    .data_output (from_irs5)
);

sext_6 sext_6_0 (
    .data_input (ir[5:0]),
    .data_output (from_irs6)
);

sext_9 sext_9_0 (
    .data_input (ir[8:0]),
    .data_output (from_irs9)
);

sext_11 sext_11_0 (
    .data_input (ir[10:0]),
    .data_output (from_irs11)
);

assign led_o = ir;
assign hex_display_debug = ir;

reg_file reg_file0 (
    .clk (clk),
    .reset (reset),
    .bus (bus),
    .dr (drmux_out),
    .sr2 (ir[2:0]),
    .sr1 (sr1mux_out),
    .data_select (ld_reg),

    .sr2_out (from_sr2out),
    .sr1_out (from_sr1out),
    .R0 (R0),
    .R1 (R1),
    .R2 (R2),
    .R3 (R3),
    .R4 (R4),
    .R5 (R5),
    .R6 (R6),
    .R7 (R7)
);

sr2_mux sr2_mux0 (
    .data_select (sr2mux),
    .from_irs5 (from_irs5),
    .from_sr2out (from_sr2out),
    .data (from_sr2mux)
);

sr1_mux sr1_mux0 (
    .data_select (sr1mux),
    .ir (ir),
    
    .data (sr1mux_out)
);

dr_mux dr_mux0 (
    .data_select (drmux),
    .ir (ir),
    
    .data (drmux_out)
);

pc_mux pc_mux0 (
    .data_select (pcmux),
    .from_data_input (bus_temp),
    .from_addr (from_addr),
    .from_pc (pc_now),
    .data (pc_temp)
);

load_reg #(.DATA_WIDTH(16)) ir_reg (
    .clk    (clk),
    .reset  (reset),

    .load   (ld_ir),
    .data_i (bus),

    .data_q (ir)
);

load_reg #(.DATA_WIDTH(16)) pc_reg (
    .clk    (clk),
    .reset  (reset),

    .load   (ld_pc),
    .data_i (pc_temp),

    .data_q (pc)
);

load_reg #(.DATA_WIDTH(16)) mar_reg (
    .clk    (clk),
    .reset  (reset),

    .load   (ld_mar),
    .data_i (bus),

    .data_q (mar)
);

mux2 #(16) mux_mdr(.d0(mem_rdata), .d1(bus), .data_select(mio_en), .y(mdr_temp));

load_reg #(.DATA_WIDTH(16)) mdr_reg (
    .clk    (clk),
    .reset  (reset),

    .load   (ld_mdr),
    .data_i (mdr_temp),

    .data_q (mdr)
);

alu alu0 (
    .data_select (aluk),
    .from_sr2mux (from_sr2mux),
    .from_sr1out (from_sr1out),
    .data (alu_out)
);

addr2_mux addr2_mux0 (
    .data_select (addr2mux),
    .from_irs6 (from_irs6),
    .from_irs9 (from_irs9),
    .from_irs11 (from_irs11),
    .data (addr2_out)
);

addr1_mux addr1_mux0 (
    .data_select (addr1mux),
    .from_pc (pc),
    .from_sr1 (from_sr1out),
    .data (addr1_out)
);

assign from_addr = addr2_out + addr1_out;

nzp nzp0 (
    .ir (ir),
    .data_input (bus),
    .load_ben (ld_ben),
    .load_cc (ld_cc),
    .reset (reset),
    .clk (clk),
    .nzp_output (nzp_out),
    .ben_output (ben)
);

data_bus data_bus0 (
    .data_select ({gate_marmux, gate_mdr, gate_alu, gate_pc}),
    .data_input (bus_temp),
    .from_marmux (from_addr),
    .from_pc (pc),
    .from_alu (alu_out),
    .from_mdr (mdr),
    .data (bus)
);

endmodule
