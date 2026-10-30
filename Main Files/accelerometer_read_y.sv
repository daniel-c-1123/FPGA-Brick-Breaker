//continuously reads y-acceleration at a fixed frequency (100 samples/s by default)


module accelerometer_read_y(						input 	logic 		clk,	//SPI clock < 5 MHz
															input 	logic			reset,

															output 	logic[15:0] y_accel_magnitude,
															output	logic			y_accel_sign,
															//ADXL345 SPI pins
															inout 	tri 			spi_sdio,
															output 	logic 		spi_cs,
															output 	logic 		spi_sclk);

				
		//initiation sequence signals & register addresses
		parameter INIT_REGISTER_CT = 2; //number of registers written in the initiation sequence
		parameter POWER_CTL 			= 6'h2D;
		parameter DATA_FORMAT 		= 6'h31;
		parameter DATAY0 				= 6'h34;
		logic [2:0] init_index 		= 3'b00;
		
		//counter signals
		parameter SPI_CLK_FREQ 			= 1000000; //spi clock frequency; 1MHz
		parameter POLL_FREQUENCY		= 100; 		//poll frequency for reading data; 100Hz
		parameter POLL_COUNTER_LIMIT 	= SPI_CLK_FREQ / POLL_FREQUENCY; //counter limit; 10000
		logic [$clog2(POLL_COUNTER_LIMIT):0] poll_counter = 0;
		
		//start signal controlled by the counter
		logic start;
		assign start = (poll_counter == POLL_COUNTER_LIMIT - 1);
		logic tx_start; //SPI controller start signal
		logic tx_complete;

		
				
		//controller state signals
		parameter IDLE = 2'b00;		//Waiting for a signal to start the SPI transaction
		parameter START = 2'b01;	//Initiate the SPI transmission
		parameter WAITING = 2'b10; //Wait for the SPI controller to complete transmission
		(*preserve*)logic [1:0] state = 2'b00;

		
		//serial transmission components (R/W bit, MB bit, address bit, write bit)
		parameter DEVID_ADDR = 6'b000000;
		logic tx_read_bit = 1'b1;
		logic tx_multiple_bytes_bit = 1'b1;
		logic [5:0] tx_register_addr = 6'b0;
		logic [7:0]	tx_write_byte = 6'b0;
		logic [15:0] serial_tx;
		logic [15:0] serial_rx;
		
		spi_controller_v3 spi_read_controller_inst(	
								.reset(reset),
								.clk (clk),
								.start(tx_start),
								.serial_tx(serial_tx), 
								.done(tx_complete),
								.serial_rx(serial_rx), 
								
								.spi_sdio(spi_sdio),
								.spi_cs(spi_cs),
								.spi_sclk(spi_sclk));
		//convert the y acceleration from two's complement to unsigned (also reverses the upper/lower byte order of serial_rx)
		signed_to_unsigned y_convert(	.signed_num({serial_rx[7:0],serial_rx[15:8]}),
												.unsigned_num(y_accel_magnitude),
												.sign_bit(y_accel_sign));

		//state logic
		always_ff@(posedge clk) begin
			if (reset) begin
				init_index 		<= 3'b00;
				state 			<= IDLE;
				poll_counter 	<= 0;
			end else begin
				
				case (state)
					IDLE: begin
						if (start)
							state <= START;
					end
					
					START: begin
						state <= WAITING;
					end
					
					WAITING: begin
						if (tx_complete) begin
							state <= IDLE;
							if(init_index < INIT_REGISTER_CT)
								init_index <= init_index + 1;
						end
						
					end
					
					default: begin
							state <= IDLE;
					end
				endcase
				
				if(poll_counter < POLL_COUNTER_LIMIT)
					poll_counter 	<= poll_counter + 1;
				else
					poll_counter	<= 0;
			end

		end
		
		always_comb begin
			//SPI controller signals
			tx_start = (state == START);

			serial_tx = {tx_read_bit, tx_multiple_bytes_bit, tx_register_addr, tx_write_byte};
			case (init_index)
				0: begin
					tx_read_bit = 0;
					tx_multiple_bytes_bit = 0;
					tx_register_addr = POWER_CTL;
					tx_write_byte = 8'b0000_1000; //activate measurement mode
				end
				1: begin
					tx_read_bit = 0;
					tx_multiple_bytes_bit = 0;
					tx_register_addr = DATA_FORMAT;
					tx_write_byte = 8'b0100_0000; //activate 3-wire SPI mode
				end
				default: begin
					tx_read_bit = 1;
					tx_multiple_bytes_bit = 1;
					tx_register_addr = DATAY0;
					tx_write_byte = 8'b0; //dummy byte for read requests
				end
			endcase
		end
endmodule