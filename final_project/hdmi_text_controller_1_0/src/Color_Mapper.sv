module ram_32x8(
 output logic [31:0] q,
 output logic [31:0] data_out,
 input [31:0] d,
 input [11:0] write_address, read_address,
 input logic we, clk,
 input logic S_AXI_ARESETN, slv_reg_wren,
 input integer C_S_AXI_DATA_WIDTH,
 input integer register,
 input logic [3:0] S_AXI_WSTRB,
 input logic game_over,
 input logic rand_num,
 input int score,
 output logic no_draw,
 output logic [31:0] palette [8]
);

logic [31:0] mem [1201];
integer byte_index;
int wr_addr;
assign wr_addr = write_address;

always_ff @( posedge clk) begin

    if (write_address[11] == 1'b0) begin
        if (slv_reg_wren && S_AXI_ARESETN) begin
            for ( byte_index = 0; byte_index <= 3; byte_index = byte_index+1 ) begin
                if ( (S_AXI_WSTRB[byte_index] == 1) ) begin
                    mem[write_address][(byte_index*8) +: 8] <= d[(byte_index*8) +: 8];
                    q <= mem[register];
                end
                else begin 
                    q <= mem[register];
                end  
            end
        end 
            
        else if ((~slv_reg_wren) && S_AXI_ARESETN) begin
            q <= mem[register];
        end
            
        else if ((S_AXI_ARESETN == 1'b0)) begin
            mem[write_address] <= 32'h00000000;
            q <= mem[register];
        end
        
        if (read_address[11] == 1'b0) begin
            data_out <= mem[read_address];
        end 
        else if (read_address[11] == 1'b1) begin
            data_out <= palette[read_address-2048];
        end
        
        palette[5] <= score;
        palette[7] <= rand_num;
    end
    else if (write_address[11] == 1'b1) begin
        if (slv_reg_wren && S_AXI_ARESETN) begin
            for ( byte_index = 0; byte_index <= 3; byte_index = byte_index+1 ) begin
                if ( (S_AXI_WSTRB[byte_index] == 1) ) begin
                    palette[write_address-2048][(byte_index*8) +: 8] <= d[(byte_index*8) +: 8];
                    q <= mem[register];
                end
                else begin 
                    q <= mem[register];
                end  
            end
            palette[5] <= score;
            palette[7] <= rand_num;
        end 
            
        else if ((~slv_reg_wren) && S_AXI_ARESETN) begin
            q <= mem[register];
            palette[5] <= score;
            palette[7] <= rand_num;
        end
            
        else if ((S_AXI_ARESETN == 1'b0)) begin
            palette[write_address-2048] <= 32'h00000000;
            q <= mem[register];
        end
            
        if (read_address[11] == 1'b0) begin
            data_out <= mem[read_address];
        end 
        else if (read_address[11] == 1'b1) begin
            data_out <= palette[read_address-2048];
        end
    end
    
    if (palette[7][1] == 1'b1) begin
        no_draw = 1'b1;
    end 
    else begin
        no_draw = 1'b0;
    end
end    

endmodule

//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Modified by Zuofu Cheng   08-19-2023                               --
//                                                                       --
//    Fall 2023 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module  color_mapper ( input  logic [9:0] BallX, BallY, DrawX, DrawY, Ball_size,
                       input  logic [9:0] StoneX, StoneY, Stone_size,
                       input  logic [9:0] CoinX, CoinY, Coin_size,
                       input  logic no_draw,
                       input  logic game_begin, game_over,
                       input  logic restart,
                       input  logic [31:0] regs[8],
                       input  logic [31:0] q,
                       output logic [3:0]  Red, Green, Blue );
    
    logic ball_on;
    logic [10:0] digit;
    logic [10:0] line;
    logic [10:0] charX;
    logic [10:0] charY;
    int register;
    int line_idx;
    int digit_idx;
    int byte_i;
    
    logic [3:0] color_f1;
    logic [3:0] color_b1;
    logic [3:0] color_f3;
    logic [3:0] color_b3;

    assign line = (DrawY << 6) >> 6;        // ROM entry's location
    assign digit = (DrawX << 7) >> 7;       // ROM entry's drawing digit
    assign charX = DrawX >> 5;              // The register number, X dimension
    assign charY = DrawY >> 4;              // The register number, Y dimension

    int x;
    int y;
    int read_d;
    assign x = DrawX/16;
    assign y = DrawY/16;
    assign byte_i = DrawX%16;
    assign line_idx = DrawY%16;
    assign register = x + y * 40;   // VRAM register index to search
    assign read_d = q;

    logic [31:0] tb_read;
    logic [31:0] color;
    logic [7:0]	font0;
    logic [7:0]	font1;
    logic [7:0]	font2;
    logic [7:0]	font3;
    logic [7:0]	font;

    assign color = regs[0];
    
    assign digit_idx = byte_i/8;
    logic [10:0] addr0;
    int inv_t0;
    logic [10:0] addr1;
    int inv_t1;
    logic [10:0] addr2;
    int inv_t2;
    logic [10:0] addr3;
    int inv_t3;
    int inv_t;
    
    assign addr1 = {4'b0000, read_d[14:8]};
    assign inv_t1 = read_d[15];
    assign color_f1 = read_d[7:4];
    assign color_b1 = read_d[3:0];
            
    assign addr3 = {4'b0000, read_d[30:24]};
    assign inv_t3 = read_d[31];
    assign color_f3 = read_d[23:20];
    assign color_b3 = read_d[19:16];
    
    logic [3:0] color_f;
    logic [3:0] color_b;
    
    font_rom draw_char1(
        .addr(addr1 * 16 + line_idx),
        .data(font1)
    );
    
    font_rom draw_char3(
        .addr(addr3 * 16 + line_idx),
        .data(font3)
    );
    
    always_comb begin
        if (digit_idx == 0) begin
            font = font1;
            inv_t = inv_t1;
            color_f = color_f1;
            color_b = color_b1;
        end 
        else if (digit_idx == 1) begin
            font = font3;
            inv_t = inv_t3;
            color_f = color_f3;
            color_b = color_b3;
        end
    end
    
    int digit_inv;
    assign digit_inv = byte_i%8;
	
    always_comb
    begin:Ball_on_proc
        if (((font[7-digit_inv] == 1'b1) && (inv_t == 0)) || ((font[7-digit_inv] == 1'b0) && (inv_t != 0)))
            ball_on = 1'b1;
        else 
            ball_on = 1'b0;
     end 
     
     integer f_idx;
     assign f_idx = color_f;
     integer b_idx;
     assign b_idx = color_b;
     integer half_f;
     integer half_b;
     assign half_f = f_idx/2;
     assign half_b = b_idx/2;
     
    logic ball_on_screen;
    logic stone_on_screen;
    logic coin_on_screen;
    int DistX, DistY, Size;
    assign DistX = DrawX - BallX;
    assign DistY = DrawY - BallY;
    assign Size = Ball_size;
  
    always_comb
    begin:Ball_on_proc1
        // if ( (DistX*DistX + DistY*DistY) <= (Size * Size) )
        if ( DistX <= Size && DistX >= -Size && DistY <= Size && DistY >= -Size )
            ball_on_screen = 1'b1;
        else 
            ball_on_screen = 1'b0;
    end 
    
    always_comb
    begin:Ball_on_proc2
        if ( (((DrawX - StoneX)*(DrawX - StoneX) + (DrawY - StoneY)*(DrawY - StoneY)) <= (10 * 10)) || (((DrawY - StoneY)*(DrawY - StoneY) + (DrawX - (StoneX+15))*(DrawX - (StoneX+15))) <= (10 * 10)) )
        // if ( (DrawX - StoneX) <= 20 && (DrawX - StoneX) >= -20 && (DrawY - StoneY) <= 20 && (DrawY - StoneY) >= -20 )
            stone_on_screen = 1'b1;
        else 
            stone_on_screen = 1'b0;
    end 
    
    always_comb
    begin:Ball_on_proc3
        // if ( ((DrawX - CoinX)*(DrawX - CoinX) + (DrawY - CoinY)*(DrawY - CoinY)) <= (10 * 10) )
        // if ( ((DrawX - CoinX) - (DrawY - CoinY)) <= 10 && ((DrawX - CoinX) - (DrawY - CoinY)) >= -10 ) 
        if ( (((DrawX - CoinX)*(DrawX - CoinX) + (DrawY - CoinY)*(DrawY - CoinY)) <= (10 * 10)) || (((DrawX - CoinX)*(DrawX - CoinX) + (DrawY - (CoinY+15))*(DrawY - (CoinY+15))) <= (10 * 10)) )
            coin_on_screen = 1'b1;
        else 
            coin_on_screen = 1'b0;
    end 
       
    always_comb
    begin:RGB_Display
        if ((ball_on == 1'b1) && (ball_on_screen == 1'b0) && (stone_on_screen == 1'b0) && (coin_on_screen == 1'b0)) begin 
            if ( (half_f*2 != f_idx) ) begin
                Red = regs[f_idx/2][24:21];
                Green = regs[f_idx/2][20:17];
                Blue = regs[f_idx/2][16:13];
            end
            else begin 
                Red = regs[f_idx/2][12:9];
                Green = regs[f_idx/2][8:5];
                Blue = regs[f_idx/2][4:1];
            end
        end       
        else if ((ball_on == 1'b0) && (ball_on_screen == 1'b0) && (stone_on_screen == 1'b0) && (coin_on_screen == 1'b0)) begin 
            if ( (half_b*2 != b_idx) ) begin
                Red = regs[b_idx/2][24:21];
                Green = regs[b_idx/2][20:17];
                Blue = regs[b_idx/2][16:13];
            end
            else begin 
                Red = regs[b_idx/2][12:9];
                Green = regs[b_idx/2][8:5];
                Blue = regs[b_idx/2][4:1];
            end
        end      
        else if ((ball_on_screen == 1'b1) && (stone_on_screen == 1'b0) && (coin_on_screen == 1'b0) && (game_begin == 1'b1)) begin
            Red = 4'hf;
            Green = 4'h7;
            Blue = 4'h0;
        end
        else if ((ball_on_screen == 1'b0) && (stone_on_screen == 1'b1) && (coin_on_screen == 1'b0) && (game_begin == 1'b1)) begin
            Red = 4'h7;
            Green = 4'hf;
            Blue = 4'hf;
        end
        else if ((ball_on_screen == 1'b1) && (stone_on_screen == 1'b1) && (coin_on_screen == 1'b0) && (game_begin == 1'b1)) begin
            Red = 4'hf;
            Green = 4'hf;
            Blue = 4'hf;
        end
        else if ((ball_on_screen == 1'b0) && (stone_on_screen == 1'b0) && (coin_on_screen == 1'b1) && (game_begin == 1'b1)) begin
            Red = 4'hf;
            Green = 4'hf;
            Blue = 4'hc;
        end
        else if ((ball_on_screen == 1'b0) && (stone_on_screen == 1'b1) && (coin_on_screen == 1'b1) && (game_begin == 1'b1)) begin
            Red = 4'h7;
            Green = 4'hf;
            Blue = 4'hf;
        end
        else if ((ball_on_screen == 1'b1) && (stone_on_screen == 1'b1) && (coin_on_screen == 1'b1) && (game_begin == 1'b1)) begin
            Red = 4'hf;
            Green = 4'hf;
            Blue = 4'hf;
        end
        else if ((ball_on_screen == 1'b1) && (stone_on_screen == 1'b0) && (coin_on_screen == 1'b1) && (game_begin == 1'b1)) begin
            Red = 4'hf;
            Green = 4'h7;
            Blue = 4'h0;
        end
        else if ((ball_on_screen == 1'b1) && (game_begin == 1'b0 || game_over == 1'b1)) begin
            Red = 4'h7;
            Green = 4'h7;
            Blue = 4'h8;
        end
        else if ((stone_on_screen == 1'b1) && (game_begin == 1'b0 || game_over == 1'b1)) begin
            Red = 4'h7;
            Green = 4'h7;
            Blue = 4'h8;
        end
        else if ((coin_on_screen == 1'b1) && (game_begin == 1'b0 || game_over == 1'b1)) begin
            Red = 4'h7;
            Green = 4'h7;
            Blue = 4'h8;
        end
    end 
	
endmodule

