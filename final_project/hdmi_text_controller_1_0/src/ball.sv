//-------------------------------------------------------------------------
//    Ball.sv                                                            --
//    Viral Mehta                                                        --
//    Spring 2005                                                        --
//                                                                       --
//    Modified by Stephen Kempf     03-01-2006                           --
//                                  03-12-2007                           --
//    Translated by Joe Meng        07-07-2013                           --
//    Modified by Zuofu Cheng       08-19-2023                           --
//    Modified by Satvik Yellanki   12-17-2023                           --
//    Fall 2024 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI Lab                                --
//    UIUC ECE Department                                                --
//-------------------------------------------------------------------------


module  ball 
( 
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [7:0]  keycode,
    
    input  logic [9:0]  StoneX, StoneY, Stone_size,
    output logic        game_over,

    output logic [9:0]  BallX, 
    output logic [9:0]  BallY, 
    output logic [9:0]  BallS
);
    

	 
    parameter [9:0] Ball_X_Center=320;  // Center position on the X axis
    parameter [9:0] Ball_Y_Center=390;  // Center position on the Y axis
    parameter [9:0] Ball_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Ball_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Ball_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Ball_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] Ball_X_Step=1;      // Step size on the X axis
    parameter [9:0] Ball_Y_Step=1;      // Step size on the Y axis

    logic [9:0] Ball_X_Motion;
    logic [9:0] Ball_X_Motion_next;
    logic [9:0] Ball_Y_Motion;
    logic [9:0] Ball_Y_Motion_next;

    logic [9:0] Ball_X_next;
    logic [9:0] Ball_Y_next;
    
    int DistX, DistY, Size;
    assign DistX = BallX - StoneX;
    assign DistY = BallY - StoneY;
    assign Size = BallS + Stone_size;

    always_comb begin
        Ball_Y_Motion_next = Ball_Y_Motion; 
        Ball_X_Motion_next = Ball_X_Motion;

        if ( (DistX*DistX + DistY*DistY) <= (Size * Size) ) begin
            Ball_X_Motion_next = 10'd0;
            Ball_Y_Motion_next = 10'd0;
            game_over = 1'b1;
            if (keycode == 8'h2c) begin
                Ball_X_next = Ball_X_Center;
                Ball_Y_next = Ball_Y_Center;
            end
            else begin
                Ball_X_next = (BallX + Ball_X_Motion_next);
                Ball_Y_next = (BallY + Ball_Y_Motion_next);
            end
        end 
        else begin
            game_over = 1'b0;
            if (keycode == 8'h04) begin
                Ball_X_Motion_next = -10'd4;
                Ball_Y_Motion_next = 10'd0;
            end
            else if (keycode == 8'h07) begin
                Ball_X_Motion_next = 10'd4;
                Ball_Y_Motion_next = 10'd0;
            end 
            else if (keycode == 8'h0d) begin
                Ball_X_Motion_next = 10'd6;
                Ball_Y_Motion_next = 10'd0;
            end 
            else if (keycode == 8'h0e) begin
                Ball_X_Motion_next = -10'd6;
                Ball_Y_Motion_next = 10'd0;
            end 
            else begin
                Ball_X_Motion_next = 10'd0;
                Ball_Y_Motion_next = 10'd0;
            end
    
           if ( (BallX + BallS) >= 560 )  
                if (keycode == 8'h04) begin
                    Ball_X_Motion_next = -10'd2;
                    Ball_Y_Motion_next = 10'd0;
                end else begin
                    Ball_X_Motion_next = 10'd0;
                    Ball_Y_Motion_next = 10'd0;
                end    
            else if ( (BallX - BallS) <= 80 )  
                if (keycode == 8'h07) begin
                    Ball_X_Motion_next = 10'd2;
                    Ball_Y_Motion_next = 10'd0;
                end else begin
                    Ball_X_Motion_next = 10'd0;
                    Ball_Y_Motion_next = 10'd0;
                end  	
                
            if (game_over) begin
                Ball_X_Motion_next = 10'd0;
                Ball_Y_Motion_next = 10'd0;
                if (keycode == 8'h2c) begin
                    Ball_X_next = Ball_X_Center;
                    Ball_Y_next = Ball_Y_Center;
                end
                else begin
                    Ball_X_next = (BallX + Ball_X_Motion_next);
                    Ball_Y_next = (BallY + Ball_Y_Motion_next);
                end
            end 
            else begin
                Ball_X_next = (BallX + Ball_X_Motion_next);
                Ball_Y_next = (BallY + Ball_Y_Motion_next);
            end
        end
        
        BallS = 16;  
        
    end

    always_ff @(posedge frame_clk) 
    begin: Move_Ball
        if (Reset)
        begin 
            Ball_Y_Motion <= 10'd0; 
			Ball_X_Motion <= 10'd0; 
			BallY <= Ball_Y_Center;
			BallX <= Ball_X_Center;
        end
        else 
        begin 
			Ball_Y_Motion <= Ball_Y_Motion_next; 
			Ball_X_Motion <= Ball_X_Motion_next; 
            BallY <= Ball_Y_next;  
            BallX <= Ball_X_next;
		end  
    end
      
endmodule

module  stone
( 
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [7:0]  keycode,
    
    input  logic [9:0]  x, y, size,
    output int          rand_num,
    output logic        game_begin,
    input  logic        game_over,

    output logic [9:0]  BallX, 
    output logic [9:0]  BallY, 
    output logic [9:0]  BallS 
);
    
    parameter [9:0] Ball_X_Center=320;  // Center position on the X axis
    parameter [9:0] Ball_Y_Center=10;  // Center position on the Y axis
    parameter [9:0] Ball_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Ball_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Ball_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Ball_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] Ball_X_Step=1;      // Step size on the X axis
    parameter [9:0] Ball_Y_Step=1;      // Step size on the Y axis

    logic [9:0] Ball_X_Motion;
    logic [9:0] Ball_X_Motion_next;
    logic [9:0] Ball_Y_Motion;
    logic [9:0] Ball_Y_Motion_next;
    logic [9:0] Ball_X_next;
    logic [9:0] Ball_Y_next;
    int DistX, DistY, Size;
    int random;
    logic game_start;

    always_comb begin
        DistX = BallX - x;
        DistY = BallY - y;
        Size = BallS + size;
        Ball_Y_Motion_next = Ball_Y_Motion; 
        Ball_X_Motion_next = Ball_X_Motion;
        BallS = 20;  
        random = rand_num;
        game_start = game_begin;
        
        if ( (DistX*DistX + DistY*DistY) <= (Size * Size) ) begin
            Ball_X_Motion_next = 10'd0;
            Ball_Y_Motion_next = 10'd0;
        end 

        if (keycode == 8'h28) begin
            Ball_X_Motion_next = 10'd0;
            Ball_Y_Motion_next = 10'd2;
            random = $random;
            game_start = 1'b1;
        end
        
        if ((BallY + Ball_Y_Motion_next) >= Ball_Y_Max) begin
            if ( random == 0 ) begin
                Ball_X_next = 10'd288;
                Ball_Y_next = 10'd50;
                Ball_X_Motion_next = -10'd2;
                Ball_Y_Motion_next = 10'd3;
                random = 1;
            end
            else if ( random == 2 ) begin
                Ball_X_next = 10'd362;
                Ball_Y_next = 10'd100;
                Ball_X_Motion_next = 10'd2;
                Ball_Y_Motion_next = 10'd3;
                random = 3;
            end
            else if ( random == 1 ) begin
                Ball_X_next = 10'd340;
                Ball_Y_next = 10'd70;
                Ball_X_Motion_next = 10'd1;
                Ball_Y_Motion_next = 10'd3;
                random = 2;
            end
            else if ( random == 3 ) begin
                Ball_X_next = 10'd320;
                Ball_Y_next = 10'd10;
                Ball_X_Motion_next = 10'd0;
                Ball_Y_Motion_next = 10'd3;
                random = 4;
            end
            else if ( random == 4 ) begin
                Ball_X_next = 10'd351;
                Ball_Y_next = 10'd110;
                Ball_X_Motion_next = -10'd1;
                Ball_Y_Motion_next = 10'd3;
                random = 0;
            end
        end 
        else begin
            Ball_X_next = (BallX + Ball_X_Motion_next);
            Ball_Y_next = (BallY + Ball_Y_Motion_next);
        end
        
        if (game_over) begin
            game_start = 1'b0;
            Ball_X_Motion_next = 10'd0;
            Ball_Y_Motion_next = 10'd0;
            if (keycode == 8'h2c) begin
                Ball_X_next = Ball_X_Center;
                Ball_Y_next = Ball_Y_Center;
            end
            else begin
                Ball_X_next = (BallX + Ball_X_Motion_next);
                Ball_Y_next = (BallY + Ball_Y_Motion_next);
            end
        end
    end
   
    always_ff @(posedge frame_clk) 
    begin: Move_Ball
        if (Reset)
        begin 
            Ball_Y_Motion <= 10'd0; 
			Ball_X_Motion <= 10'd0;
			BallY <= Ball_Y_Center;
			BallX <= Ball_X_Center;
			rand_num <= 0;
			game_begin <= 0;
        end
        else 
        begin 
			Ball_Y_Motion <= Ball_Y_Motion_next; 
			Ball_X_Motion <= Ball_X_Motion_next; 
            BallY <= Ball_Y_next;  
            BallX <= Ball_X_next;
            rand_num <= random;
            game_begin <= game_start;
		end  
    end
     
 endmodule
 
 module  coin
( 
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [7:0]  keycode,
    
    input  logic [9:0]  x, y, size,
    output int          rand_num,
    output int          score,
    input  logic        game_over,

    output logic [9:0]  BallX, 
    output logic [9:0]  BallY, 
    output logic [9:0]  BallS 
);
    
    parameter [9:0] Ball_X_Center=320;  // Center position on the X axis
    parameter [9:0] Ball_Y_Center=320;  // Center position on the Y axis
    parameter [9:0] Ball_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Ball_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Ball_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Ball_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] Ball_X_Step=1;      // Step size on the X axis
    parameter [9:0] Ball_Y_Step=1;      // Step size on the Y axis

    logic [9:0] Ball_X_Motion;
    logic [9:0] Ball_X_Motion_next;
    logic [9:0] Ball_Y_Motion;
    logic [9:0] Ball_Y_Motion_next;
    logic [9:0] Ball_X_next;
    logic [9:0] Ball_Y_next;
    int DistX, DistY, Size;
    int keep_score;
    int random;

    always_comb begin
        DistX = BallX - x;
        DistY = BallY - y;
        Size = BallS + size;
        Ball_Y_Motion_next = Ball_Y_Motion; 
        Ball_X_Motion_next = Ball_X_Motion;
        BallS = 10;  
        keep_score = score;
        random = rand_num;
        
        if ( (DistX*DistX + DistY*DistY) <= (Size * Size) ) begin
            keep_score = keep_score + 1;
            if (keep_score%3 == 0) begin
                Ball_X_next = 10'd300;
                Ball_Y_next = 10'd200;
                Ball_X_Motion_next = -10'd2;
                Ball_Y_Motion_next = 10'd3;
                random = 1;
            end
            else if (keep_score%3 == 1) begin
                Ball_X_next = 10'd320;
                Ball_Y_next = 10'd180;
                Ball_X_Motion_next = 10'd2;
                Ball_Y_Motion_next = 10'd3;
                random = 2;
            end
            else if (keep_score%3 == 2) begin
                Ball_X_next = 10'd340;
                Ball_Y_next = 10'd150;
                Ball_X_Motion_next = 10'd0;
                Ball_Y_Motion_next = 10'd3;
                random = 0;
            end
        end 
        else begin
            if (keycode == 8'h28) begin
                if (rand_num % 2 == 0) begin
                    Ball_X_Motion_next = 10'd0;
                    Ball_Y_Motion_next = 10'd2;
                end
                else begin
                    Ball_X_Motion_next = 10'd2;
                    Ball_Y_Motion_next = 10'd4;
                end
            end
            
            Ball_X_next = (BallX + Ball_X_Motion_next);
            
            if ((BallY + Ball_Y_Motion_next) >= Ball_Y_Max) begin
                if ( random == 0 ) begin
                    Ball_X_next = 10'd300;
                    Ball_Y_next = 10'd200;
                    Ball_X_Motion_next = -10'd1;
                    Ball_Y_Motion_next = 10'd3;
                    random = 1;
                end
                else if ( random == 2 ) begin
                    Ball_X_next = 10'd340;
                    Ball_Y_next = 10'd150;
                    Ball_X_Motion_next = 10'd0;
                    Ball_Y_Motion_next = 10'd3;
                    random = 0;
                end
                else if ( random == 1 ) begin
                    Ball_X_next = 10'd320;
                    Ball_Y_next = 10'd180;
                    Ball_X_Motion_next = 10'd1;
                    Ball_Y_Motion_next = 10'd3;
                    random = 2;
                end
            end 
            else begin
                Ball_X_next = (BallX + Ball_X_Motion_next);
                Ball_Y_next = (BallY + Ball_Y_Motion_next);
            end
        end
        if (game_over) begin
            Ball_X_Motion_next = 10'd0;
            Ball_Y_Motion_next = 10'd0;
            if (keycode == 8'h2c) begin
                Ball_X_next = Ball_X_Center;
                Ball_Y_next = Ball_Y_Center;
            end
            else begin
                Ball_X_next = (BallX + Ball_X_Motion_next);
                Ball_Y_next = (BallY + Ball_Y_Motion_next);
            end
            keep_score = 0;
        end
    end
   
    always_ff @(posedge frame_clk) 
    begin: Move_Ball
        if (Reset)
        begin 
            Ball_Y_Motion <= 10'd0; 
			Ball_X_Motion <= 10'd0;
			BallY <= Ball_Y_Center;
			BallX <= Ball_X_Center;
			rand_num <= 0;
			score <= 0;
        end
        else 
        begin 
			Ball_Y_Motion <= Ball_Y_Motion_next; 
			Ball_X_Motion <= Ball_X_Motion_next; 
            BallY <= Ball_Y_next;  
            BallX <= Ball_X_next;
            rand_num <= random;
            score <= keep_score;
		end  
    end
     
 endmodule

