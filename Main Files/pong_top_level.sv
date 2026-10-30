//Top-level module to package modules into an instance of the pong game
module pong_top_level(	input logic clk,reset,
								input logic [2:0] spd_puck,
								input logic left_paddle, right_paddle,
								input logic tilt_mode,
								
								output logic [3:0] vga_red, vga_green, vga_blue,
								output logic vga_hsync, vga_vsync,
								
								//ADXL345 SPI pins
								inout 	tri 			spi_sdio,
								output 	logic 		spi_cs,
								output 	logic 		spi_sclk);
		//current VGA pixel position 
		logic [10:0] 	x_pos;
		logic [9:0] 	y_pos;
		//color of current pixel
		logic [11:0] 	pixel;
		logic active;
		logic recalculate;
		vga_sync vga_sync_1(	.clk(clk),
									.x_pos(x_pos), .y_pos(y_pos), .vsync(vga_vsync), .hsync(vga_hsync), .active(active),.recalculate(recalculate));
		pong_logic pong_logic_1(	.clk(clk),.reset(reset), .x_pos(x_pos), .y_pos(y_pos),.spd_puck(spd_puck),.left_paddle(left_paddle), .right_paddle(right_paddle), .active(active), .recalculate(recalculate), .tilt_mode(tilt_mode),
											.pixel(pixel),.spi_sdio(spi_sdio), .spi_cs(spi_cs), .spi_sclk(spi_sclk));
		always_comb begin
			vga_red = pixel[11:8];
			vga_green = pixel[7:4];
			vga_blue = pixel[3:0];
		end
endmodule