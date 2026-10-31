// V3: v2 but written way more concisely
// Supports 1-byte writes, and 1 or 2 byte reads
// for 2 byte reads, the first byte appears on serial_rx[15:8] and the second byte appears at serial_rx[7:0]
// for 1 byte reads, the byte appears on serial_rx[7:0]
module spi_controller_v3(
								input 	logic				reset,
								input 	logic 			clk,
								input 	logic 			start,
								input 	logic [15:0] 	serial_tx, //bits to transmit
								output	logic 			done,
								output 	logic [15:0] 	serial_rx, //byte recieved; this is only updated once at the end of the read cycle (not during transmission)
								
								//SPI ports
								inout 	tri 				spi_sdio,
								output 	logic 			spi_cs,
								output 	logic 			spi_sclk);
								
								
	//state register & parameters

	parameter IDLE = 2'b00;
	parameter READ = 2'b01;
	parameter WRITE = 2'b10;
	parameter DONE = 2'b11;
	
	(*preserve*) logic [1:0] state = IDLE;
	logic [3:0] tx_index = 0;
	logic 		multi_byte_ct = 0; // stays on 0 for multi byte reads. For 2 byte reads, set this to 1 during the first byte and 0 during the second byte

	
	//variables to hold bits for transmission 
	logic [15:0] 	rx_shift_reg = 0; //recieved SPI bits; this is updated during transmission & transferred to serial_rx at the end of the transmission
	logic [15:0] 	serial_tx_saved = 0; //saves a copy of serial_tx at the beginning of transmission (in case serial_tx changes during transmission)
	
	//Next state logic (updates on falling edge)
	always_ff@(negedge clk) begin
		if (reset) begin
			state 				<= IDLE;
			multi_byte_ct 		<= 0;
			tx_index 			<= 0;
			serial_rx 			<= 0;
			serial_tx_saved 	<= 0;
			
		end else begin
			case (state) 
				IDLE: begin
					if (start) begin
						state 				<= serial_tx[15] ? READ : WRITE; //enter read or write state based on the R/W bit of serial_tx
						multi_byte_ct 		<= (serial_tx[14] && serial_tx[15]) ? 1'b1 : 1'b0; //if multi-byte bit = 1, set multi_byte_ct. Ignore MB on write operations
						tx_index 			<= 4'd15;
						serial_tx_saved 	<= serial_tx;
					end 
				end
				
				READ: begin
					if (tx_index == 0 && multi_byte_ct == 0) begin //finish transmission & transfer rx shift register to serial_rx
						state		 <= DONE;
						serial_rx <= rx_shift_reg;
						
					end else if (tx_index == 0 && multi_byte_ct == 1) begin //start reading the second byte
						tx_index 			<= 7;
						multi_byte_ct	 	<= 0;
						
					end else begin //read next bit of transmission
						tx_index <= tx_index - 1;
					end
				end
				
				WRITE: begin
					if (tx_index == 0)
						state <= DONE;
					else
						tx_index <= tx_index - 1;
				end
				
				DONE: begin
					state <= IDLE;
				end
			endcase
			
		end
		
	end
	
	//output logic
	
	assign done = (state == DONE);
	assign spi_sdio = ((state == READ && tx_index >= 8) || state == WRITE) ? serial_tx_saved[tx_index] : 1'bz; //keep sdi floating when idle & in second half of a read request.	
	assign spi_cs = !((state == IDLE && start) || state == READ || state == WRITE);  //active low CS
	assign spi_sclk = (state == READ || state == WRITE)?clk:1'b1;
						
						
	//rx data logic (sample SDIO on clock rise)
	always_ff@(posedge clk) begin
		if(reset) begin
			rx_shift_reg <= 0;
		end else begin
			if(state == READ && tx_index >= 0 && tx_index <= 7) begin
				rx_shift_reg <= {rx_shift_reg[14:0],spi_sdio};
			end
		end
	end
	
endmodule