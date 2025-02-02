//Provided HDMI_Text_controller_v1_0 for HDMI AXI4 IP 
//Spring 2024 Distribution

//Modified 3/10/24 by Zuofu


`timescale 1 ns / 1 ps

module hdmi_text_controller_v1_0 #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_AXI_DATA_WIDTH	= 32,
    parameter integer C_AXI_ADDR_WIDTH	= 14
)
(
    // Users to add ports here
    input logic  [7:0]  keycode0_gpio,
    input logic  restart,
//    output logic [9:0]  ballxsig, 
//    output logic [9:0]  ballysig, 
//    output logic [9:0]  ballsizesig,
//    output logic [9:0]  stonexsig, 
//    output logic [9:0]  stoneysig, 
//    output logic [9:0]  stonesizesig,

    output logic hdmi_clk_n,
    output logic hdmi_clk_p,
    output logic [2:0] hdmi_tx_n,
    output logic [2:0] hdmi_tx_p,
    output logic [31:0] score_record,
    output logic game_over,

    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface AXI
    input logic  axi_aclk,
    input logic  axi_aresetn,
    input logic [C_AXI_ADDR_WIDTH-1 : 0] axi_awaddr,
    input logic [2 : 0] axi_awprot,
    input logic  axi_awvalid,
    output logic  axi_awready,
    input logic [C_AXI_DATA_WIDTH-1 : 0] axi_wdata,
    input logic [(C_AXI_DATA_WIDTH/8)-1 : 0] axi_wstrb,
    input logic  axi_wvalid,
    output logic  axi_wready,
    output logic [1 : 0] axi_bresp,
    output logic  axi_bvalid,
    input logic  axi_bready,
    input logic [C_AXI_ADDR_WIDTH-1 : 0] axi_araddr,
    input logic [2 : 0] axi_arprot,
    input logic  axi_arvalid,
    output logic  axi_arready,
    output logic [C_AXI_DATA_WIDTH-1 : 0] axi_rdata,
    output logic [1 : 0] axi_rresp,
    output logic  axi_rvalid,
    input logic  axi_rready
);

//additional logic variables as necessary to support VGA, and HDMI modules.
// logic [31:0] regs[601];
logic [31:0] regs[8];
logic [31:0] q;
logic game_begin;
int rand_num_coin;
int score;
logic no_draw;

logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY;
    logic [9:0] ballxsig, ballysig, ballsizesig;
    logic [9:0] stonexsig, stoneysig, stonesizesig;
    logic [9:0] coinxsig, coinysig, coinsizesig;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah;
    
    assign reset_ah = ~axi_aresetn;
    
    coin coin_instance(
        .Reset(reset_ah),
        .frame_clk(vsync),                    //Figure out what this should be so that the ball will move
        .keycode(keycode0_gpio[7:0]),    //Notice: only one keycode connected to ball by default
        .rand_num(rand_num_coin),
        .x(ballxsig),
        .y(ballysig),
        .size(ballsizesig),
        .score(score),
        .game_over(game_over),
        .BallX(coinxsig),
        .BallY(coinysig),
        .BallS(coinsizesig)
    );

assign score_record = score;

// Instantiation of Axi Bus Interface AXI
hdmi_text_controller_v1_0_AXI # ( 
    .C_S_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH)
) hdmi_text_controller_v1_0_AXI_inst (
    .S_AXI_ACLK(axi_aclk),
    .S_AXI_ARESETN(axi_aresetn),
    .S_AXI_AWADDR(axi_awaddr),
    .S_AXI_AWPROT(axi_awprot),
    .S_AXI_AWVALID(axi_awvalid),
    .S_AXI_AWREADY(axi_awready),
    .S_AXI_WDATA(axi_wdata),
    .S_AXI_WSTRB(axi_wstrb),
    .S_AXI_WVALID(axi_wvalid),
    .S_AXI_WREADY(axi_wready),
    .S_AXI_BRESP(axi_bresp),
    .S_AXI_BVALID(axi_bvalid),
    .S_AXI_BREADY(axi_bready),
    .S_AXI_ARADDR(axi_araddr),
    .S_AXI_ARPROT(axi_arprot),
    .S_AXI_ARVALID(axi_arvalid),
    .S_AXI_ARREADY(axi_arready),
    .S_AXI_RDATA(axi_rdata),
    .S_AXI_RRESP(axi_rresp),
    .S_AXI_RVALID(axi_rvalid),
    .S_AXI_RREADY(axi_rready),
    .palette(regs),
    .drawX(drawX),
    .drawY(drawY),
    
    .game_over(game_over),
    .rand_num(rand_num),
    .score(score),
    .no_draw(no_draw),
    // .score_record(score_record),
    
    .q(q)
);
    
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(axi_aclk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_clk_p),          
        .TMDS_CLK_N(hdmi_clk_n),          
        .TMDS_DATA_P(hdmi_tx_p),         
        .TMDS_DATA_N(hdmi_tx_n)          
    );
    
    //Ball Module
    ball ball_instance(
        .Reset(reset_ah),
        .frame_clk(vsync),                    
        .keycode(keycode0_gpio[7:0]),
        .game_over(game_over),
        .StoneX(stonexsig),
        .StoneY(stoneysig),
        .Stone_size(stonesizesig),
        .BallX(ballxsig),
        .BallY(ballysig),
        .BallS(ballsizesig)
    );
    
    stone stone_instance(
        .Reset(reset_ah),
        .frame_clk(vsync),                    
        .keycode(keycode0_gpio[7:0]),   
        .rand_num(rand_num),
        .game_begin(game_begin),
        .game_over(game_over),
        .x(ballxsig),
        .y(ballysig),
        .size(ballsizesig),
        .BallX(stonexsig),
        .BallY(stoneysig),
        .BallS(stonesizesig)
    );

    //Color Mapper Module   
    color_mapper color_instance(
        .BallX(ballxsig),
        .BallY(ballysig),
        .StoneX(stonexsig),
        .StoneY(stoneysig),
        .CoinX(coinxsig),
        .CoinY(coinysig),
        .DrawX(drawX),
        .DrawY(drawY),
        .regs(regs),
        .q(q),
        .no_draw(no_draw),
        .game_begin(game_begin),
        .game_over(game_over),
        .restart(restart),
        .Ball_size(ballsizesig),
        .Stone_size(stonesizesig),
        .Coin_size(coinsizesig),
        .Red(red),
        .Green(green),
        .Blue(blue)
    );

// User logic ends

endmodule
