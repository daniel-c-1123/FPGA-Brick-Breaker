
//draws the border of the screen area
module border#(parameter LEFT_EDGE=14, RIGHT_EDGE = 1014, TOP_EDGE = 10, BOTTOM_EDGE = 590, COLOR = 12'hFFF)
				(	input logic [10:0] x_pos,
					input logic [9:0] y_pos,
					output logic [11:0] pixel);
		always_comb begin
			if (x_pos <= LEFT_EDGE || x_pos >= RIGHT_EDGE || y_pos <= TOP_EDGE || y_pos >= BOTTOM_EDGE )
				pixel = COLOR;
			else
				pixel = 12'b0;
		end
endmodule