//wrapper module to connect pins of the DE10 fpga board
module vga_top_wrapper(	input logic MAX10_CLK1_50, 
								input logic [9:0] SW,
								input logic [1:0] KEY,
								
								output logic [3:0] VGA_R, VGA_G, VGA_B, 
								output logic VGA_VS, VGA_HS,
								
								//ADXL345 SPI pins
								inout 	tri 			GSENSOR_SDI,
								output 	logic 		GSENSOR_CS_N,
								output 	logic 		GSENSOR_SCLK,
								input		logic [2:1]	GSENSOR_INT);
								
	pong_top_level game(	.clk(MAX10_CLK1_50), .spd_puck(SW[2:0]), .reset(SW[9]), .left_paddle(~KEY[0]), .right_paddle(~KEY[1]),.tilt_mode(SW[8]),
								.vga_red(VGA_R), .vga_green(VGA_G), .vga_blue(VGA_B), .vga_hsync(VGA_HS),.vga_vsync(VGA_VS),
								.spi_sdio(GSENSOR_SDI),.spi_cs(GSENSOR_CS_N), .spi_sclk(GSENSOR_SCLK));
endmodule