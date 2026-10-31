//converts a two's complement signed number to an unsigned number with separate sign bit (sign_bit = 1 if the input is negative)
module signed_to_unsigned #(parameter SIZE = 16)(	input 	logic [SIZE-1 : 0] 	signed_num,
																	output 	logic	[SIZE-1 : 0]	unsigned_num,
																	output 	logic						sign_bit);
					
	assign sign_bit = signed_num[SIZE -1];
	assign unsigned_num = sign_bit? ~signed_num + 1: signed_num;
				
endmodule