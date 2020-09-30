module sm_hex_display_digit
(
    input [6:0] digit1,
    output [11:0] seven_segments
);


    assign seven_segments = {1'b0, digit1[0], digit1[5], 2'b11, digit1[1], 1'b0, digit1[6], digit1[2], 1'b0, digit1[3], digit1[4]};
	 

endmodule