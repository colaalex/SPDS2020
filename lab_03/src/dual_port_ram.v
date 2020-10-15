module dual_port_ram
#(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=4)
(
	input [(DATA_WIDTH-1):0] data_a,
	input [(ADDR_WIDTH-1):0] addr_a,
	input we, clk,
	output [(DATA_WIDTH-1):0] q_a,
	input [(ADDR_WIDTH-1):0] addr_b,
	output [(DATA_WIDTH-1):0] q_b
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];


	// Specify the initial contents.  You can also use the $readmemb
	// system task to initialize the RAM variable from a text file.
	// See the $readmemb template page for details.
	initial begin
        $readmemh ("firmware.hex", ram);
	end 
	always @ (posedge clk)
	begin
		if(we)
			ram[addr_a] <= data_a;
	end
	assign q_a = ram[addr_a];
	assign q_b = ram[addr_b];
endmodule