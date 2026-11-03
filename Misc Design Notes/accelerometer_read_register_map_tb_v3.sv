module accelerometer_read_register_map_tb_v3 ();

	logic clk = 0;
	logic reset = 0;
	logic button_start = 0;
	logic button_increment_addr = 0;
	
	logic spi_cs, spi_sclk;
	tri spi_sdio;
	
	accelerometer_read_register_map_v3 dut(.clk(clk),	
														.button_start(button_start),
														.reset(reset),
														.button_increment_addr(button_increment_addr),
														.seven_seg_lower_nibble_rx_1(),
														.seven_seg_upper_nibble_rx_1(),
														.seven_seg_lower_nibble_rx_2(),
														.seven_seg_upper_nibble_rx_2(),
														.seven_seg_lower_nibble_addr(),
														.seven_seg_upper_nibble_addr(),

														.spi_sdio(spi_sdio),
														.spi_cs(spi_cs),
														.spi_sclk(spi_sclk),
														.spi_int());
		always begin
			#1; clk <= ~clk;
		end
		
		initial begin
			#20; reset = 1; #2; reset = 0; 
			#20; button_start = 1; #2; button_start = 0; 
			#40; button_start = 1; #2; button_start = 0;
			#40; button_start = 1; #2; button_start = 0;
			#80; button_start = 1; #2; button_start = 0;
			#80; reset = 1; #2; reset = 0;
			#20; button_start = 1; #2; button_start = 0; 
			#40; button_start = 1; #2; button_start = 0;
			
		end
endmodule