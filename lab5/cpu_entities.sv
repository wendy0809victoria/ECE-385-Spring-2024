module mux2
		#(parameter width = 8)
		(input logic [width - 1: 0] d0, d1, 
		 input logic select,
		 output logic [width - 1: 0] y);
		
    always_comb 
    begin
        if(select)
            begin
                y = d0;
            end
        else
            begin
                y = d1;
            end
    end
endmodule

module data_bus (
    input logic [3:0] data_select,
    input logic [15:0] data_input,
    input logic [15:0] from_marmux,
    input logic [15:0] from_pc,
    input logic [15:0] from_alu,
    input logic [15:0] from_mdr,

    output logic [15:0] data
);

    always_comb begin
    case(data_select)
        4'b0001: data = from_pc;
        4'b0010: data = from_alu;
        4'b0100: data = from_mdr;
        4'b1000: data = from_marmux;
        default: data = data_input;
    endcase
    end

endmodule

module zext_8 (
    input logic [7:0] data_input,
    output logic [15:0] data_output
);

    assign data_output = {8'h00, data_input[7:0]};

endmodule

module sext_5 (
    input logic [4:0] data_input,
    output logic [15:0] data_output
);
    always_comb
    begin
        if (data_input[4]) begin
            data_output = {11'b11111111111, data_input[4:0]};
        end
        else begin
            data_output = {11'b00000000000, data_input[4:0]};
        end 
    end

endmodule

module sext_6 (
    input logic [5:0] data_input,
    output logic [15:0] data_output
);

    always_comb
    begin
        if (data_input[5]) begin
            data_output = {10'b1111111111, data_input[5:0]};
        end
        else begin
            data_output = {10'b0000000000, data_input[5:0]};
        end 
    end

endmodule

module sext_9 (
    input logic [8:0] data_input,
    output logic [15:0] data_output
);

    always_comb
    begin
        if (data_input[8]) begin
            data_output = {7'b1111111, data_input[8:0]};
        end
        else begin
            data_output = {7'b0000000, data_input[8:0]};
        end 
    end

endmodule

module sext_11 (
    input logic [10:0] data_input,
    output logic [15:0] data_output
);

    always_comb
    begin
        if (data_input[10]) begin
            data_output = {5'b11111, data_input[10:0]};
        end
        else begin
            data_output = {5'b00000, data_input[10:0]};
        end 
    end

endmodule

module pc_mux (
    input logic [1:0] data_select,
    input logic [15:0] from_data_input,
    input logic [15:0] from_addr,
    input logic [15:0] from_pc,

    output logic [15:0] data
);

    always_comb begin
    case(data_select)
        2'b00: data = from_pc+1;
        2'b01: data = from_data_input;
        2'b10: data = from_addr;
        default: data = from_pc;
    endcase
    end

endmodule

module addr2_mux (
    input logic [1:0] data_select,
    input logic [15:0] from_irs6,
    input logic [15:0] from_irs9,
    input logic [15:0] from_irs11,

    output logic [15:0] data
);

    always_comb begin
    case(data_select)
        2'b00: data = 16'h0000;
        2'b01: data = from_irs6;
        2'b10: data = from_irs9;
        2'b11: data = from_irs11;
    endcase
    end

endmodule

module addr1_mux (
    input logic data_select,
    input logic [15:0] from_pc,
    input logic [15:0] from_sr1,

    output logic [15:0] data
);

    always_comb begin
    case(data_select)
        1'b0: data = from_pc;
        1'b1: data = from_sr1;
    endcase
    end

endmodule

module sr2_mux (
    input logic data_select,
    input logic [15:0] from_irs5,
    input logic [15:0] from_sr2out,

    output logic [15:0] data
);

    always_comb begin
    case(data_select)
        1'b0: data = from_sr2out;
        1'b1: data = from_irs5;
    endcase
    end

endmodule

module sr1_mux (
    input logic data_select,
    input logic [15:0] ir,

    output logic [2:0] data
);

    always_comb begin
    case(data_select)
        1'b0: data = ir[11:9];
        1'b1: data = ir[8:6];
    endcase
    end

endmodule

module alu (
    input logic [1:0] data_select,
    input logic [15:0] from_sr2mux,
    input logic [15:0] from_sr1out,

    output logic [15:0] data
);

    always_comb begin
    case(data_select)
        2'b00: data = from_sr2mux+from_sr1out;
        2'b01: data = from_sr2mux&from_sr1out;
        2'b10: data = ~from_sr1out;
        2'b11: data = from_sr1out;
    endcase
    end

endmodule

module nzp (
    input logic [15:0] ir,
    input logic [15:0] data_input,
    input logic load_ben,
    input logic load_cc,
    input logic reset,
    input logic clk,
    output logic [2:0] nzp_output,
    output logic ben_output
);

    logic N, Z, P;

    always_ff @(posedge clk)
	begin
		if (reset)
			begin
				ben_output <= 1'b0;
			end
		if ((~reset) & load_ben)
			begin
				ben_output <= ((nzp_output[2]&ir[11]) | (nzp_output[1]&ir[10]) | (nzp_output[0]&ir[9]));
			end
		if (load_cc)
			begin
				nzp_output <= {N, Z, P};
			end
	end

    always_comb begin
        N = 1'b1;
		Z = 1'b1;
		P = 1'b1;
        if (data_input[15] == 1'b0 && data_input != 16'h0000)
			begin
				N = 1'b0;
				Z = 1'b0;
				P = 1'b1;
			end
		if (data_input == 16'h0000)
			begin 
				N = 1'b0;
				Z = 1'b1;
				P = 1'b0;
			end
		if (data_input[15] == 1'b1)
			begin
				N = 1'b1;
				Z = 1'b0;
				P = 1'b0;
			end
    end

endmodule

module dr_mux (
    input logic [15:0] ir, 
	input logic data_select,
						
    output logic [2:0] data
);

always_comb begin
	unique case(data_select)
		1'b0 : data = ir[11:9];
		1'b1 : data = 3'b111;		
	endcase	
end	

endmodule

module reg_file (
    input logic clk,
    input logic reset,
    input logic [15:0] bus,
    input logic [2:0] dr,
    input logic [2:0] sr2,
    input logic [2:0] sr1,
    input logic data_select,

    output logic [15:0] sr2_out,
    output logic [15:0] sr1_out,
    output logic [15:0] R0, R1, R2, R3, R4, R5, R6, R7
);

always_ff @(posedge clk)
begin
	if (reset) begin
		R0 <= 16'h0000;
		R1 <= 16'h0000;
		R2 <= 16'h0000;
		R3 <= 16'h0000;
		R4 <= 16'h0000;
		R5 <= 16'h0000;
		R6 <= 16'h0000;
		R7 <= 16'h0000;
	end
	if ((~reset) & data_select) begin
		case (dr)
			3'b000: R0[15:0] <= bus;
			3'b001: R1[15:0] <= bus;
			3'b010: R2[15:0] <= bus;
			3'b011: R3[15:0] <= bus;
			3'b100: R4[15:0] <= bus;
			3'b101: R5[15:0] <= bus;
			3'b110: R6[15:0] <= bus;
			3'b111: R7[15:0] <= bus;		
		endcase
	end
end

always_comb begin
	case (sr1)
		3'b000: sr1_out = R0[15:0];
		3'b001: sr1_out = R1[15:0];
		3'b010: sr1_out = R2[15:0];
		3'b011: sr1_out = R3[15:0];
		3'b100: sr1_out = R4[15:0];
		3'b101: sr1_out = R5[15:0];
		3'b110: sr1_out = R6[15:0];
		3'b111: sr1_out = R7[15:0];
	endcase
end

always_comb begin	
	case (sr2)
		3'b000: sr2_out = R0[15:0];
	    3'b001: sr2_out = R1[15:0];
		3'b010: sr2_out = R2[15:0];
		3'b011: sr2_out = R3[15:0];
		3'b100: sr2_out = R4[15:0];
		3'b101: sr2_out = R5[15:0];
		3'b110: sr2_out = R6[15:0];
		3'b111: sr2_out = R7[15:0];
	endcase
end

endmodule
