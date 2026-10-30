//synchronizer for clock domain crossing
module synchronizer#(parameter SIZE = 16)(input		logic clk_new,
														input 	logic [SIZE-1:0] data_in,
														output 	logic [SIZE-1:0] data_out);
		logic [SIZE-1:0]	sync_1;
		always@(posedge clk_new) begin
			sync_1 <= data_in;
			data_out <= sync_1;
		end
endmodule