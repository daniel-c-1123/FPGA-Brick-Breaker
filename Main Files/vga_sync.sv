//Generates vsync & hsync signals for the VGA display. Also tracks the current pixel position, "active" zone signal, and recalculate signal.
module vga_sync(	input  logic clk,

						output logic [10:0] x_pos,
						output logic [9:0] y_pos,
						output logic vsync,hsync,
						output logic active,
						output logic recalculate);//pulses once per frame at the start of the vertical blanking period to signal calculations for the next frame
		
		//Hsync and vsync timings
		parameter H_ACTIVE = 1024;
		parameter H_FP = 40;
		parameter H_SYNC_LENGTH = 104;
		parameter H_BP = 144;
		parameter H_TOTAL = H_ACTIVE + H_FP + H_SYNC_LENGTH + H_BP;
		
		parameter V_ACTIVE = 600;
		parameter V_FP = 3;
		parameter V_SYNC_LENGTH = 10;
		parameter V_BP = 11;
		parameter V_TOTAL = V_ACTIVE + V_FP + V_SYNC_LENGTH + V_BP;
		
		
		logic [10:0] x_pos_next;
		logic [9:0] y_pos_next;
		logic hsync_next, vsync_next;
		logic active_next;
		logic recalculate_next;
		always_ff@(posedge clk) begin
			
			x_pos <= x_pos_next;
			y_pos <= y_pos_next;
		
			hsync <= hsync_next;
			vsync <= vsync_next;
			active <= active_next;
			recalculate <= recalculate_next;
		end
		
		always_comb begin
			//calculate next x and y positions
			if (x_pos < H_TOTAL - 1) 
				x_pos_next = x_pos + 1;
			else 
				x_pos_next = 0;

			if (x_pos_next == 0) begin //update y_pos when  beginning the next row
				if(y_pos < V_TOTAL -1) 
					y_pos_next = y_pos + 1;
				else
					y_pos_next = 0;
			end else
				y_pos_next = y_pos;
				
			//calculate next hsync, vsync, and active signals
			hsync_next = (x_pos_next < H_ACTIVE + H_FP ) || (x_pos_next >= H_ACTIVE + H_FP + H_SYNC_LENGTH);
			vsync_next = (y_pos_next < V_ACTIVE + V_FP ) || (y_pos_next >= V_ACTIVE + V_FP + V_SYNC_LENGTH);
			active_next = (x_pos_next < H_ACTIVE) && (y_pos_next < V_ACTIVE);
			recalculate_next = (x_pos_next == H_ACTIVE) && (y_pos_next == V_ACTIVE);
			
			
		end
		
		
endmodule