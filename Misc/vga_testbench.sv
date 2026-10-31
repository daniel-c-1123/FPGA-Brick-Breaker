//test bench to verify the VGA signal generation
module vga_testbench();


	logic clk = 1'b0;
	logic [10:0] x_pos;
	logic [9:0] y_pos;
	logic hsync,vsync;
	logic active;
	
	vga_sync dut(.clk(clk), .x_pos(x_pos), .y_pos(y_pos), .hsync(hsync), .vsync(vsync), .active(active));

	always begin
		#1; clk <= ~clk;
	end
	initial begin
		#100; $stop;
	end
endmodule