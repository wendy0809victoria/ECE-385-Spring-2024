module full_adder4 (
	input  logic  A[3:0], 
    input  logic  B[3:0],
	input  logic         in,
	
	output logic  sum[3:0],
	output logic         out
);

	/* TODO
		*
		* Insert code here to implement a ripple adder.
		* Your code should be completly combinational (don't use always_ff or always_latch).
		* Feel free to create sub-modules or other files. */

	logic       c1, c2, c3;

	full_adder  FA0(.x(A[0]), .y(B[0]), .z(in), .s(sum[0]), .c(c1));
	full_adder  FA1(.x(A[1]), .y(B[1]), .z(c1), .s(sum[1]), .c(c2));
	full_adder  FA2(.x(A[2]), .y(B[2]), .z(c2), .s(sum[2]), .c(c3));
	full_adder  FA3(.x(A[3]), .y(B[3]), .z(c3), .s(sum[3]), .c(out));

endmodule
