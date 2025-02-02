module select_adder (
	input  logic  [15:0] a, 
    input  logic  [15:0] b,
	input  logic         cin,
	
	output logic  [15:0] s,
	output logic         cout
);

	/* TODO
		*
		* Insert code here to implement a CSA adder.
		* Your code should be completly combinational (don't use always_ff or always_latch).
		* Feel free to create sub-modules or other files. */

	logic a0[3:0], b0[3:0], s0[3:0];
	logic a1[3:0], b1[3:0], s1[3:0], s4[3:0];
	logic a2[3:0], b2[3:0], s2[3:0], s5[3:0];
	logic a3[3:0], b3[3:0], s3[3:0], s6[3:0];
	logic c4, c8_0, c8_1, c12_0, c12_1, cout_0, cout_1;
	logic c8, c12;
	
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

	full_adder4 fa0(.A(a0), .B(b0), .in(cin), .sum(s0), .out(c4));
 	full_adder4 fa1(.A(a1), .B(b1), .in(1'b0), .sum(s1), .out(c8_0));
 	full_adder4 fa2(.A(a2), .B(b2), .in(1'b0), .sum(s2), .out(c12_0));
    full_adder4 fa3(.A(a3), .B(b3), .in(1'b0), .sum(s3), .out(cout_0));
	full_adder4 fa4(.A(a1), .B(b1), .in(1'b1), .sum(s4), .out(c8_1));
	full_adder4 fa5(.A(a2), .B(b2), .in(1'b1), .sum(s5), .out(c12_1));
	full_adder4 fa6(.A(a3), .B(b3), .in(1'b1), .sum(s6), .out(cout_1));

	assign c8 = (c8_1&c4)|c8_0;
	assign c12 = (c12_1&c8)|c12_0;
	assign cout = (cout_1&c12)|cout_0;
	
	always_comb
	begin
		if (c4) begin
		    s[4] = s4[0];
		    s[5] = s4[1];
		    s[6] = s4[2];
		    s[7] = s4[3];
		end else begin
		    s[4] = s1[0];
		    s[5] = s1[1];
		    s[6] = s1[2];
		    s[7] = s1[3];
		end
	end
	
	always_comb
	begin
		if (c8) begin
		    s[8] = s5[0];
		    s[9] = s5[1];
		    s[10] = s5[2];
		    s[11] = s5[3];
		end else begin
		    s[8] = s2[0];
		    s[9] = s2[1];
		    s[10] = s2[2];
		    s[11] = s2[3];
		end
	end
	
	always_comb
	begin
		if (c12) begin
		    s[12] = s6[0];
		    s[13] = s6[1];
		    s[14] = s6[2];
		    s[15] = s6[3];
		end else begin
		    s[12] = s3[0];
		    s[13] = s3[1];
		    s[14] = s3[2];
		    s[15] = s3[3];
		end
	end
	
	genvar j;
    generate
        for(j = 0; j < 4; j++) begin
            assign s[j] = s0[j];
        end
    endgenerate

endmodule
