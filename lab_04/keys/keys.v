module keys(KEY, CLOCK_50, LEDR);
	input [1:0] KEY;
	input CLOCK_50;
	output reg [1:0] LEDR;
	
	always @(posedge CLOCK_50)
		LEDR [1:0] <= KEY [1:0];
endmodule