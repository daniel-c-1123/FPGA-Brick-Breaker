//calculates VGA RGB output based on current pixel position
//tracks object positions, collision logic, etc
//pixel/vga clock runs on 50MHz and SPI clock runs on 1MHz

module pong_logic (	input logic clk,reset,
							input logic [10:0] x_pos,
							input logic [9:0] y_pos,
							input logic [2:0] spd_puck,
							input logic left_paddle, right_paddle,
							input logic active,
							input logic recalculate,
							input logic tilt_mode,
							output logic [11:0] pixel,
							
							//ADXL345 SPI pins
							inout 	tri 			spi_sdio,
							output 	logic 		spi_cs,
							output 	logic 		spi_sclk,
							input 	logic [2:1]	spi_int); 

		logic [3:0] red, green, blue;
		
		//border object
		parameter BORDER_LEFT_EDGE = 14;
		parameter BORDER_RIGHT_EDGE = 1014; 
		parameter BORDER_TOP_EDGE = 10; 
		parameter BORDER_BOTTOM_EDGE = 590; 
		parameter BORDER_COLOR = 12'hFFF;
		logic pixel_contains_border;
		logic [11:0] pixel_border;
		border#(.LEFT_EDGE(BORDER_LEFT_EDGE), .RIGHT_EDGE(BORDER_RIGHT_EDGE), .TOP_EDGE(BORDER_TOP_EDGE), .BOTTOM_EDGE(BORDER_BOTTOM_EDGE), .COLOR(BORDER_COLOR)) border_1(.x_pos(x_pos), .y_pos(y_pos), .pixel(pixel_border));
		assign pixel_contains_border = |pixel_border;
		
		//puck object
		parameter PUCK_WIDTH = 20;
		parameter PUCK_HEIGHT = 20;
		logic [10:0] x_puck = 512,x_puck_next;
		logic [9:0]	y_puck = 300, y_puck_next;
		logic x_dir_puck = 1, x_dir_puck_next;//1 = moving right, 0 = moving left
		logic y_dir_puck = 1, y_dir_puck_next;//1 = moving down, 0 = moving up
		logic [11:0] pixel_puck;
		logic pixel_contains_puck;
		
		logic event_collision_left; //collision "events" are only active for a single pixel during the collision & will signal bricks to break (these are wires)
		logic event_collision_right;
		logic event_collision_top;
		logic event_collision_bottom;
		logic event_collision_any;
		assign event_collision_any = event_collision_left || event_collision_right || event_collision_top || event_collision_bottom;
		logic flag_collision_left = 0, flag_collision_left_next; //collision "flags" are active until the end of the frame when the puck's velocity & position is recalculated (these are registers)
		logic flag_collision_right = 0, flag_collision_right_next;
		logic flag_collision_top = 0, flag_collision_top_next;
		logic flag_collision_bottom = 0, flag_collision_bottom_next;
		object#(.WIDTH(PUCK_WIDTH), .HEIGHT(PUCK_HEIGHT)) puck(.x(x_puck),.y(y_puck),.x_pos(x_pos), .y_pos(y_pos),.pixel_obj(pixel_puck));
		assign pixel_contains_puck = |pixel_puck;

		
		//paddle object
		parameter PADDLE_WIDTH = 200;
		parameter PADDLE_HEIGHT = 16;
		parameter PADDLE_SPEED_BUTTON = 8; //default speed for button control
		
		logic [10:0] 	x_paddle = 412, x_paddle_next;
		logic [9:0]		y_paddle = 560;
		logic [4:0]		paddle_speed;
		logic				paddle_direction;
		logic [11:0] pixel_paddle;
		logic pixel_contains_paddle;
		object#(.WIDTH(PADDLE_WIDTH), .HEIGHT(PADDLE_HEIGHT)) paddle(.x(x_paddle),.y(y_paddle),.x_pos(x_pos), .y_pos(y_pos),.pixel_obj(pixel_paddle));
		assign pixel_contains_paddle = |pixel_paddle;
		
		//brick objects
		parameter BRICKS_PER_ROW = 9;
		parameter BRICKS_PER_COLUMN = 5;
		parameter BRICK_WIDTH = 80;
		parameter BRICK_HEIGHT = 10;
		parameter BRICK_COLOR = 12'hFFF;
		logic [BRICKS_PER_COLUMN-1 : 0][BRICKS_PER_ROW-1:0][11:0] pixel_brick_array ;
		logic pixel_contains_brick_array;
		
		genvar i;
		genvar j;
		generate
			for(j = 0; j < BRICKS_PER_COLUMN; j++) begin : generate_brick_array_columns
				for( i = 0; i < BRICKS_PER_ROW; i++) begin : generate_brick_array_rows
					brick #(.X(60 + 100*i),.Y(50 + 25 * j),.WIDTH(BRICK_WIDTH),.HEIGHT(BRICK_HEIGHT)) brick_array(.clk(clk),.reset(reset), .recalculate(recalculate), .x_pos(x_pos), .y_pos(y_pos), .pixel_contains_puck(pixel_contains_puck),.event_collision(event_collision_any),.pixel_brick(pixel_brick_array[j][i]));
				end
			end
		endgenerate
		assign pixel_contains_brick_array= |pixel_brick_array;
		
		//signal that tracks if the pixel contains a collidible object (anything except the puck)
		logic pixel_is_collidible;
		assign pixel_is_collidible = pixel_contains_paddle || pixel_contains_border || pixel_contains_brick_array;

		//accelerometer data for reading the y-tilt (note: the SPI controller works on a separate clock domain (1MHz vs 50 MHz)
		logic spi_clk; 
		logic [15:0] y_tilt_magnitude_dirty;
		logic	[15:0] y_tilt_magnitude;
		logic	y_tilt_sign_dirty;
		logic y_tilt_sign;
		pll_50_to_1 spi_clock_gen(.inclk0(clk), .c0(spi_clk));
		
		
		accelerometer_read_y tilt_reader(	.clk(spi_clk), .reset(reset), 
														.y_accel_magnitude(y_tilt_magnitude_dirty), .y_accel_sign(y_tilt_sign_dirty),
														.spi_sdio(spi_sdio), .spi_cs(spi_cs), .spi_sclk(spi_sclk));
														
		synchronizer					 sync_y_tilt_mag (.clk_new(clk), .data_in(y_tilt_magnitude_dirty), .data_out(y_tilt_magnitude));
		synchronizer#(.SIZE(1'b1))	 sync_y_tilt_sign(.clk_new(clk), .data_in(y_tilt_sign_dirty), .data_out(y_tilt_sign));
		
		//at the start of each pixel clock, update all registers 
		always_ff@(posedge clk) begin
			if(reset)begin
				x_puck <= 512;
				y_puck <= 300;
				x_dir_puck <= 0;
				y_dir_puck <= 0;
				x_paddle <= 412;
				flag_collision_left <= 0;
				flag_collision_right <= 0;
				flag_collision_top <= 0;
				flag_collision_bottom <= 0;
			end else begin
				x_puck <= x_puck_next;
				y_puck <= y_puck_next;
				x_dir_puck <= x_dir_puck_next;
				y_dir_puck <= y_dir_puck_next;
				x_paddle <= x_paddle_next;
				
				flag_collision_left <= flag_collision_left_next;
				flag_collision_right <= flag_collision_right_next;
				flag_collision_top <= flag_collision_top_next;
				flag_collision_bottom <= flag_collision_bottom_next;
			end
		end
		
		always_comb begin
			
			//output pixel (graphic)logic
			if (active) begin
				if (pixel_contains_border)
					pixel = pixel_border;
				else if(pixel_contains_puck)
					pixel = pixel_puck;
				else if(pixel_contains_paddle)
					pixel = pixel_paddle;
				else if(pixel_contains_brick_array)
					pixel = BRICK_COLOR;
				else
					pixel = 0;
			end else //no pixel during blanking periods
				pixel = 0;
				
			//paddle speed & direction logic
			if (tilt_mode) begin
				// tilt control mode
				paddle_direction = y_tilt_sign;
				paddle_speed = y_tilt_magnitude[8:4]; //rescale the tilt measures to an appropriate number for paddle speed
			end else begin
				//button control mode
				if(left_paddle) begin
					paddle_direction = 1;
					paddle_speed = PADDLE_SPEED_BUTTON;
				end else if(right_paddle) begin
					paddle_direction = 0;
					paddle_speed = PADDLE_SPEED_BUTTON;
				end else begin
					paddle_direction = 0;
					paddle_speed = 0;
				end
			end

			if(recalculate) begin // recalculate once per frame for object positions, movement directions, etc.
			
				//check collision flags & update puck movement direction
				if(flag_collision_left) begin
					x_dir_puck_next = 1;
				end else if(flag_collision_right) begin
					x_dir_puck_next = 0;
				end else begin
					x_dir_puck_next = x_dir_puck;
				end
				if(flag_collision_top) begin
					y_dir_puck_next = 1;
				end else if(flag_collision_bottom) begin
					y_dir_puck_next = 0;
				end else begin
					y_dir_puck_next = y_dir_puck;
				end
				
				//update puck & paddle position
				if (x_paddle >= BORDER_LEFT_EDGE && paddle_direction)
					x_paddle_next = x_paddle - paddle_speed;
				else if (x_paddle + PADDLE_WIDTH -1 <= BORDER_RIGHT_EDGE && ~paddle_direction)
					x_paddle_next = x_paddle + paddle_speed;
				else
					x_paddle_next = x_paddle;

				x_puck_next = x_dir_puck_next ? x_puck + spd_puck : x_puck - spd_puck;
				y_puck_next = y_dir_puck_next ? y_puck + spd_puck : y_puck - spd_puck;
				
				//reset collision flags
				flag_collision_left_next = 0;
				flag_collision_right_next = 0;
				flag_collision_top_next = 0;
				flag_collision_bottom_next = 0;
				
				event_collision_left = 0;
				event_collision_right = 0;
				event_collision_top = 0;
				event_collision_bottom = 0;
				
			end else begin 
				//logic in between frames (active every pixel)
				
				// keep object positions the same in between frames
				x_puck_next = x_puck;
				y_puck_next = y_puck;
				x_dir_puck_next = x_dir_puck;
				y_dir_puck_next = y_dir_puck;
				x_paddle_next = x_paddle;
				
				//raise flag if a collision is detected (puck edge overlaps with a collidible object). each edge has its own flag (4 total)
				//exclude the corners since their collisions are ambiguous(part of two edges). Higher puck speeds require a larger corner margin
				//also signal a collision event so bricks know to break
				if(pixel_contains_puck && pixel_is_collidible && x_pos == x_puck && (y_pos > y_puck + 3 && y_pos < y_puck + PUCK_HEIGHT - 4))begin
					flag_collision_left_next = 1;
					event_collision_left = 1;
				end else begin
					flag_collision_left_next = flag_collision_left;
					event_collision_left = 0;
				end
				
				if(pixel_contains_puck && pixel_is_collidible && x_pos == (x_puck + PUCK_WIDTH - 1) && (y_pos > y_puck + 3 && y_pos < y_puck + PUCK_HEIGHT - 4))begin
					flag_collision_right_next = 1;
					event_collision_right = 1;
				end else begin
					flag_collision_right_next = flag_collision_right;
					event_collision_right = 0;
				end
				
				if(pixel_contains_puck && pixel_is_collidible && y_pos == y_puck && (x_pos > x_puck + 3 && x_pos < x_puck + PUCK_WIDTH - 4))begin
					flag_collision_top_next = 1;
					event_collision_top = 1;
				end else begin
					flag_collision_top_next = flag_collision_top;
					event_collision_top = 0;
				end
				
				if(pixel_contains_puck && pixel_is_collidible && y_pos == (y_puck + PUCK_HEIGHT - 1)&& (x_pos > x_puck + 3 && x_pos < x_puck + PUCK_WIDTH - 4))begin
					flag_collision_bottom_next = 1;
					event_collision_bottom = 1;
				end else begin
					flag_collision_bottom_next = flag_collision_bottom;
					event_collision_bottom = 0;
				end
					

			end
		end
endmodule