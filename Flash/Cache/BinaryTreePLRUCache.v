`default_nettype none

module BinaryTreePLRUCache #(
		parameter SIZE = 3
	)(
		input wire clk,
		input wire rst,

		input wire enable,
		input wire[SIZE-1:0] address,
		output wire [SIZE-1:0] lruAddress
	);

	localparam PARENT_SIZE = (SIZE - 1);

	reg[(1 << PARENT_SIZE)-1:0] state;

generate
	if (SIZE > 1) begin

		always @(posedge clk) begin
			if (rst) begin
				state <= {SIZE{1'b0}};
			end else if (enable) begin
				state[address[SIZE-1:1]] <= !address[0];
			end
		end

		BinaryTreePLRUCache #(.SIZE(PARENT_SIZE)) parentLayer (
			.clk(clk),
			.rst(rst),
			.enable(enable),
			.address(address[SIZE-1:1]),
			.lruAddress(lruAddress[SIZE-1:1]));

		assign lruAddress[0] = state[lruAddress[SIZE-1:1]];
		
	end else begin
		always @(posedge clk) begin
			if (rst) begin
				state <= 1'b0;
			end else if (enable) begin
				state <= !address;
			end
		end

		assign lruAddress = state;
	end
endgenerate

endmodule
