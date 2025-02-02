module lookahead_adder (
	input  logic  [15:0] a, 
    input  logic  [15:0] b,
	input  logic         cin,
	
	output logic  [15:0] s,
	output logic         cout
);

	/* TODO
		*
		* Insert code here to implement a CLA adder.
		* Your code should be completly combinational (don't use always_ff or always_latch).
		* Feel free to create sub-modules or other files. */
		
	logic pg0, pg4, pg8, pg12;
	logic gg0, gg4, gg8, gg12;
	logic c4, c8, c12;
	logic a0[3:0], b0[3:0], s0[3:0];
	logic a1[3:0], b1[3:0], s1[3:0];
	logic a2[3:0], b2[3:0], s2[3:0];
	logic a3[3:0], b3[3:0], s3[3:0];
	
	genvar i;
    generate
        for(i = 0; i < 4; i++) begin
            assign a0[i] = a[i];
            assign b0[i] = b[i];
            assign a1[i] = a[i+4];
            assign b1[i] = b[i+4];
            assign a2[i] = a[i+8];
            assign b2[i] = b[i+8];
            assign a3[i] = a[i+12];
            assign b3[i] = b[i+12];
        end
    endgenerate
	
	lookahead4 la0(.A(a0), .B(b0), .in(cin), .sum(s0), .pg(pg0), .gg(gg0));
    assign c4 = gg0|(cin&pg0);

    lookahead4 la1(.A(a1), .B(b1), .in(c4), .sum(s1), .pg(pg4), .gg(gg4));
    assign c8 = gg4|(gg0&pg4)|(cin&pg0&pg4);

    lookahead4 la2(.A(a2), .B(b2), .in(c8), .sum(s2), .pg(pg8), .gg(gg8));
    assign c12 = gg8|(gg4&pg8)|(gg0&pg8&pg4)|(cin&pg8&pg4&pg0);

    lookahead4 la3(.A(a3), .B(b3), .in(c12), .sum(s3), .pg(pg12), .gg(gg12));
    assign cout = gg12|(gg8&pg12)|(gg4&pg8&pg12)|(gg0&pg8&pg4&pg12)|(cin&pg8&pg4&pg0&pg12);
    
    genvar j;
    generate
        for(j = 0; j < 4; j++) begin
            assign s[j] = s0[j];
            assign s[j+4] = s1[j];
            assign s[j+8] = s2[j];
            assign s[j+12] = s3[j];
        end
    endgenerate

endmodule
