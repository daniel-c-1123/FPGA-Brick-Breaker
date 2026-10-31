//(x,y) is the upper left corner of the object; (x_pos,y_pos) is the VGA current display pixel
module object #(parameter WIDTH = 32, HEIGHT = 32, COLOR = 12'hFFF)
			(	input logic [10:0] x, x_pos,
				input logic [9:0] y, y_pos,
				output logic [11:0] pixel_obj);
	
	always_comb begin
		if (	x <= x_pos && 
				x_pos < x + WIDTH &&
				y <= y_pos &&
				y_pos < y + HEIGHT)
				
				pixel_obj = COLOR;
			else
				pixel_obj = 12'b0;
	end
				
				
endmodule