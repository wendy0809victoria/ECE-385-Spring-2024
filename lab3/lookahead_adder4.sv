module lookahead4  (input logic A[3:0], B[3:0], in,
 				 output logic sum[3:0], pg, gg);
	logic g[3:0];
	logic p[3:0];
	logic c[3:0];
	logic c3, c2, c1, c0;
	
	genvar i;
    generate
        for(i = 0; i < 4; i++) begin
            assign g[i] = A[i]&B[i];
        end
    endgenerate
    
    genvar j;
    generate
        for(j = 0; j < 4; j++) begin
            assign p[j] = A[j]^B[j];
        end
    endgenerate
    
    assign pg = p[0]&p[1]&p[2]&p[3];
    assign gg = g[3]|(g[2]&p[3])|(g[1]&p[3]&p[2])|(g[0]&p[3]&p[2]&p[1]);
	
	assign c0 = in;
	assign c1 = (in&p[0])|g[0];
	assign c2 = (in&p[0]&p[1])|(g[0]&p[1])|g[1];
	assign c3 = (in&p[0]&p[1]&p[2])|(g[0]&p[1]&p[2])|(g[1]&p[2])|g[2];
	assign c = {c3, c2, c1, c0};
	
	genvar k;
    generate
        for(k = 0; k < 4; k++) begin
            assign sum[k] = A[k]^B[k]^c[k];
        end
    endgenerate
	
endmodule