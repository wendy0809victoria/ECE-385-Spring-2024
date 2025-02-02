module  stone
( 
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [7:0]  keycode,

    input  logic [9:0]  x, y, size,
    output logic        game_begin,
    input  logic        game_over,

    output logic [9:0]  BallX, 
    output logic [9:0]  BallY, 
    output logic [9:0]  BallS 
);
    
    parameter [9:0] Ball_X_Center=320;  
    parameter [9:0] Ball_Y_Center=10;  
    parameter [9:0] Ball_X_Min=0;       
    parameter [9:0] Ball_X_Max=639;     
    parameter [9:0] Ball_Y_Min=0;       
    parameter [9:0] Ball_Y_Max=479;     
    parameter [9:0] Ball_X_Step=1;      
    parameter [9:0] Ball_Y_Step=1;      

    logic [9:0] Ball_X_Motion;
    logic [9:0] Ball_X_Motion_next;
    logic [9:0] Ball_Y_Motion;
    logic [9:0] Ball_Y_Motion_next;

    logic [9:0] Ball_X_next;
    logic [9:0] Ball_Y_next;
    
    int DistX, DistY, Size;
    int y_loc;

    always_comb begin
        Ball_Y_Motion_next = Ball_Y_Motion; 
        Ball_X_Motion_next = Ball_X_Motion;
        y_loc = BallY;
        DistX = BallX - x;
        DistY = BallY - y;
        Size = BallS + size;
        
//        if (game_over) begin
//            Ball_Y_Motion_next = 10'd0;
//            Ball_X_Motion_next = 10'd0;
//            BallS = 16;
//            Ball_X_next = 10'd320;
//            Ball_Y_next = 10'd10;
//            game_begin = 1'b0;
//        end
//        else begin
            if ( (DistX*DistX + DistY*DistY) <= (Size * Size) ) begin
                Ball_X_Motion_next = 10'd0;
                Ball_Y_Motion_next = 10'd0;
            end 
    
            if (keycode == 8'h28) begin
                Ball_Y_Motion_next = 10'd4;
                Ball_X_Motion_next = 10'd0;
                game_begin = 1'b1;
            end
            
            if (y_loc == 10) begin
                game_begin = 1'b0;
            end
            else begin
                game_begin = 1'b1;
            end
            
            BallS = 16;
            Ball_X_next = (BallX + Ball_X_Motion_next);
            
            if (Ball_Y_next >= Ball_Y_Max) begin
                Ball_Y_next = 10'd20;
            end 
            else begin
                Ball_Y_next = (BallY + Ball_Y_Motion_next);
            end
//        end
    end
   
    always_ff @(posedge frame_clk) //make sure the frame clock is instantiated correctly
    begin: Move_Ball
        if (Reset)
        begin 
            Ball_Y_Motion <= 10'd0; //Ball_Y_Step;
			Ball_X_Motion <= 10'd0; //Ball_X_Step;
            
			BallY <= Ball_Y_Center;
			BallX <= Ball_X_Center;
        end
        else if (!game_over)
        begin 
			Ball_Y_Motion <= Ball_Y_Motion_next; 
			Ball_X_Motion <= Ball_X_Motion_next; 

            BallY <= Ball_Y_next;  // Update ball position
            BallX <= Ball_X_next;			
		end  
		else if (game_over) begin
		    Ball_Y_Motion <= 10'd0; 
			Ball_X_Motion <= 10'd0; 

            BallY <= 10'd10;  
            BallX <= 10'd320;
		end
    end


    
      
endmodule
