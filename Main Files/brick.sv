//(X,Y) is the upper left corner of the brick; (x_pos,y_pos) is the current VGA display pixel.
//Accepts pixel_contains_puck input to detect collisions
module brick#(parameter X = 100, Y= 100, WIDTH = 200, HEIGHT = 16, COLOR = 12'hFFF)
				(	input logic clk,reset,
					input logic recalculate,
					input logic [10:0]  x_pos,
					input logic [9:0]  y_pos,
					input logic pixel_contains_puck,
					input logic event_collision,
					
					output logic [11:0] pixel_brick);
	
	logic is_broken = 0, is_broken_next;
	logic flag_puck_collision = 0, flag_puck_collision_next;
	
	//each brick module stores its own state (broken/intact) & a flag to detect collision with the puck
	always_ff@(posedge clk) begin
		if(reset) begin
			is_broken <= 0;
			flag_puck_collision <= 0;
		end else begin
			is_broken <= is_broken_next;
			flag_puck_collision <= flag_puck_collision_next;
		end
	end
	
	always_comb begin
		//output pixel(graphic) logic & collision detection
		if (	X <= x_pos && 
				x_pos < X + WIDTH &&
				Y <= y_pos &&
				y_pos < Y + HEIGHT) begin
			
			pixel_brick = is_broken ? 12'b0 : COLOR;
			flag_puck_collision_next = pixel_contains_puck&&event_collision ? 1 : flag_puck_collision;
		end else begin
			pixel_brick = 12'b0;
			flag_puck_collision_next = flag_puck_collision;
		end
		

		if(recalculate) begin
		//checks collision flag once per frame & updates broken state
			is_broken_next = flag_puck_collision ? 1 : is_broken;
		end else begin
			is_broken_next = is_broken;
		end
			
	end
endmodule